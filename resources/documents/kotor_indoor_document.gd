@tool
extends RefCounted
class_name KotorIndoorDocument

signal changed

const KotorIndoorMapIO := preload("../indoor/kotor_indoor_map_io.gd")
const KotorIndoorKitLibrary := preload("../indoor/kotor_indoor_kit_library.gd")
const BWMParser := preload("../../formats/bwm_parser.gd")

const DEFAULT_HALF_EXTENT := 2.0

var _data: Dictionary = {}
var _embedded_by_id: Dictionary = {}
var _kit_library: RefCounted


func load_from_bytes(data: PackedByteArray) -> bool:
	var parsed := KotorIndoorMapIO.parse_bytes(data)
	if parsed.is_empty():
		return false
	_set_data(parsed)
	return true


func load_from_dictionary(data: Dictionary) -> void:
	_set_data(data.duplicate(true))


func serialize_to_bytes() -> PackedByteArray:
	return KotorIndoorMapIO.write_bytes(_data)


func get_data() -> Dictionary:
	return _data.duplicate(true)


func get_module_id() -> String:
	return str(_data.get("warp", _data.get("module_id", "test01")))


func get_display_name() -> String:
	var name_data: Variant = _data.get("name", {})
	if typeof(name_data) == TYPE_DICTIONARY:
		var stringref := int((name_data as Dictionary).get("stringref", -1))
		if stringref >= 0:
			return "Indoor map (TLK %d)" % stringref
	return "Indoor map (%s)" % get_module_id()


func set_kit_library(library: RefCounted) -> void:
	_kit_library = library


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Module ID: %s" % get_module_id())
	lines.append("Rooms: %d" % get_room_count())
	lines.append("Embedded components: %d" % _embedded_by_id.size())
	if _kit_library != null and _kit_library.has_method("get_kit_count"):
		lines.append("Loaded kits: %d" % int(_kit_library.call("get_kit_count")))
	return lines


func get_room_count() -> int:
	var rooms: Variant = _data.get("rooms", [])
	return rooms.size() if typeof(rooms) == TYPE_ARRAY else 0


func get_room_dictionary(index: int) -> Dictionary:
	var rooms: Variant = _data.get("rooms", [])
	if typeof(rooms) != TYPE_ARRAY:
		return {}
	var room_list: Array = rooms
	if index < 0 or index >= room_list.size():
		return {}
	var room: Variant = room_list[index]
	return room as Dictionary if typeof(room) == TYPE_DICTIONARY else {}


func get_room_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var rooms: Variant = _data.get("rooms", [])
	if typeof(rooms) != TYPE_ARRAY:
		return records
	var room_list: Array = rooms
	for index in room_list.size():
		var room: Dictionary = room_list[index] if typeof(room_list[index]) == TYPE_DICTIONARY else {}
		if room.is_empty():
			continue
		var position := _read_position(room)
		var footprint := _room_footprint(room)
		records.append({
			"index": index,
			"label": _room_label(room),
			"x": position.x,
			"y": position.y,
			"z": position.z,
			"rotation": float(room.get("rotation", 0.0)),
			"flip_x": bool(room.get("flip_x", false)),
			"flip_y": bool(room.get("flip_y", false)),
			"half_width": footprint.x,
			"half_height": footprint.y,
		})
	return records


func find_room_record(index: int) -> Dictionary:
	for record in get_room_records():
		if int(record.get("index", -1)) == index:
			return record
	return {}


func get_layout_bounds(padding: float = 2.0) -> Rect2:
	var records := get_room_records()
	if records.is_empty():
		return Rect2(-padding, -padding, padding * 2.0, padding * 2.0)
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for record in records:
		var corners := _room_world_corners(record)
		for corner in corners:
			min_x = minf(min_x, corner.x)
			min_y = minf(min_y, corner.y)
			max_x = maxf(max_x, corner.x)
			max_y = maxf(max_y, corner.y)
	if min_x == max_x:
		min_x -= padding
		max_x += padding
	if min_y == max_y:
		min_y -= padding
		max_y += padding
	return Rect2(
		min_x - padding,
		min_y - padding,
		(max_x - min_x) + padding * 2.0,
		(max_y - min_y) + padding * 2.0
	)


func set_room_position(index: int, x: float, y: float) -> bool:
	var room := get_room_dictionary(index)
	if room.is_empty():
		return false
	var position := _read_position(room)
	position.x = x
	position.y = y
	_write_position(room, position)
	_commit_room(index, room)
	return true


func set_room_rotation(index: int, rotation: float) -> bool:
	var room := get_room_dictionary(index)
	if room.is_empty():
		return false
	room["rotation"] = rotation
	_commit_room(index, room)
	return true


func add_room_from_kit(
	kit_id: String,
	component_id: String,
	position: Vector3,
	rotation: float = 0.0
) -> int:
	if kit_id.is_empty() or component_id.is_empty():
		return -1
	if kit_id != KotorIndoorMapIO.EMBEDDED_KIT_ID:
		if _kit_library == null or not _kit_library.has_method("has_component"):
			return -1
		if not bool(_kit_library.call("has_component", kit_id, component_id)):
			return -1
	elif not _embedded_by_id.has(component_id):
		return -1

	var rooms: Variant = _data.get("rooms", [])
	if typeof(rooms) != TYPE_ARRAY:
		rooms = []
	var room_list: Array = rooms
	var room := {
		"position": [position.x, position.y, position.z],
		"rotation": rotation,
		"flip_x": false,
		"flip_y": false,
		"kit": kit_id,
		"component": component_id,
	}
	room_list.append(room)
	_data["rooms"] = room_list
	_emit_changed()
	return room_list.size() - 1


