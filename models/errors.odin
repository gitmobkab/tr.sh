package models

import "core:sys/posix"
import "core:os"

// a union of all posible errors trsh may deal with
Error :: union {
    os.Error,
    posix.Errno,
    Redirect_Error,
}

Redirect_Error :: struct {
    target: string,
    errno: posix.Errno
}
