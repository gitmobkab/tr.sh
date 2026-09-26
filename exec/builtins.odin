package exec

import "core:sys/posix"
import "core:os"

import "../models"
import "../parser"
import "../utils"


exec_builtin :: proc(
    builtin_proc: models.builtin_proc,
    args: []string,
    current_state: ^models.Shell_state,
    command_io: Command_IO,
    redirects: []parser.Redirect
) -> []models.Error {
    
    saved_io := save_current_io()
    fds, errs := setup_redirects(redirects)
    defer delete(fds)
    if len(errs) > 0 {
        return errs
    } 
    dup_redirects(redirects, fds)

    exec_errs: [dynamic]models.Error
    setup_process_io(command_io)
    dup_redirects(redirects, fds)

    err := builtin_proc(current_state, args)
    if err != nil {
        append(&exec_errs, err)
    }
    
    // unnecessary comment 2
    setup_process_io(saved_io)

    return utils.snapshot_dynamic_array(models.Error, exec_errs)
}

save_current_io :: proc() -> Command_IO {
    
    current_io := default_command_io()
    current_io.stdin_source = posix.dup(posix.STDIN_FILENO)
    current_io.stdout_target = posix.dup(posix.STDOUT_FILENO)

    return current_io
}