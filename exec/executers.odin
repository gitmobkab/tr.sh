package exec

import "core:strings"
import "core:sys/posix"
import "core:os"
import "core:fmt"

import "../models"
import "../utils"

no_op_executer :: proc(ctx: Exec_Context) {}

builtin_command_executer :: proc(ctx: Exec_Context) {
    err := ctx.builtin_proc(&ctx.shell.state, ctx.argv)
    if err != nil {
        fmt.eprintln("trsh:", err)
    }
}

external_command_executer :: proc(ctx: Exec_Context) {
    c_path := strings.clone_to_cstring(ctx.path)
    c_argv := utils.strings_to_cstrings(ctx.argv)
    c_envp := utils.strings_to_cstrings(ctx.environ)
    posix.execve(c_path, c_argv, c_envp)

    fmt.eprintfln("trsh: %v: %v", posix.strerror(posix.errno()), ctx.path)
}