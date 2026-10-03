package models

import "core:strings"

ENV_SEP :: "="

Env_Store :: map[string]Env_Entry

Env_Entry :: struct {
    value: string,
    exportable: bool
}

env_store_to_environ :: proc(env_store: Env_Store) -> []string {
    environ: [dynamic]string
    i := 0
    for key, entry in env_store {
        if !entry.exportable {
            continue
        }
        key_value_string := strings.join({key, entry.value}, ENV_SEP)
        append(&environ, key_value_string)
        i += 1
    }
    return environ[:]
}

populate_env :: proc(env_store: ^Env_Store, environ: []string, exportable: bool = true) {
    for env_pair in environ {
        parts := strings.split(env_pair, ENV_SEP)
        name := parts[0]
        value := parts[1]
        env_store[name] = {value = value, exportable = exportable}
    }
}