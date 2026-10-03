package builtins

import "base:runtime"
import "core:reflect"
import "core:fmt"
import "core:os"

import "../models"

PRFIX :: " "

state :: proc(current_state: ^models.Shell_State, args: []string) -> os.Error {
	field_names := reflect.struct_field_names(models.Shell_State)
	for field_name in field_names {
		field_value := reflect.struct_field_value_by_name(current_state, field_name, allow_using=true)
		

		fmt.println(field_name, field_value)
	}
	return nil
}

pretty_print :: proc(value: any, depth: int = 0) {

}