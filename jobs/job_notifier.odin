package jobs

import "core:fmt"

import "../models"

notify_and_clean_jobs :: proc(jobs: ^models.Job_Store) {
    job_ids_to_remove: [dynamic]int
    defer delete(job_ids_to_remove)
    for id, job in jobs {
        can_be_removed := notify_job(job, id)
        if can_be_removed {
            append(&job_ids_to_remove, id)
        }
    }

    for id in job_ids_to_remove {
        models.destroy_job(jobs, id)
    }
}

notify_job :: proc(job: models.Job_Entry, id: int) -> (_can_be_removed: bool) {
    can_be_removed := false
    #partial switch job.state {
        case .Done:
            fmt.printfln("[%d] Done", id)
            can_be_removed = true
        case .Stopped:
            fmt.printfln("[%d] Stopped", id)
    }
    return can_be_removed
}
