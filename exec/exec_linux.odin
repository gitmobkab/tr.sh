package exec

import "core:sys/posix"

import "../parser"
import "../models"
import "../lookup"
import "../utils"
import "../jobs"


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

    if pipeline_can_be_handle_as_single_command(pipeline) {
        pid, cmd_errs := handle_single_command(pipeline.commands[0], shell)
        if len(cmd_errs) >= 1 {
            return cmd_errs
        }
        if pid != BAD_PID {
            if err := set_foreground_pgrp(pid); err != nil {
                append(&errs, err)
            }
            stat_loc: i32
            posix.waitpid(pid, &stat_loc, {.UNTRACED})
            if err := set_foreground_pgrp(shell.state.pgid); err != nil {
                append(&errs, err)
            }
        }
        return utils.snapshot_dynamic_array(models.Error, errs)
    }

    pids, collect_errs := exec_and_collect_pids(pipeline.commands, pipes, shell)
    defer delete(pids)
    defer delete(collect_errs)
    if len(collect_errs) > 0 {
        append(&errs, ..collect_errs)
    }

    waiting_for_children := !pipeline.background && len(pids) >= 1
    if waiting_for_children {
        if err := set_foreground_pgrp(pids[0]); err != nil {
            append(&errs, err)
        }
    }
    
    if pipeline.background {
        id := models.add_new_job(&shell.state.jobs, pids, pids[0], .Running)
        jobs.notify_job(shell.state.jobs[id], id)
    } else {
        status: i32
        for pid, i in pids {
            posix.waitpid(pid, &status, {.UNTRACED, .CONTINUED})
            switch {
                case posix.WIFSTOPPED(status):
                    id := models.add_new_job(&shell.state.jobs, pids[i:], pids[0], .Stopped)
                    jobs.notify_job(shell.state.jobs[id], id)
            }
        }
    }   

    for pipe, i in pipes {
        models.close_pipe(pipe)
    }

    if waiting_for_children {
        if err := set_foreground_pgrp(shell.state.pgid); err != nil {
            append(&errs, err)
        }
    }

    return utils.snapshot_dynamic_array(models.Error, errs)
}

set_foreground_pgrp :: proc(pgid: posix.pid_t) -> models.Error {
    result := posix.tcsetpgrp(posix.STDIN_FILENO, pgid)
    if result == .FAIL {
        return posix.errno()
    }
    return nil
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


handle_single_command :: proc(
    command: parser.Parsed_Command,
    shell: ^models.Shell,
) -> (_pid: posix.pid_t, _errs: []models.Error) {
    found_command, search_err := lookup.search_command(command.argv[0], shell.state.cwd,
                                                    &shell.state.commands_cache, shell.builtins)
                                                    
    if search_err != nil {
        errs: [dynamic]models.Error
        defer delete(errs)
        append(&errs, search_err)
        return BAD_PID, utils.snapshot_dynamic_array(models.Error, errs)
    }

    exec_context := Exec_Context{
        path = found_command.path,
        argv = command.argv,
        builtin_proc = found_command.builtin_proc,
        shell = shell
    }

    switch found_command.kind {
        case .Builtin:
            backup_io := Process_IO{
                stdin_source = posix.dup(posix.STDIN_FILENO),
                stdout_target = posix.dup(posix.STDOUT_FILENO),
            }

            defer {
                posix.dup2(backup_io.stdin_source, posix.STDIN_FILENO)
                posix.dup2(backup_io.stdout_target, posix.STDOUT_FILENO)
                close_process_io(backup_io)
            }

            fds, redirect_errs := setup_redirects(command.redirects)
            if len(redirect_errs) != 0 {
                return BAD_PID, redirect_errs
            }

            dup_redirects(command.redirects, fds)
            builtin_command_executer(exec_context)
        case .External:
            pid, exec_errs := exec_as_child_process(
                external_command_executer,
                exec_context,
                default_process_io(),
                command.redirects,
                BAD_PID,
                shell.signals
            )
            if len(exec_errs) >= 1 {
                return BAD_PID, exec_errs
            }
            return pid, {}
    }

    return BAD_PID, {}
}


exec_command :: proc(
    command: parser.Parsed_Command,
    shell: ^models.Shell,
    IO: Process_IO,
    pgid: posix.pid_t
) -> (_pid: posix.pid_t, _errs: []models.Error) {

    if len(command.argv) == 0 {
        pid, errs := exec_as_child_process(no_op_executer, {}, IO, command.redirects, pgid, shell.signals)
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
    cmd_pid, fork_errs := exec_as_child_process(executer, exec_context, IO, command.redirects, pgid, shell.signals)
    return cmd_pid, utils.snapshot_dynamic_array(models.Error, errs)
}

pipeline_can_be_handle_as_single_command :: proc(pipeline: parser.Pipeline) -> bool {
    return !pipeline.background && len(pipeline.commands) == 1 && len(pipeline.commands[0].argv) >= 1
}