func remove_room(index: int) -> bool:
	var rooms: Variant = _data.get("rooms", [])
	if typeof(rooms) != TYPE_ARRAY:
		return false
	var room_list: Array = rooms
	if index < 0 or index >= room_list.size():
		return false
	room_list.remove_at(index)
	_data["rooms"] = room_list
	_emit_changed()
	return true


func _set_data(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_rebuild_embedded_index()
	_emit_changed()


func _rebuild_embedded_index() -> void:
	_embedded_by_id.clear()
	var embedded: Variant = _data.get("embedded_components", [])
	if typeof(embedded) != TYPE_ARRAY:
		return
	for raw_component in embedded:
		if typeof(raw_component) != TYPE_DICTIONARY:
			continue
		var component: Dictionary = raw_component
		var component_id := str(component.get("id", ""))
		if component_id.is_empty():
			continue
		_embedded_by_id[component_id] = component


func _commit_room(index: int, room: Dictionary) -> void:
	var rooms: Variant = _data.get("rooms", [])
	if typeof(rooms) != TYPE_ARRAY:
		return
	var room_list: Array = rooms
	if index < 0 or index >= room_list.size():
		return
	room_list[index] = room
	_data["rooms"] = room_list
	_emit_changed()


func _emit_changed() -> void:
	changed.emit()


func _read_position(room: Dictionary) -> Vector3:
	var raw: Variant = room.get("position", [0.0, 0.0, 0.0])
	if typeof(raw) != TYPE_ARRAY:
		return Vector3.ZERO
	var values: Array = raw
	return Vector3(
		float(values[0]) if values.size() > 0 else 0.0,
		float(values[1]) if values.size() > 1 else 0.0,
		float(values[2]) if values.size() > 2 else 0.0
	)


func _write_position(room: Dictionary, position: Vector3) -> void:
	room["position"] = [position.x, position.y, position.z]


func _room_label(room: Dictionary) -> String:
	var kit_id := str(room.get("kit", ""))
	var component_id := str(room.get("component", ""))
	if kit_id.is_empty() and component_id.is_empty():
		return "Room"
	if kit_id == KotorIndoorMapIO.EMBEDDED_KIT_ID:
		var embedded: Dictionary = _embedded_by_id.get(component_id, {})
		var embedded_name := str(embedded.get("name", component_id))
		return "embedded/%s" % embedded_name
	return "%s/%s" % [kit_id, component_id]


func _room_footprint(room: Dictionary) -> Vector2:
	var override_bwm := _decode_room_walkmesh_override(room)
	if not override_bwm.is_empty():
		return _footprint_from_bwm(override_bwm)
	var component_id := str(room.get("component", ""))
	if str(room.get("kit", "")) == KotorIndoorMapIO.EMBEDDED_KIT_ID:
		var embedded: Dictionary = _embedded_by_id.get(component_id, {})
		var embedded_bwm := _decode_base64_bytes(str(embedded.get("bwm", "")))
		if not embedded_bwm.is_empty():
			return _footprint_from_bwm(BWMParser.parse_bytes(embedded_bwm))
	var kit_id := str(room.get("kit", ""))
	if not kit_id.is_empty() and _kit_library != null and _kit_library.has_method("get_component_footprint"):
		return _kit_library.call(
			"get_component_footprint",
			kit_id,
			component_id
		) as Vector2
	return Vector2(DEFAULT_HALF_EXTENT, DEFAULT_HALF_EXTENT)


func _decode_room_walkmesh_override(room: Dictionary) -> Dictionary:
	var encoded := str(room.get("walkmesh_override", ""))
	if encoded.is_empty():
		return {}
	var bytes := _decode_base64_bytes(encoded)
	if bytes.is_empty():
		return {}
	return BWMParser.parse_bytes(bytes)


func _decode_base64_bytes(encoded: String) -> PackedByteArray:
	if encoded.is_empty():
		return PackedByteArray()
	return Marshalls.base64_to_raw(encoded.strip_edges())


func _footprint_from_bwm(parsed: Dictionary) -> Vector2:
	var bounds := BWMParser.compute_bounds(parsed)
	if bounds.size == Vector3.ZERO:
		return Vector2(DEFAULT_HALF_EXTENT, DEFAULT_HALF_EXTENT)
	var half_x := maxf(bounds.size.x * 0.5, 0.5)
	var half_y := maxf(bounds.size.z * 0.5, 0.5)
	return Vector2(half_x, half_y)


static func _room_world_corners(record: Dictionary) -> PackedVector2Array:
	var center := Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))
	var half_width := float(record.get("half_width", DEFAULT_HALF_EXTENT))
	var half_height := float(record.get("half_height", DEFAULT_HALF_EXTENT))
	var rotation := float(record.get("rotation", 0.0))
	var flip_x := bool(record.get("flip_x", false))
	var flip_y := bool(record.get("flip_y", false))
	var local_corners := PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height),
	])
	var world_corners := PackedVector2Array()
	for corner in local_corners:
		var scaled := corner
		if flip_x:
			scaled.x = -scaled.x
		if flip_y:
			scaled.y = -scaled.y
		var rotated := scaled.rotated(-rotation)
		world_corners.append(center + rotated)
	return world_corners
