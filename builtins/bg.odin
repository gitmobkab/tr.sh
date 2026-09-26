package builtins

import "core:fmt"
import "core:os"

import "../models"
import "../registry"

bg :: proc(current_state: ^models.Shell_state, _: []string) -> os.Error {
    return nil
}

@(init)
register_bg :: proc "contextless"() {
    registry.registry["bg"] = bg
}