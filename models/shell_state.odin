package models

import "core:os"
import "core:sys/posix"

Shell_State :: struct {
    pgid: posix.pid_t,
    
    cwd: string,
    jobs: Job_Store,
    env: Env_Store,
    
    commands_cache: map[string]string,

    aliases: map[string]string,
    should_exit: bool,

    // exit_code: u8,
}

init_shell_state :: proc() -> (Shell_State, Error) {
    state := Shell_State{ should_exit = false } // yes, i know this is useless, just like staying explicit
    
    if working_dir, err := os.get_working_directory(context.allocator); err != nil {
        return {}, err
    } else {
        state.cwd = working_dir
    }
    
    if environ, err := os.environ(context.allocator); err != nil{
        return {}, err
    } else {
        populate_env(&state.env, environ)
    }

    if pgid := posix.getpgid(0); pgid == -1 {
        return {}, posix.errno()
    } else {
        state.pgid = pgid
    }
    
    return state, nil
}
