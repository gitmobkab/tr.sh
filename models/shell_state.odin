package models

import "core:os"
import "core:sys/posix"

import "../utils"

Shell_state :: struct {
    cwd: string,

    pgid: posix.pid_t,
    jobs: map[int]Job_Entry,
    public_env: map[string]string,
    ignored_signals: [3]posix.Signal,

    // do not confuse with the public env passed to programs (not used until we support variables lookup)
    private_env: map[string]string,
    aliases: map[string]string,
    should_exit: bool,
    exit_code: u8,
}

init_shell_state :: proc() -> (Shell_state, Error) {
    state := Shell_state{
        ignored_signals = [3]posix.Signal{.SIGINT, .SIGTTOU, .SIGTTIN},
        should_exit = false 
    }
    
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

    if pgid := posix.getpgid(0); pgid == -1 {
        return {}, posix.errno()
    } else {
        state.pgid = pgid
    }
    
    return state, nil
}
