@tool
extends "../kotor_gff_document.gd"
class_name KotorAREDocument


func get_area_name() -> String:
	return get_locstring_text("Name")


func get_tag() -> String:
	return get_string("Tag")


func get_on_enter_script() -> String:
	return get_resref("OnEnter")


func get_on_exit_script() -> String:
	return get_resref("OnExit")


func get_on_heartbeat_script() -> String:
	return get_resref("OnHeartbeat")


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
	_append_summary_line(lines, "On Enter", get_on_enter_script())
	_append_summary_line(lines, "On Exit", get_on_exit_script())
	_append_summary_line(lines, "On Heartbeat", get_on_heartbeat_script())
	return lines
