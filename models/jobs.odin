package models

import "core:sys/posix"

Job_Entry :: struct {
    state: Job_State,
    pgid: posix.pid_t,
    pids: []posix.pid_t,
    pipeline_text: string,
}

Job_State :: enum u8 {
    Running,
    Stopped,
}