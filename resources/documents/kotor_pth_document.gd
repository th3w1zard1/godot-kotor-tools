@tool
extends "../kotor_gff_document.gd"
class_name KotorPTHDocument

const POINT_LIST_FIELDS := ["Path_Points", "PathPoints", "Waypoints"]
const POINT_ID_FIELDS := ["ID", "Id"]
const POINT_X_FIELDS := ["X", "XPosition", "XPos"]
const POINT_Y_FIELDS := ["Y", "YPosition", "YPos"]
const POINT_Z_FIELDS := ["Z", "ZPosition", "ZPos"]
# KotOR/PyKotor carry historical misspellings in the connection field names.
const CONNECTION_LIST_FIELDS := ["Path_Conections", "PathConnections", "Path_Connections"]
const POINT_CONNECTION_COUNT_FIELDS := ["Conections", "Connections"]
const POINT_FIRST_CONNECTION_FIELDS := ["First_Conection", "FirstConnection", "First_Connection"]
const CONNECTION_TARGET_FIELDS := ["Destination", "Target", "To"]


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
			"path": [field_name, index],
			"id": _point_int(point, POINT_ID_FIELDS, index),
			"x": _point_float(point, POINT_X_FIELDS),
			"y": _point_float(point, POINT_Y_FIELDS),
			"z": _point_float(point, POINT_Z_FIELDS),
			"raw": point,
	})
	return records


func get_connection_field_name() -> String:
	for field_name in CONNECTION_LIST_FIELDS:
		if has_field(field_name):
			return field_name
	return ""


func get_connection_count() -> int:
	return get_connection_records().size()


func get_connection_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var field_name := get_connection_field_name()
	if field_name.is_empty():
		return records
	var connections := get_struct_list(field_name)
	if connections.is_empty():
		return records
	var points := get_point_records()
	for source_index in range(points.size()):
		var point: Dictionary = points[source_index]
		var raw_point: Dictionary = point.get("raw", {})
		var connection_count := _point_int(raw_point, POINT_CONNECTION_COUNT_FIELDS, 0)
		var first_connection := _point_int(raw_point, POINT_FIRST_CONNECTION_FIELDS, 0)
		for offset in range(connection_count):
			var connection_index := first_connection + offset
			if connection_index < 0 or connection_index >= connections.size():
				continue
			var raw_connection: Dictionary = connections[connection_index]
			var target_index := _point_int(raw_connection, CONNECTION_TARGET_FIELDS, -1)
			if target_index < 0 or target_index >= points.size():
				continue
			var target: Dictionary = points[target_index]
			records.append({
				"index": connection_index,
				"source_index": source_index,
				"target_index": target_index,
				"source_id": int(point.get("id", source_index)),
				"target_id": int(target.get("id", target_index)),
				"source_x": float(point.get("x", 0.0)),
				"source_y": float(point.get("y", 0.0)),
				"source_z": float(point.get("z", 0.0)),
				"target_x": float(target.get("x", 0.0)),
				"target_y": float(target.get("y", 0.0)),
				"target_z": float(target.get("z", 0.0)),
				"raw": raw_connection,
			})
	return records


func find_point_record(index: int) -> Dictionary:
	for point_record in get_point_records():
		if int(point_record.get("index", -1)) == index:
			return point_record
	return {}


func set_point_position(index: int, x: float, y: float, z: Variant = null) -> bool:
	var point_record := find_point_record(index)
	if point_record.is_empty():
		return false
	var base_path: Array = point_record.get("path", [])
	if base_path.is_empty():
		return false
	var raw_point: Dictionary = point_record.get("raw", {})
	var changed := false
	changed = _set_point_float(base_path, raw_point, POINT_X_FIELDS, x) or changed
	changed = _set_point_float(base_path, raw_point, POINT_Y_FIELDS, y) or changed
	if z != null:
		changed = _set_point_float(base_path, raw_point, POINT_Z_FIELDS, float(z)) or changed
	return changed


func get_display_name() -> String:
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Point Field", get_point_field_name())
	_append_summary_line(lines, "Points", get_point_count())
	_append_summary_line(lines, "Connection Field", get_connection_field_name())
	_append_summary_line(lines, "Connections", get_connection_count())
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


func _set_point_float(base_path: Array, raw_point: Dictionary, field_names: Array, value: float) -> bool:
	var field_name := _point_field_name(raw_point, field_names)
	if field_name.is_empty():
		return false
	var path := base_path.duplicate()
	path.append(field_name)
	return set_field_at_path(path, value)


static func _point_field_name(point: Dictionary, field_names: Array) -> String:
	for field_name in field_names:
		if point.has(field_name):
			return String(field_name)
	return ""
