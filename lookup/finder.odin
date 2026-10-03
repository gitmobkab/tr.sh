package lookup

import "core:os"
import "core:strings"

LOCAL_COMMAND_PREFIX :: "./"
DEFAULT_ENV_KEY :: "PATH"
DEFAULT_ENV_SPLITER :: ":"

find_command_on_path :: proc(command_name: string) -> (_abs_path: string, _err: os.Error) {
    dirs: []string
    if strings.starts_with(command_name, LOCAL_COMMAND_PREFIX) {
        cwd, err := os.get_working_directory(context.allocator)
        if err != nil {
            return "", err
        }
        dirs = {cwd}
    } else {
        dirs = get_all_directories_from_path()
    }
    path, err := get_command_absolute_path(command_name, dirs)
    return path, err
}

get_command_absolute_path :: proc(command_name: string, directories: []string) -> (path: string, error: os.Error) {
    for directory in directories {
        command_path, err := os.join_path({directory, command_name}, context.allocator)
        if err != nil {
            return "", err
        }
        if !os.is_file(command_path) {
            return "", .Invalid_Path
        } else {
            return command_path, nil
        }

    }
    return "", os.General_Error.Invalid_Command
}

get_all_directories_from_path :: proc() -> []string {
    normalized_key := strings.to_upper(DEFAULT_ENV_KEY)
    path := os.get_env(normalized_key, context.allocator)
    return strings.split(path, DEFAULT_ENV_SPLITER)
}
