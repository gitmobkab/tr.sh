package builtins

import "core:os"
import "core:fmt"

import "../models"

hash :: proc(current_state: ^models.Shell_State, _: []string) -> models.Error {
    if len(current_state.commands_cache) == 0 {
        fmt.println("No cached commands...")
        return nil
    }

    for key, value in current_state.commands_cache {
        fmt.printfln("%s -> %s",key, value)
    }

    return nil
}