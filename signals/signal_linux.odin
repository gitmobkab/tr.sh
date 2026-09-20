package signal

import "core:sys/posix"


ignore_signals :: proc(signals: ..posix.Signal) {
    for signal in signals {
        ignore_signal(signal)
    }
}

restore_default_signals :: proc(signals: ..posix.Signal) {
    for signal in signals {
        restore_default_signal(signal)
    }
}

ignore_signal :: proc(signal: posix.Signal) {
    act: posix.sigaction_t
    act.sa_handler = auto_cast posix.SIG_IGN
    posix.sigemptyset(&act.sa_mask)
    act.sa_flags = {}
    posix.sigaction(signal, &act, nil)
}

restore_default_signal :: proc(signal: posix.Signal) {
    act: posix.sigaction_t
    act.sa_handler = auto_cast posix.SIG_DFL
    posix.sigemptyset(&act.sa_mask)
    act.sa_flags = {}
    posix.sigaction(signal, &act, nil)
}