package builtins

import "core:os"

import "../models"

exit :: proc(current_state: ^models.Shell_State, _: []string) -> os.Error {
    current_state.should_exit = true
    return nil
}