package exec

import "core:sys/posix"


Command_IO :: struct {
    stdin_source: posix.FD,
    stdout_target: posix.FD,
}

default_command_io :: proc() -> Command_IO {
    default_io := Command_IO{SKIP_FILENO, SKIP_FILENO}
    return default_io
}

