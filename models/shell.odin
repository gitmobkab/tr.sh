package models

import "core:sys/posix"

SIGNALS := []posix.Signal{
    .SIGINT,
    .SIGTTIN,
    .SIGTTOU
}

Shell :: struct {
    state: Shell_State,
    builtins: Builtin_Store,
    signals: []posix.Signal,
    // config?
}

// give a fresh shell, due to circurlar imports shenanigans, the builtins aren't directly populated
// which makes it the caller job now
init_shell :: proc() -> (_shell: Shell, _init_error: Error) {
    default_shell := Shell{}
    startup_state, err := init_shell_state()
    if err != nil {
        return {}, nil
    }
    default_shell.state = startup_state
    default_shell.signals = SIGNALS

    return default_shell, nil
}