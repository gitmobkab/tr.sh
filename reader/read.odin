package reader

import "core:sys/posix"
import "core:strings"
import "core:os"
import "core:io"


import "../utils"
import "../models"

self_pipe_read :: proc(self_pipe: models.Process_Pipe) -> (_line: string, _err: models.Error, _sig_chld: bool) {
    max_fd := (self_pipe.reader > posix.STDIN_FILENO ? self_pipe.reader : posix.STDIN_FILENO)
    fd_num := i32(max_fd + 1)
    
    for {
        read_fds_set: posix.fd_set 
        posix.FD_ZERO(&read_fds_set)
        posix.FD_SET(posix.STDIN_FILENO, &read_fds_set)
        posix.FD_SET(self_pipe.reader, &read_fds_set)
        
        ready_fds := posix.select(fd_num, &read_fds_set, nil, nil, nil)
    
        if ready_fds < 0 {
            return "", posix.errno(), false
        }
        
        if posix.FD_ISSET(posix.STDIN_FILENO, &read_fds_set) {
            line, err := read_line()
            if err != nil {
                return line, err, false
            }
            return line, nil, false
        }
    
        if posix.FD_ISSET(self_pipe.reader, &read_fds_set) {
            drain_buf: [64]byte
            for posix.read(self_pipe.reader, raw_data(drain_buf[:]), len(drain_buf)) > 0 {}
            return "", nil, true
        }
    }
}


read_line :: proc () -> (string, os.Error) {
    buf: [1024]byte

    line_builder := strings.builder_make()
    defer strings.builder_destroy(&line_builder)
    for {
        count, err := os.read(os.stdin, buf[:])
        if err != nil {
            return "", err
        }
        if count == 0 {
            return "", io.Error.EOF
        }
        strings.write_bytes(&line_builder, buf[:count])
        
        if buf[count - 1] == '\n' {
            break
        }
    }
    raw_line := utils.builder_to_string(&line_builder)
    line := strings.trim_space(raw_line)
    return line, nil
}
