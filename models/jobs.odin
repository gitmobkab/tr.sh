package models

import "core:slice"
import "core:sys/posix"

Job_Store :: map[int]Job_Entry

Job_Entry :: struct {
    pgid: posix.pid_t,
    processes: map[posix.pid_t]Process_Entry,
    state: Job_State,
    pipeline_text: string,
}

Job_State :: enum u8 {
    Running,
    Stopped,
    Done,
}

Process_Entry :: struct {
    state: Process_State,
    exit_code: int,
    signal: int,
}

// thinking about merging Job_State and Process_State
// don't know how to name the enum though, maybe keep it Process_State
Process_State :: enum u8 {
    Running,
    Stopped,
    Done,
    Terminated,
}

// TODO: too tired
add_new_job :: proc(pids: []posix.pid_t, jobs: ^Job_Store) {
    id := get_next_job_id(jobs^)

}

get_next_job_id :: proc(jobs: Job_Store) -> int {
    expected_id := 1
    for job_id in jobs {
        if job_id != expected_id {
            return expected_id
        }
        expected_id += 1
    }
    return expected_id
}

find_pid_job :: proc(pid: posix.pid_t, jobs: Job_Store) -> (_job_id: int, _job: Job_Entry) {
    for id, job in jobs {
        _, ok := job.processes[pid]
        if ok {
            return id, job
        } 
    }
    return -1, {}
}

compute_job_state :: proc(processes: []Process_Entry) -> Job_State {
    if slice.any_of_proc(processes, process_is_stopped) {
        return .Stopped
    }
    if slice.all_of_proc(processes, process_is_done) {
        return .Done
    }
    return .Running
}

process_is_done :: proc(process: Process_Entry) -> bool {
    return process_is(.Done, process)
}

process_is_stopped :: proc(process: Process_Entry) -> bool {
    return process_is(.Stopped, process)
}

process_is :: proc(state: Process_State, process: Process_Entry) -> bool {
    return process.state == state
}