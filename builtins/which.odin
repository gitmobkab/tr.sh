package builtins

import "core:fmt"
import "core:os"

import "../lookup"
import "../models"

which :: proc(current_state: ^models.Shell_State, args: []string) -> models.Error {
    if len(args) <= 1 {
        fmt.println("missing operand <cmd>")
        fmt.println("usage: which <cmd>")
        return nil
    }
    cmd := args[1]
    found_command, err := lookup.search_command(cmd, current_state.cwd, &current_state.commands_cache, BUILTINS) // hmm...
    if err != nil {
        return err
    }
    description: string
    switch found_command.kind {
        case .Builtin:
            description = "shell built-in command"
        case .External:
            description = fmt.tprintf("external command at '%s'",found_command.path)
    }
    fmt.printfln("%s: %s",cmd, description)
    return nil
}