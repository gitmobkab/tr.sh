package builtins

import "core:strings"
import "base:runtime"
import "core:reflect"
import "core:fmt"

import "../models"

PREFIX :: " "
NIL_REPR :: "<nil>"

LEAF_TYPES_INFO :: []runtime.Type_Info

state :: proc(current_state: ^models.Shell_State, _: []string) -> models.Error {
	stdout_builder := strings.builder_make()
	defer strings.builder_destroy(&stdout_builder)


	pretty_print(current_state, 1, &stdout_builder)
	
	fmt.println(strings.to_string(stdout_builder))

	return nil
}

pretty_print :: proc(value: any, depth: int = 0, builder: ^strings.Builder) {
	repeated_prefix := strings.repeat(PREFIX, depth)

	type_info := type_info_of(value.id)
	base := reflect.type_info_base(type_info)

	if value.id == nil || value.data == nil {
		strings.write_string(builder, NIL_REPR)
		return
	}

	#partial switch info in base.variant {
		case runtime.Type_Info_Integer, runtime.Type_Info_Float, runtime.Type_Info_Boolean,
			runtime.Type_Info_String, runtime.Type_Info_Rune:
			fmt.sbprintln(builder, value)

		case runtime.Type_Info_Struct:
			for index in 0..<info.field_count {
				fmt.sbprintf(builder, "%s.%s: ", repeated_prefix, info.names[index])
				child := any{
					data = rawptr(uintptr(value.data) + info.offsets[index]),
					id = info.types[index].id
				}
				pretty_print(child, depth + 1, builder)
			}
		case runtime.Type_Info_Pointer:
			target := (^rawptr)(value.data)^
			if target == nil {
				fmt.sbprintln(builder, NIL_REPR)
				return
			} 
			if info.elem == nil {
				fmt.sbprintln(builder, value.data)
				return
			}
			child := any{data =  target, id = info.elem.id}
			pretty_print(child, depth + 1, builder)
		case runtime.Type_Info_Slice:
			strings.write_string(builder, "[")
			header := (^runtime.Raw_Slice)(value.data)^

			for index in 0..<header.len {
				child := any{
					data = rawptr(uintptr(header.data) + uintptr(index * info.elem_size)),
					id = info.elem.id
				}
				pretty_print(child, depth + 1, builder)
				strings.write_string(builder, ", ")
			}

			strings.write_string(builder, "]")
		case runtime.Type_Info_Map:
			fmt.sbprintln(builder)
			it: int
			for key, val in reflect.iterate_map(value, &it) {
				
				fmt.sbprint(builder, repeated_prefix)
				base_info := runtime.type_info_base(type_info_of(val.id))
				
				if is_leaf(base_info) {
					fmt.sbprintfln(builder, " %v -> %v", key, val)
				} else {
					fmt.sbprintln(builder, key)
					pretty_print(val, depth + 1, builder)
				}

			}

		
	}
}

is_leaf :: proc(base: ^runtime.Type_Info) -> bool {
    #partial switch _ in base.variant {
    case runtime.Type_Info_Integer, runtime.Type_Info_Float,
         runtime.Type_Info_Boolean, runtime.Type_Info_String,
         runtime.Type_Info_Rune, runtime.Type_Info_Enum:
        return true
    }
    return false
}