package builtins

import "core:os"
import "core:fmt"

import "../models"

cd :: proc(current_state: ^models.Shell_State, args: []string) -> os.Error {
    if len(args) < 2 {
        fmt.println("Missing operand <path>")
        return nil
    }
    target, err := os.get_absolute_path(args[1], context.allocator)
    if err != nil {
        return err
    }
    if err := os.chdir(target); err != nil {
        return err
    }
    current_state.cwd = target
    return nil
}