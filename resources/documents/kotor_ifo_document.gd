@tool
extends "../kotor_gff_document.gd"
class_name KotorIFODocument


func get_module_name() -> String:
	return get_locstring_text("Mod_Name")


func get_module_tag() -> String:
	return get_string("Mod_Tag")


func get_module_resref() -> String:
	return get_resref("Mod_ResRef")


func get_starting_area_count() -> int:
	return get_struct_list("Mod_Area_list").size()


func get_display_name() -> String:
	var module_name := get_module_name()
	if not module_name.is_empty():
		return module_name
	var module_resref := get_module_resref()
	return module_resref if not module_resref.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Module", get_module_name())
	_append_summary_line(lines, "ResRef", get_module_resref())
	_append_summary_line(lines, "Tag", get_module_tag())
	_append_summary_line(lines, "Areas", get_starting_area_count())
	_append_summary_line(lines, "On Load", get_resref("OnModLoad"))
	_append_summary_line(lines, "On Heartbeat", get_resref("Mod_OnHeartbeat"))
	return lines
