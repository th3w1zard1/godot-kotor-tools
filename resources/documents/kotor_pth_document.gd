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


func find_connection_record(connection_index: int) -> Dictionary:
	for connection_record in get_connection_records():
		if int(connection_record.get("index", -1)) == connection_index:
			return connection_record
	return {}


func add_connection(source_index: int, target_index: int) -> int:
	if source_index < 0 or source_index >= get_point_count():
		return -1
	if target_index < 0 or target_index >= get_point_count():
		return -1
	if source_index == target_index:
		return -1
	for connection_record in get_connection_records():
		if (
			int(connection_record.get("source_index", -1)) == source_index
			and int(connection_record.get("target_index", -1)) == target_index
		):
			return -1
	var edges: Array[Dictionary] = []
	for connection_record in get_connection_records():
		edges.append({
			"source_index": int(connection_record.get("source_index", -1)),
			"target_index": int(connection_record.get("target_index", -1)),
			"raw": (connection_record.get("raw", {}) as Dictionary).duplicate(true),
		})
	edges.append({
		"source_index": source_index,
		"target_index": target_index,
		"raw": _build_default_connection_struct(target_index),
	})
	if not _rebuild_connection_topology(edges):
		return -1
	for connection_record in get_connection_records():
		if (
			int(connection_record.get("source_index", -1)) == source_index
			and int(connection_record.get("target_index", -1)) == target_index
		):
			return int(connection_record.get("index", -1))
	return -1


func set_connection_destination(connection_index: int, target_index: int) -> bool:
	var connection_field := get_connection_field_name()
	if connection_field.is_empty():
		return false
	var point_count := get_point_count()
	if target_index < 0 or target_index >= point_count:
		return false
	var connections := get_struct_list(connection_field)
	if connection_index < 0 or connection_index >= connections.size():
		return false
	var source_index := _connection_source_index(connection_index)
	if source_index < 0 or source_index == target_index:
		return false
	var raw_connection: Dictionary = connections[connection_index]
	var target_field := _connection_target_field_name(raw_connection)
	if target_field.is_empty():
		return false
	var path := [connection_field, connection_index, target_field]
	return set_field_at_path(path, target_index)


func add_point(x: float, y: float, z: float = 0.0) -> int:
	var field_name := _resolve_point_field_name()
	if field_name.is_empty():
		return -1
	if not has_field(field_name):
		set_field(field_name, [])
	var index := get_point_count()
	var new_point := _build_default_point_struct(
		_next_point_id(index),
		x,
		y,
		z,
		_next_first_connection_index()
	)
	if not insert_struct_at_array(field_name, index, new_point):
		return -1
	return index


func capture_topology_snapshot() -> Dictionary:
	var point_field := _resolve_point_field_name()
	var connection_field := get_connection_field_name()
	var points: Array = []
	var connections: Array = []
	if not point_field.is_empty() and has_field(point_field):
		for point in get_struct_list(point_field):
			points.append((point as Dictionary).duplicate(true))
	if not connection_field.is_empty() and has_field(connection_field):
		for connection in get_struct_list(connection_field):
			connections.append((connection as Dictionary).duplicate(true))
	return {
		"point_field": point_field,
		"connection_field": connection_field,
		"points": points,
		"connections": connections,
	}


func restore_topology_snapshot(snapshot: Dictionary) -> bool:
	var point_field := str(snapshot.get("point_field", ""))
	if point_field.is_empty():
		return false
	var changed := set_field(point_field, snapshot.get("points", []))
	var connection_field := str(snapshot.get("connection_field", ""))
	if not connection_field.is_empty():
		changed = set_field(connection_field, snapshot.get("connections", [])) or changed
	return changed


func remove_point(index: int) -> bool:
	if index < 0 or index >= get_point_count():
		return false
	var surviving_edges: Array[Dictionary] = []
	for connection_record in get_connection_records():
		var source_index := int(connection_record.get("source_index", -1))
		var target_index := int(connection_record.get("target_index", -1))
		if source_index == index or target_index == index:
			continue
		surviving_edges.append({
			"source_index": source_index - 1 if source_index > index else source_index,
			"target_index": target_index - 1 if target_index > index else target_index,
			"raw": (connection_record.get("raw", {}) as Dictionary).duplicate(true),
		})
	var point_field := _resolve_point_field_name()
	if point_field.is_empty() or not remove_struct_from_array(point_field, index):
		return false
	return _rebuild_connection_topology(surviving_edges)


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


