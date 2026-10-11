package builtins

import "../models"

exit :: proc(current_state: ^models.Shell_State, _: []string) -> models.Error {
    current_state.should_exit = true
    return nil
}