@tool
extends "../kotor_gff_document.gd"
class_name KotorAREDocument


func get_area_name() -> String:
	return get_locstring_text("Name")


func get_tag() -> String:
	return get_string("Tag")


func get_display_name() -> String:
	var area_name := get_area_name()
	if not area_name.is_empty():
		return area_name
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_area_name())
	_append_summary_line(lines, "Tag", get_tag())
	append_script_hook_summary_lines(lines)
	return lines
