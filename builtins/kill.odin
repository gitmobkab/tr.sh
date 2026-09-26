package builtins

import "core:sys/posix"
import "core:fmt"
import "core:os"

import "../models"
import "../registry"

kill :: proc(current_state: ^models.Shell_state, args: []string) -> os.Error {
    if len(args) == 0 {
        fmt.println("usage: kill <pid>")
        return nil
    }
    fmt.println("Not implemented yet, sorry :)")
    return nil
}

@(init)
register_kill :: proc "contextless"() {
    registry.registry["kill"] = kill
}