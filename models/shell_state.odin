package models

import "core:os"
import "core:sys/posix"

import "../utils"

Shell_state :: struct {
    cwd: string,

    pgid: posix.pid_t,
    
    public_env: map[string]string,

    // do not confuse with the public env passed to programs (not used until we support variables lookup)
    private_env: map[string]string,
    aliases: map[string]string,
    should_exit: bool,
    exit_code: u8,
}

init_shell_state :: proc() -> (Shell_state, os.Error) {
    state := Shell_state{ should_exit = false }
    if working_dir, err := os.get_working_directory(context.allocator); err != nil {
        return {}, err
    } else {
        state.cwd = working_dir
    }
    
    if environ, err := os.environ(context.allocator); err != nil{
        return {}, err
    } else {
        utils.populate_env(&state.public_env, environ)
    }

    state.pgid = posix.getpgid(0)
    
    return state, nil
}
