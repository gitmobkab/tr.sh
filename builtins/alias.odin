package builtins

import "core:fmt"
import "core:os"

import "../models"

alias :: proc(current_state: ^models.Shell_State, _: []string) -> os.Error {
    if len(current_state.aliases) == 0 {
        fmt.println("No alias defined :)")
        return nil
    }
    
    for alias_name, alias_value in current_state.aliases {
        fmt.printfln("%s=%s", alias_name, alias_value)
    }
    return nil
}