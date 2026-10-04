package exec

import "core:sys/posix"
import "core:os"

import "../parser"
import "../models"
import "../lookup"
import "../utils"


exec_pipepilines :: proc(pipelines: []parser.Pipeline, shell: ^models.Shell) -> []models.Error {
    errs: [dynamic]models.Error
    defer delete(errs)
    for pipeline in pipelines {
        pipeline_errs := exec_pipeline(pipeline, shell)
        if len(pipeline_errs) > 0 {
            append(&errs, ..pipeline_errs)
        }
    }
    return utils.snapshot_dynamic_array(models.Error, errs)
}

exec_pipeline :: proc(pipeline: parser.Pipeline, shell: ^models.Shell) -> []models.Error {
    pipes, pipe_errors := models.init_pipes(len(pipeline.commands) - 1)
    if len(pipe_errors) > 0 {
        return pipe_errors
    }
    errs: [dynamic]models.Error
    defer delete(errs)

    pids, collect_errs := exec_and_collect_pids(pipeline.commands, pipes, shell)
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
        set_foreground_pgrp(shell.state.pgid, &errs)
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
    shell: ^models.Shell
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

        pid, exec_errs := exec_command(command, shell, IO, pgid)
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
    shell: ^models.Shell,
    IO: Process_IO,
    pgid: posix.pid_t
) -> (_pid: posix.pid_t, _errs: []models.Error) {

    if len(command.argv) == 0 {
        pid, errs := fork_and_exec(no_op_executer, {}, IO, command.redirects, pgid, shell.signals)
        return pid, errs
    }

    found_command, search_err := lookup.search_command(command.argv[0], shell.state.cwd,
                                                    &shell.state.commands_cache, shell.builtins)

    errs: [dynamic]models.Error
    defer delete(errs)
    if search_err != nil {
        append(&errs, search_err)
        return BAD_PID, utils.snapshot_dynamic_array(models.Error, errs)
    }

    exec_context := Exec_Context{
        path = found_command.path,
        argv = command.argv,
        environ = models.env_store_to_environ(shell.state.env),
        builtin_proc = found_command.builtin_proc,
        shell = shell
    }
    executer: Command_Executer
    switch found_command.kind {
        case .Builtin:
            executer = builtin_command_executer
        case .External:
            executer = external_command_executer
    }
    cmd_pid, fork_errs := fork_and_exec(executer, exec_context, IO, command.redirects, pgid, shell.signals)
    return cmd_pid, utils.snapshot_dynamic_array(models.Error, errs)
}
