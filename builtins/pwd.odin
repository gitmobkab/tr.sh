package builtins

import "core:fmt"

import "../models"

pwd :: proc(current_state: ^models.Shell_State, _: []string) -> models.Error {
    fmt.println(current_state.cwd)
    return nil
}