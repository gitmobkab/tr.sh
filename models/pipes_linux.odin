package models

import "core:sys/posix"

import "../utils"

Process_Pipe :: struct {
    // the read end of the pipe, should be used for read only
    reader: posix.FD,
    // same logic except writing
    writer: posix.FD
}

init_pipes :: proc(pipes_num: int) -> (_pipes: []Process_Pipe, _errors: []Error) {
    pipes: [dynamic]Process_Pipe
    errs: [dynamic]Error
    defer delete(pipes)
    for _ in 0..<pipes_num {
        process_pipe, err := init_pipe()
        if err != nil {
            append(&errs, posix.errno())
        } else {
            append(&pipes, process_pipe)
        }
    }
    return utils.snapshot_dynamic_array(Process_Pipe, pipes), utils.snapshot_dynamic_array(Error, errs)
}

init_pipe :: proc() -> (_pipe: Process_Pipe, _err: Error) {
    fds: [2]posix.FD
    result := posix.pipe(&fds)
    if result == .OK {
        return Process_Pipe{reader= fds[0], writer = fds[1]}, nil
    }
    return {}, posix.errno()
}

close_pipe :: proc(pipe: Process_Pipe) {
    posix.close(pipe.reader)
    posix.close(pipe.writer)
}