package builtins

import "core:fmt"
import "core:os"

import "../models"

fg :: proc(current_state: ^models.Shell_State, args: []string) -> models.Error {
    if len(args) <= 1 {
        fmt.println("usage: fg <job_id>")
        return nil
    }
    
    return nil
}