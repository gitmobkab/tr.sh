package builtins

import "core:fmt"
import "core:os"

import "../models"
import "../registry"

jobs :: proc(current_state: ^models.Shell_state, _: []string) -> os.Error {
    fmt.printfln("[id] - pgid (state)")
    for id, job in current_state.jobs {
        fmt.println("[%d] - %d (%s)", id, job.pgid, job.state)
    }
    return nil
}

@(init)
register_jobs :: proc "contextless"() {
    registry.registry["jobs"] = jobs
}