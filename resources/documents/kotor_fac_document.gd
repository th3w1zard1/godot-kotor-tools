@tool
extends "../kotor_gff_document.gd"
class_name KotorFACDocument


func get_label() -> String:
	return get_string("Label")


func get_tag() -> String:
	return get_string("Tag")


func get_appearance_count() -> int:
	return get_struct_list("Appearances").size()


func get_display_name() -> String:
	var label := get_label()
	if not label.is_empty():
		return label
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Label", get_label())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Appearances", get_appearance_count())
	return lines
