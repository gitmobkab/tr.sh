package exec

import "core:sys/posix"
import "core:os"

import "../parser"
import "../models"
import "../lookup"
import "../utils"


exec_pipepilines :: proc(pipelines: []parser.Pipeline, shell_state: ^models.Shell_state) -> []Error {
    errs: [dynamic]Error
    defer delete(errs)
    for pipeline in pipelines {
        pipeline_errs := exec_pipeline(pipeline, shell_state)
        if len(pipeline_errs) > 0 {
            append(&errs, ..pipeline_errs)
        }
    }
    return utils.snapshot_dynamic_array(Error, errs)
}

exec_pipeline :: proc(pipeline: parser.Pipeline, shell_state: ^models.Shell_state) -> []Error {
    return exec_commands(pipeline.commands, shell_state)
}


exec_commands :: proc(commands: []parser.Parsed_Command, shell_state: ^models.Shell_state) -> []Error {
    pipes, pipe_errors := init_pipes(len(commands) - 1)
    if len(pipe_errors) > 0 {
        return pipe_errors
    }
    errs: [dynamic]Error
    defer delete(errs)

    pids, collect_errs := exec_and_collect_pids(commands, pipes, shell_state)
    defer delete(pids)
    defer delete(collect_errs)
    if len(collect_errs) > 0 {
        append(&errs, ..collect_errs)
    }

    pids_not_empty := len(pids) >= 1
    if pids_not_empty {
        result := posix.tcsetpgrp(posix.STDIN_FILENO, pids[0])
        if result == .FAIL {
            append(&errs, posix.errno())
        }
    }
    
    // don't intend on using it right now
    global_stat_loc: i32
    for pid in pids {
        posix.waitpid(pid, &global_stat_loc, {.UNTRACED})
    }

    for pipe, i in pipes {
        close_pipe(pipe)
    }
    if pids_not_empty {
        result := posix.tcsetpgrp(posix.STDIN_FILENO, shell_state.pgid)
        if result == .FAIL {
            append(&errs, posix.errno())
        }
    }
    return utils.snapshot_dynamic_array(Error, errs)
}

exec_and_collect_pids :: proc(
    commands: []parser.Parsed_Command, 
    pipes: []Process_Pipe, 
    shell_state: ^models.Shell_state
) -> (_pids: []posix.pid_t, _errs: []Error) {

    errs := make([dynamic]Error)
    pids := make([dynamic]posix.pid_t)
    defer delete(errs)
    defer delete(pids)

    pgid: posix.pid_t = BAD_PID
    for command, i in commands {
        command_io := default_command_io()

        if i > 0 {
            command_io.stdin_source = pipes[i - 1].reader
        }
        if i < len(commands) - 1 {
            command_io.stdout_target = pipes[i].writer
        }

        pid, exec_errs := exec_command(command, shell_state, command_io, pgid)
        if len(exec_errs) > 0 || pid == BAD_PID {
            append(&errs, ..exec_errs)
        } else {
            append(&pids, pid)
        }

        if len(pids) >= 1 && pgid == BAD_PID {
            pgid = pids[0]
        }
    }
    return utils.snapshot_dynamic_array(posix.pid_t, pids), utils.snapshot_dynamic_array(Error, errs)
}


exec_command :: proc(
    command: parser.Parsed_Command,
    shell_state: ^models.Shell_state,
    command_io: Command_IO,
    pgid: posix.pid_t
) -> (_pid: posix.pid_t, _errs: []Error) {

    found_command, search_err := lookup.search_command(command.argv[0])
    errs: [dynamic]Error
    defer delete(errs)
    if search_err != nil {
        append(&errs, search_err)
        return BAD_PID, utils.snapshot_dynamic_array(Error, errs)
    }

    cmd_pid: posix.pid_t = BAD_PID
    switch found_command.kind{
        case .Builtin:
            err := exec_builtin(found_command.builtin_proc, command.argv, shell_state, command_io, command.redirects)
            if len(err) > 0 {
                append(&errs, ..err)
            }
        case .External:
            environ := utils.env_store_to_environ(shell_state.public_env)
            pid, exec_errs := exec_external(found_command.path, command.argv, environ, command_io, command.redirects, pgid, shell_state.ignored_signals[:])
            if len(exec_errs) > 0 || pid == BAD_PID {
                append(&errs, ..exec_errs)
            } else {
                cmd_pid = pid
            }
    }
    return cmd_pid, utils.snapshot_dynamic_array(Error, errs)
}
