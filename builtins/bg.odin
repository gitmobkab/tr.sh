package builtins

import "core:os"

import "../models"

bg :: proc(current_state: ^models.Shell_State, _: []string) -> os.Error {
    return nil
}