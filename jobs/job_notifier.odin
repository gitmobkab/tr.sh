package jobs

import "core:strings"
import "core:fmt"

import "../models"

notify_and_clean_jobs :: proc(jobs: ^models.Job_Store) {
    job_ids_to_remove: [dynamic]int
    defer delete(job_ids_to_remove)

    output_builder := strings.builder_make()
    defer strings.builder_destroy(&output_builder)

    for id, job in jobs {
        can_be_removed := notify_job_through_builder(&output_builder, job, id)
        if can_be_removed {
            append(&job_ids_to_remove, id)
        }
    }

    if len(output_builder.buf) > 0 {
        summary := strings.to_string(output_builder)
        fmt.printfln("\n%s", strings.trim_right(summary, "\n"))
    }

    for id in job_ids_to_remove {
        models.destroy_job(jobs, id)
    }
}


notify_job :: proc(job: models.Job_Entry, id: int) -> (_can_be_removed: bool) {
    output_builder := strings.builder_make()
    defer strings.builder_destroy(&output_builder)
    
    can_be_removed := notify_job_through_builder(&output_builder, job, id)
    fmt.println(strings.to_string(output_builder))
    
    return can_be_removed
}

notify_job_through_builder :: proc(builder: ^strings.Builder, job: models.Job_Entry, id: int) -> (_can_be_removed: bool) {
    can_be_removed := false
    if job.state != .Running {
        fmt.sbprintfln(builder, "[%d] %v", id, job.state)
        can_be_removed = (job.state == .Done)
    }
    return can_be_removed
}
