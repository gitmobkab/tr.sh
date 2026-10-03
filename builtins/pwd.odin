package builtins

import "core:fmt"
import "core:os"

import "../models"

pwd :: proc(current_state: ^models.Shell_State, _: []string) -> os.Error {
    fmt.println(current_state.cwd)
    return nil
}