package models

import "core:sys/posix"

Job_Entry :: struct {
    state: Job_State,
    pids: []posix.pid_t,
    pipeline_text: string,
}

Job_State :: enum u8 {
    Running,
    Stopped,
}