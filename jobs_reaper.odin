package main

import "core:slice"
import "core:fmt"
import "core:sys/posix"
import "models"

reap_jobs :: proc(jobs: ^models.Job_Store) {
    for {
        status: i32
        pid := posix.waitpid(-1, &status, {.NOHANG, .UNTRACED, .CONTINUED})

        if pid == 0 {
            break
        } else if pid == -1 {
            if errno := posix.errno(); errno != .ECHILD {
                fmt.println(errno)
            } 
            break
        }

        job_id, job_entry := models.find_pid_job(pid, jobs^)
        if job_id == -1 {
            continue
        }
        process := job_entry.processes[pid]

        switch {
            case posix.WIFEXITED(status):
                process.state = .Exited
                process.exit_code = int(posix.WEXITSTATUS(status))
            case posix.WIFSIGNALED(status):
                process.state = .Terminated
                process.signal = int(posix.WTERMSIG(status))
            case posix.WIFSTOPPED(status):
                process.state = .Stopped
            case posix.WIFCONTINUED(status):
                process.state = .Running
        }

        processes, err := slice.map_values(job_entry.processes)
        if err != nil {
            fmt.eprintln(err)
            break
        }
        job_entry.state = models.compute_job_state(processes)
        if job_entry.state == .Done {
            fmt.println("DONE", job_entry)
            delete_key(jobs, job_id)
        }
    }
}

