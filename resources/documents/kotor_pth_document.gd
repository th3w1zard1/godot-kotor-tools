@tool
extends "../kotor_gff_document.gd"
class_name KotorPTHDocument

const POINT_LIST_FIELDS := ["Path_Points", "PathPoints", "Waypoints"]


func get_tag() -> String:
	return get_string("Tag")


func get_point_field_name() -> String:
	for field_name in POINT_LIST_FIELDS:
		var points := get_struct_list(field_name)
		if not points.is_empty():
			return field_name
	return ""


func get_point_count() -> int:
	var field_name := get_point_field_name()
	if not field_name.is_empty():
		return get_struct_list(field_name).size()
	return 0


func get_display_name() -> String:
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Point Field", get_point_field_name())
	_append_summary_line(lines, "Points", get_point_count())
	return lines
