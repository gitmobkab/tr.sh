package main

import "core:sys/posix"
import "core:fmt"

import _ "builtins" // only for the @(init) side effects
import "models"
import "signals"
import "reader"
import "parser"
import "lexer"
import "exec"

PROMPT :: "TRSH > "

self_job_pipe: models.Process_Pipe

main :: proc() {

    shell_state, err := models.init_shell_state()
    if err != nil {
        fmt.eprintln(err)
        return
    }
    if job_pipe, err := get_job_pipe(); err != nil {
        fmt.eprintln(err)
        return
    } else {
        self_job_pipe = job_pipe
    }
    signals.ignore_signals(..shell_state.ignored_signals[:])
    signals.set_signal_handler(.SIGCHLD, sig_chld_handler)

    for !shell_state.should_exit {
        if err := shell_iteration(&shell_state); err != nil {
            fmt.println("UNEXPECTED ERR WHILE WORKING:", err)
            break
        }
    }
}

shell_iteration :: proc(shell_state: ^models.Shell_state) -> models.Error {
    fmt.print(PROMPT)
    line, err, sig_chld := reader.self_pipe_read(self_job_pipe)
    if err != nil {
        return err
    } else if sig_chld {
        reap_jobs(&shell_state.jobs)
        return nil
    }

    tokens := lexer.tokenize(line)
    defer delete(tokens)

    pipelines, parse_error := parser.parse(tokens[:])
    defer delete(pipelines)
    if parse_error != nil {
        fmt.println("trsh:", parser.get_error_msg(parse_error))
        return nil
    }
    errs := exec.exec_pipepilines(pipelines, shell_state)
    defer delete(errs)

    if len(errs) > 0 {
        fmt.println(errs)
        return nil
    }
    drain_fd(self_job_pipe.reader, shell_state)
    return nil
    
}

drain_fd :: proc(fd: posix.FD, shell_state: ^models.Shell_state) {
    drain_buf: [64]byte
    for {
        len := posix.read(self_job_pipe.reader, raw_data(drain_buf[:]), len(drain_buf))
        if len > 0 {
            reap_jobs(&shell_state.jobs)
        } else {
            break
        }
    }
}

sig_chld_handler :: proc "c" (_: posix.Signal) {
    buf: byte = 1
    posix.write(self_job_pipe.writer, &buf, 1)
}

get_job_pipe :: proc() -> (_pipe: models.Process_Pipe, _err: models.Error) {
    pipe, err := models.init_pipe()
    if err != nil {
        return {}, err
    }
    posix.fcntl(pipe.writer, .SETFL, posix.O_NONBLOCK)
    posix.fcntl(pipe.reader, .SETFL, posix.O_NONBLOCK)
    return pipe, nil
}
