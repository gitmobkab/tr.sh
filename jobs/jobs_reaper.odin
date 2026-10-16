package jobs

import "core:slice"
import "core:fmt"
import "core:sys/posix"

import "../models"

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

        job_id, found := models.find_pid_job(pid, jobs^)
        if !found {
            continue
        }
        job_entry := &jobs[job_id]
        process := &job_entry.processes[pid]

        switch {
            case posix.WIFEXITED(status):
                process.state = .Done
                process.exit_code = int(posix.WEXITSTATUS(status))
            case posix.WIFSIGNALED(status):
                process.state = .Terminated
                process.signal = int(posix.WTERMSIG(status))
            case posix.WIFSTOPPED(status):
                process.state = .Stopped
                process.signal = int(posix.WSTOPSIG(status))
            case posix.WIFCONTINUED(status):
                process.state = .Running
        }

        processes, err := slice.map_values(job_entry.processes)
        defer delete(processes)
        if err != nil {
            fmt.eprintln("trsh", err)
            continue
        }
        job_entry.state = models.compute_job_state(processes)
    }
}

