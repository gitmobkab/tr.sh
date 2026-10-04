#+feature dynamic-literals
package builtins

import "../models"

BUILTINS := models.Builtin_Store{
    "alias" = alias,
    "bg" = bg,
    "cd" = cd,
    "exit" = exit,
    "fg" = fg,
    "hash" = hash,
    "jobs" = jobs,
    "kill" = kill,
    "pwd" = pwd,
    "state" = state,
    "which" = which,
}