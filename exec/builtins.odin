package exec

import "core:os"
import "core:fmt"

import "../models"

no_op_executer :: proc(ctx: Exec_Context) {}

builtin_executer :: proc(ctx: Exec_Context) {
    err := ctx.builtin_proc(&ctx.shell.state, ctx.argv)
    if err != nil {
        fmt.eprintln("trsh:", err)
    }
}