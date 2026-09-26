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

Process_State :: enum u8 {
    Running,
    Stopped,
    Exited,
    Terminated,
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
    if slice.all_of_proc(processes, process_had_exited) {
        return .Done
    }
    return .Running
}

process_had_exited :: proc(process: Process_Entry) -> bool {
    return process_is(.Exited, process)
}

process_is_stopped :: proc(process: Process_Entry) -> bool {
    return process_is(.Stopped, process)
}

process_is :: proc(state: Process_State, process: Process_Entry) -> bool {
    return process.state == state
}