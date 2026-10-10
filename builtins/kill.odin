package builtins

import "core:sys/posix"
import "core:fmt"
import "core:os"

import "../models"

kill :: proc(current_state: ^models.Shell_State, args: []string) -> os.Error {
    if len(args) <= 1 {
        fmt.println("usage: kill <pid>")
        return nil
    }
    fmt.println("Not implemented yet, sorry :)")
    return nil
}