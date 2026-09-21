package main

import "core:os"
import "core:fmt"

import _ "builtins" // only for the @(init) side effects
import "models"
import "signals"
import "reader"
import "parser"
import "lexer"
import "exec"

PROMPT :: "TRSH > "

main :: proc() {

    shell_state, err := models.init_shell_state()
    if err != nil {
        fmt.println(err)
        return
    }
    signals.ignore_signals(..shell_state.ignored_signals[:])

    for !shell_state.should_exit {
        if shell_iteration(&shell_state) != nil {
            break
        }
    }
}

shell_iteration :: proc(shell_state: ^models.Shell_state) -> os.Error {
    fmt.print(PROMPT)
    line, err := reader.read_line()
    if err != nil {
        return err
    }
    tokens := lexer.tokenize(line)
    defer delete(tokens)

    pipelines, parse_error := parser.parse(tokens[:])
    defer delete(pipelines)
    if parse_error != nil {
        fmt.println("trsh:", parser.get_error_msg(parse_error))
        return nil
    }
    errs := exec.exec_pipepilines(pipelines, shell_state)
    defer delete(errs)

    if len(errs) > 0 {
        fmt.println(errs)
        return nil
    }
    return nil
}