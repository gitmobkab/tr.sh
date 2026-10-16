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

add_new_job :: proc(jobs: ^Job_Store, pids: []posix.pid_t, pgid: posix.pid_t, process_state: Process_State = .Running) -> int {
    process_entries := make([]Process_Entry, len(pids))
    defer delete(process_entries)

    new_job := Job_Entry{
        pgid = pgid,
    }

    for pid, i in pids {
        current_process_entry := Process_Entry{
            state = process_state,
        }
        process_entries[i] = current_process_entry
        new_job.processes[pid] = current_process_entry
    }

    id := get_next_job_id(jobs^)
    new_job.state = compute_job_state(process_entries)
    jobs[id] = new_job
    return id
}

destroy_job ::proc(jobs: ^Job_Store, job_id: int) {
    job_entry := &jobs[job_id]
    delete(job_entry.pipeline_text)
    delete(job_entry.processes)
    delete_key(jobs, job_id)
}

get_next_job_id :: proc(jobs: Job_Store) -> int {
    expected_id := 1
    for {
        _, exist := jobs[expected_id]
        if !exist {
            return expected_id
        }
        expected_id += 1
    }
    return expected_id
}

find_pid_job :: proc(pid: posix.pid_t, jobs: Job_Store) -> (_job_id: int, _found: bool) {
    for id, job in jobs {
        _, ok := job.processes[pid]
        if ok {
            return id, true
        } 
    }
    return -1, false
}

compute_job_state :: proc(processes: []Process_Entry) -> Job_State {
    if slice.any_of_proc(processes, process_is_stopped) {
        return .Stopped
    }
    if slice.all_of_proc(processes, process_is_done_or_terminated) {
        return .Done
    }
    return .Running
}

process_is_done_or_terminated :: proc(process: Process_Entry) -> bool {
    return process_is(.Done, process) || process_is(.Terminated, process)
}

process_is_stopped :: proc(process: Process_Entry) -> bool {
    return process_is(.Stopped, process)
}

process_is :: proc(state: Process_State, process: Process_Entry) -> bool {
    return process.state == state
}