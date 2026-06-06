@tool
extends "../kotor_gff_document.gd"
class_name KotorPTHDocument

const POINT_LIST_FIELDS := ["Path_Points", "PathPoints", "Waypoints"]
const POINT_ID_FIELDS := ["ID", "Id"]
const POINT_X_FIELDS := ["X", "XPosition", "XPos"]
const POINT_Y_FIELDS := ["Y", "YPosition", "YPos"]
const POINT_Z_FIELDS := ["Z", "ZPosition", "ZPos"]


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


func get_point_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var field_name := get_point_field_name()
	if field_name.is_empty():
		return records
	var points := get_struct_list(field_name)
	for index in range(points.size()):
		var point := points[index]
		records.append({
			"index": index,
			"id": _point_int(point, POINT_ID_FIELDS, index),
			"x": _point_float(point, POINT_X_FIELDS),
			"y": _point_float(point, POINT_Y_FIELDS),
			"z": _point_float(point, POINT_Z_FIELDS),
			"raw": point,
		})
	return records


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


static func _point_float(point: Dictionary, field_names: Array) -> float:
	for field_name in field_names:
		if point.has(field_name):
			return float(point.get(field_name, 0.0))
	return 0.0


static func _point_int(point: Dictionary, field_names: Array, default_value: int) -> int:
	for field_name in field_names:
		if point.has(field_name):
			return int(point.get(field_name, default_value))
	return default_value
