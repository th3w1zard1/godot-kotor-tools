## KotOR BWM/WOK walkmesh binary parser (read-only, visualization-focused).
##
## Parses BWM V1.0 layout per PyKotor io_bwm legacy reader: header, vertices,
## face indices, and per-face surface materials. Skips AABB/adjacency/edge tables.
class_name BWMParser

const MAGIC := "BWM "
const VERSION := "V1.0"
const HEADER_SIZE := 136

## Surface material IDs treated as walkable in Odyssey (PyKotor SurfaceMaterial.walkable).
const DEFAULT_WALKABLE_MATERIAL := 1
const DEFAULT_UNWALKABLE_MATERIAL := 0

const WALKABLE_MATERIALS := {
	1: true,
	2: true,
	3: true,
	4: true,
	5: true,
	6: true,
	7: true,
	8: true,
	9: true,
	10: true,
	11: true,
	12: true,
	13: true,
	30: true,
}


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.size() < HEADER_SIZE:
		return {}
	var stream := StreamPeerBuffer.new()
	stream.data_array = data
	stream.big_endian = false

	var file_type := _read_fixed_string(stream, 4)
	var file_version := _read_fixed_string(stream, 4)
	if file_type != MAGIC or file_version != VERSION:
		return {}

	var walkmesh_type := int(stream.get_u32())
	var relative_hook1 := _read_vector3(stream)
	var relative_hook2 := _read_vector3(stream)
	var absolute_hook1 := _read_vector3(stream)
	var absolute_hook2 := _read_vector3(stream)
	var position := _read_vector3(stream)

	var vertices_count := int(stream.get_u32())
	var vertices_offset := int(stream.get_u32())
	var face_count := int(stream.get_u32())
	var indices_offset := int(stream.get_u32())
	var materials_offset := int(stream.get_u32())

	if vertices_count < 0 or face_count < 0:
		return {}
	if vertices_offset < 0 or vertices_offset >= data.size():
		return {}
	if indices_offset < 0 or indices_offset >= data.size():
		return {}
	if materials_offset < 0 or materials_offset >= data.size():
		return {}

	var vertices: Array[Vector3] = []
	vertices.resize(vertices_count)
	stream.seek(vertices_offset)
	for index in range(vertices_count):
		vertices[index] = _read_vector3(stream)

	var faces: Array[Dictionary] = []
	faces.resize(face_count)
	stream.seek(indices_offset)
	for face_index in range(face_count):
		var i1 := int(stream.get_u32())
		var i2 := int(stream.get_u32())
		var i3 := int(stream.get_u32())
		if i1 < 0 or i2 < 0 or i3 < 0:
			return {}
		if i1 >= vertices_count or i2 >= vertices_count or i3 >= vertices_count:
			return {}
		faces[face_index] = {
			"i1": i1,
			"i2": i2,
			"i3": i3,
			"material": 0,
		}

	stream.seek(materials_offset)
	for face_index in range(face_count):
		faces[face_index]["material"] = int(stream.get_u32())

	return {
		"file_type": file_type,
		"file_version": file_version,
		"walkmesh_type": walkmesh_type,
		"position": position,
		"relative_hook1": relative_hook1,
		"relative_hook2": relative_hook2,
		"absolute_hook1": absolute_hook1,
		"absolute_hook2": absolute_hook2,
		"vertices": vertices,
		"faces": faces,
		"vertex_count": vertices_count,
		"face_count": face_count,
	}


static func is_walkable_material(material_id: int) -> bool:
	return WALKABLE_MATERIALS.has(material_id)


static func get_face_material(parsed: Dictionary, face_index: int) -> int:
	var faces: Array = parsed.get("faces", [])
	if face_index < 0 or face_index >= faces.size():
		return -1
	var face: Variant = faces[face_index]
	if typeof(face) != TYPE_DICTIONARY:
		return -1
	return int((face as Dictionary).get("material", DEFAULT_UNWALKABLE_MATERIAL))


static func set_face_material(parsed: Dictionary, face_index: int, material_id: int) -> bool:
	if parsed.is_empty():
		return false
	var faces: Array = parsed.get("faces", [])
	if face_index < 0 or face_index >= faces.size():
		return false
	var face: Variant = faces[face_index]
	if typeof(face) != TYPE_DICTIONARY:
		return false
	var face_dict: Dictionary = face
	if int(face_dict.get("material", DEFAULT_UNWALKABLE_MATERIAL)) == material_id:
		return false
	face_dict["material"] = material_id
	faces[face_index] = face_dict
	parsed["faces"] = faces
	return true


static func toggle_face_walkable(parsed: Dictionary, face_index: int) -> Dictionary:
	var current := get_face_material(parsed, face_index)
	if current < 0:
		return {"ok": false}
	var target := (
		DEFAULT_UNWALKABLE_MATERIAL
		if is_walkable_material(current)
		else DEFAULT_WALKABLE_MATERIAL
	)
	if not set_face_material(parsed, face_index, target):
		return {"ok": false, "old_material": current, "new_material": current}
	return {"ok": true, "old_material": current, "new_material": target}


static func compute_bounds(parsed: Dictionary) -> AABB:
	if parsed.is_empty():
		return AABB()
	var vertices: Array = parsed.get("vertices", [])
	if vertices.is_empty():
		return AABB()
	var min_pos := Vector3(INF, INF, INF)
	var max_pos := Vector3(-INF, -INF, -INF)
	var offset: Vector3 = parsed.get("position", Vector3.ZERO)
	for raw_vertex in vertices:
		if typeof(raw_vertex) != TYPE_VECTOR3:
			continue
		var vertex: Vector3 = raw_vertex + offset
		min_pos = min_pos.min(vertex)
		max_pos = max_pos.max(vertex)
	if min_pos == Vector3(INF, INF, INF):
		return AABB()
	return AABB(min_pos, max_pos - min_pos)


static func _read_vector3(stream: StreamPeerBuffer) -> Vector3:
	return Vector3(stream.get_float(), stream.get_float(), stream.get_float())


static func _read_fixed_string(stream: StreamPeerBuffer, length: int) -> String:
	var bytes := PackedByteArray()
	bytes.resize(length)
	for index in range(length):
		bytes[index] = stream.get_u8()
	return bytes.get_string_from_ascii()