func _connection_source_index(connection_index: int) -> int:
	var points := get_point_records()
	var connection_field := get_connection_field_name()
	if connection_field.is_empty():
		return -1
	var connections := get_struct_list(connection_field)
	for source_index in range(points.size()):
		var point: Dictionary = points[source_index]
		var raw_point: Dictionary = point.get("raw", {})
		var connection_count := _point_int(raw_point, POINT_CONNECTION_COUNT_FIELDS, 0)
		var first_connection := _point_int(raw_point, POINT_FIRST_CONNECTION_FIELDS, 0)
		for offset in range(connection_count):
			if first_connection + offset == connection_index:
				return source_index
	return -1


static func _connection_target_field_name(connection: Dictionary) -> String:
	for field_name in CONNECTION_TARGET_FIELDS:
		if connection.has(field_name):
			return String(field_name)
	return ""


func _resolve_point_field_name() -> String:
	var existing := get_point_field_name()
	if not existing.is_empty():
		return existing
	for field_name in POINT_LIST_FIELDS:
		if has_field(field_name):
			return field_name
	return "Path_Points"


func _next_point_id(fallback_index: int) -> int:
	var max_id := 0
	for point_record in get_point_records():
		max_id = max(max_id, int(point_record.get("id", 0)))
	return max_id + 1 if max_id > 0 else fallback_index + 1


func _next_first_connection_index() -> int:
	var connection_field := get_connection_field_name()
	if connection_field.is_empty():
		return 0
	return get_struct_list(connection_field).size()


func _rebuild_connection_topology(edges: Array) -> bool:
	var point_field := _resolve_point_field_name()
	var connection_field := get_connection_field_name()
	var point_count := get_point_count()
	var edges_by_source: Dictionary = {}
	for raw_edge in edges:
		if typeof(raw_edge) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = raw_edge
		var source_index := int(edge.get("source_index", -1))
		if source_index < 0 or source_index >= point_count:
			continue
		if not edges_by_source.has(source_index):
			edges_by_source[source_index] = []
		(edges_by_source[source_index] as Array).append(edge)
	var new_connections: Array = []
	var points := get_struct_list(point_field)
	for source_index in range(point_count):
		var raw_point: Dictionary = points[source_index]
		var source_edges: Array = edges_by_source.get(source_index, [])
		var count_field := _point_field_name(raw_point, POINT_CONNECTION_COUNT_FIELDS)
		var first_field := _point_field_name(raw_point, POINT_FIRST_CONNECTION_FIELDS)
		if count_field.is_empty():
			count_field = "Conections"
		if first_field.is_empty():
			first_field = "First_Conection"
		var first_connection := new_connections.size()
		var count_path := [point_field, source_index, count_field]
		var first_path := [point_field, source_index, first_field]
		set_field_at_path(count_path, source_edges.size())
		set_field_at_path(first_path, first_connection)
		for edge in source_edges:
			if typeof(edge) != TYPE_DICTIONARY:
				continue
			var connection_struct := (edge.get("raw", {}) as Dictionary).duplicate(true)
			var target_field := _connection_target_field_name(connection_struct)
			if target_field.is_empty():
				target_field = "Destination"
			connection_struct[target_field] = int(edge.get("target_index", -1))
			new_connections.append(connection_struct)
	if connection_field.is_empty():
		if new_connections.is_empty():
			return true
		connection_field = "Path_Conections"
	return set_field(connection_field, new_connections)


func _build_default_connection_struct(target_index: int) -> Dictionary:
	var template: Dictionary = {}
	var connection_field := get_connection_field_name()
	if not connection_field.is_empty() and has_field(connection_field):
		var connections := get_struct_list(connection_field)
		if not connections.is_empty():
			template = connections[0]
	var connection := {}
	var target_field := _connection_target_field_name(template)
	connection[target_field if not target_field.is_empty() else "Destination"] = target_index
	return connection


func _build_default_point_struct(
	point_id: int,
	x: float,
	y: float,
	z: float,
	first_connection: int
) -> Dictionary:
	var template: Dictionary = {}
	var records := get_point_records()
	if not records.is_empty():
		template = records[0].get("raw", {})
	var point := {}
	var id_field := _point_field_name(template, POINT_ID_FIELDS)
	point[id_field if not id_field.is_empty() else "ID"] = point_id
	var x_field := _point_field_name(template, POINT_X_FIELDS)
	point[x_field if not x_field.is_empty() else "X"] = x
	var y_field := _point_field_name(template, POINT_Y_FIELDS)
	point[y_field if not y_field.is_empty() else "Y"] = y
	var z_field := _point_field_name(template, POINT_Z_FIELDS)
	point[z_field if not z_field.is_empty() else "Z"] = z
	var count_field := _point_field_name(template, POINT_CONNECTION_COUNT_FIELDS)
	point[count_field if not count_field.is_empty() else "Conections"] = 0
	var first_field := _point_field_name(template, POINT_FIRST_CONNECTION_FIELDS)
	point[first_field if not first_field.is_empty() else "First_Conection"] = first_connection
	return point
