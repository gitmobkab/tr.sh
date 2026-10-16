package builtins

import "core:fmt"

import "../models"

jobs :: proc(current_state: ^models.Shell_State, _: []string) -> models.Error {
    fmt.printfln("[id] - pgid (state)")
    for id, job in current_state.jobs {
        fmt.printfln("[%d] - %d (%v)", id, job.pgid, job.state)
    }
    return nil
}