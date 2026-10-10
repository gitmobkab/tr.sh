package models

import "core:sys/posix"
import "core:os"

// a union of all posible errors trsh may deal with
Error :: union {
    os.Error,
    posix.Errno,
    Redirect_Error,
    Command_Not_Found,
}

Command_Not_Found :: struct {
    command_name: string
}

Redirect_Error :: struct {
    target: string,
    errno: posix.Errno
}
