package exec

import "core:sys/posix"
import "core:os"

import "../parser"
import "../models"
import "../lookup"
import "../utils"


exec_pipepilines :: proc(pipelines: []parser.Pipeline, shell_state: ^models.Shell_State) -> []models.Error {
    errs: [dynamic]models.Error
    defer delete(errs)
    for pipeline in pipelines {
        pipeline_errs := exec_pipeline(pipeline, shell_state)
        if len(pipeline_errs) > 0 {
            append(&errs, ..pipeline_errs)
        }
    }
    return utils.snapshot_dynamic_array(models.Error, errs)
}

exec_pipeline :: proc(pipeline: parser.Pipeline, shell_state: ^models.Shell_State) -> []models.Error {
    pipes, pipe_errors := models.init_pipes(len(pipeline.commands) - 1)
    if len(pipe_errors) > 0 {
        return pipe_errors
    }
    errs: [dynamic]models.Error
    defer delete(errs)

    pids, collect_errs := exec_and_collect_pids(pipeline.commands, pipes, shell_state)
    defer delete(pids)
    defer delete(collect_errs)
    if len(collect_errs) > 0 {
        append(&errs, ..collect_errs)
    }

    pids_not_empty := len(pids) >= 1
    if pids_not_empty {
        set_foreground_pgrp(pids[0], &errs)
    }
    defer if pids_not_empty {
        set_foreground_pgrp(shell_state.pgid, &errs)
    }
    
    // don't intend on using it right now
    global_stat_loc: i32
    for pid in pids {
        posix.waitpid(pid, &global_stat_loc, {.UNTRACED})
    }

    for pipe, i in pipes {
        models.close_pipe(pipe)
    }
    
    return utils.snapshot_dynamic_array(models.Error, errs)
}

set_foreground_pgrp :: proc(pgid: posix.pid_t, errs: ^[dynamic]models.Error) {
    result := posix.tcsetpgrp(posix.STDIN_FILENO, pgid)
    if result == .FAIL {
        append(errs, posix.errno())
    }
}

exec_and_collect_pids :: proc(
    commands: []parser.Parsed_Command, 
    pipes: []models.Process_Pipe, 
    shell_state: ^models.Shell_State
) -> (_pids: []posix.pid_t, _errs: []models.Error) {

    errs := make([dynamic]models.Error)
    pids := make([dynamic]posix.pid_t)
    defer delete(errs)
    defer delete(pids)

    pgid: posix.pid_t = BAD_PID
    for command, i in commands {
       IO := default_process_io()

        if i > 0 {
           IO.stdin_source = pipes[i - 1].reader
        }
        if i < len(commands) - 1 {
            IO.stdout_target = pipes[i].writer
        }

        pid, exec_errs := exec_command(command, shell_state, IO, pgid)
        if len(exec_errs) > 0 || pid == BAD_PID {
            append(&errs, ..exec_errs)
        } else {
            append(&pids, pid)
        }

        if len(pids) >= 1 && pgid == BAD_PID {
            pgid = pids[0]
        }
    }
    return utils.snapshot_dynamic_array(posix.pid_t, pids), utils.snapshot_dynamic_array(models.Error, errs)
}


exec_command :: proc(
    command: parser.Parsed_Command,
    shell_state: ^models.Shell_State,
    IO: Process_IO,
    pgid: posix.pid_t
) -> (_pid: posix.pid_t, _errs: []models.Error) {

    found_command, search_err := lookup.search_command(command.argv[0])
    errs: [dynamic]models.Error
    defer delete(errs)
    if search_err != nil {
        append(&errs, search_err)
        return BAD_PID, utils.snapshot_dynamic_array(models.Error, errs)
    }

    cmd_pid: posix.pid_t = BAD_PID
    switch found_command.kind{
        case .Builtin:
            err := exec_builtin(found_command.builtin_proc, command.argv, shell_state,Process_IO, command.redirects)
            if len(err) > 0 {
                append(&errs, ..err)
            }
        case .External:
            environ := models.env_store_to_environ(shell_state.env)
            pid, exec_errs := exec_external(found_command.path, command.argv, environ, IO, command.redirects, pgid, shell_state.ignored_signals[:])
            if len(exec_errs) > 0 || pid == BAD_PID {
                append(&errs, ..exec_errs)
            } else {
                cmd_pid = pid
            }
    }
    return cmd_pid, utils.snapshot_dynamic_array(models.Error, errs)
}
