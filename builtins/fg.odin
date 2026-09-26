package builtins

import "core:fmt"
import "core:os"

import "../models"
import "../registry"

fg :: proc(current_state: ^models.Shell_state, args: []string) -> os.Error {
    if len(args) == 0 {
        fmt.println("usage: fg <job_id>")
        return nil
    }
    
    return nil
}

@(init)
register_fg :: proc "contextless"() {
    registry.registry["fg"] = fg
}