package exec

import "core:sys/posix"

import "../models"

Process_IO :: struct {
    stdin_source: posix.FD,
    stdout_target: posix.FD,
}

default_process_io :: proc() -> Process_IO {
    default_io := Process_IO{SKIP_FILENO, SKIP_FILENO}
    return default_io
}

// centralized payload for builtin and external command execution (WIP)
Exec_Context :: struct {
    path: string,
    argv: []string,
    builtin_proc: models.builtin_proc,
    shell: ^models.Shell,
}

Command_Executer :: #type proc(ctx: Exec_Context) -> (_exit_code: int)