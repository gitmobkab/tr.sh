package builtins

import "base:runtime"
import "core:reflect"
import "core:fmt"
import "core:os"

import "../models"

PREFIX :: " "

state :: proc(current_state: ^models.Shell_State, args: []string) -> os.Error {
	field_names := reflect.struct_field_names(models.Shell_State)
	for field_name in field_names {
		field_value := reflect.struct_field_value_by_name(current_state, field_name, allow_using=true)
		

		fmt.println(field_name, field_value)
	}
	return nil
}

pretty_print :: proc(value: any, depth: int = 0) {
	type_info := type_info_of(value.id)
	base := reflect.type_info_base(type_info)

	if value.id == nil || value.data == nil {
		fmt.print("nil")
		return
	}

	#partial switch info in base.variant {
		case runtime.Type_Info_Integer, runtime.Type_Info_Float, runtime.Type_Info_Boolean,
			runtime.Type_Info_String, runtime.Type_Info_Rune:
			fmt.print(value)
		case :
			fmt.print(value) // unknown, unsuportted will use a plain color, the others will use a stylized color instead
	}
}