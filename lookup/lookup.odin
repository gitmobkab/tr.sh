package lookup

import "core:os"

import "../models"

search_command :: proc(
    command_name: string,
    cwd: string,
    cache: map[string]string,
    builtins_store: models.Builtin_Store
) -> (_command: Found_Command, _err: os.Error) {
    if builtin_fn, found := builtins_store[command_name]; found {
        return Found_Command{kind = .Builtin, builtin_proc = builtin_fn}, nil
    }

    if cached_path, found := cache[command_name]; found {
        return Found_Command{kind = .External, path = cached_path}, nil
    }

    abs_path, err := find_command_on_path(command_name, cwd)
    if err != nil {
        return {}, err
    } 
    return Found_Command{kind = .External, path = abs_path}, nil
}