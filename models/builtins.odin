package models

Builtin_Store :: map[string]builtin_proc

builtin_proc :: #type proc(current_state: ^Shell_State, args: []string) -> Error