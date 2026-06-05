## KotOR BWM/WOK walkmesh binary writer (round-trip with BWMParser).
class_name BWMWriter

const BWMParser := preload("bwm_parser.gd")


static func write_bytes(parsed: Dictionary) -> PackedByteArray:
	if parsed.is_empty():
		return PackedByteArray()

	var vertices: Array = parsed.get("vertices", [])
	var faces: Array = parsed.get("faces", [])
	if vertices.is_empty() or faces.is_empty():
		return PackedByteArray()

	var vertex_count := vertices.size()
	var face_count := faces.size()
	var vertices_offset := BWMParser.HEADER_SIZE
	var indices_offset := vertices_offset + vertex_count * 12
	var materials_offset := indices_offset + face_count * 12
	var total_size := materials_offset + face_count * 4

	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.resize(total_size)

	_write_fixed_string(stream, BWMParser.MAGIC, 4)
	_write_fixed_string(stream, BWMParser.VERSION, 4)
	stream.put_u32(int(parsed.get("walkmesh_type", 0)))
	_write_vector3(stream, parsed.get("relative_hook1", Vector3.ZERO))
	_write_vector3(stream, parsed.get("relative_hook2", Vector3.ZERO))
	_write_vector3(stream, parsed.get("absolute_hook1", Vector3.ZERO))
	_write_vector3(stream, parsed.get("absolute_hook2", Vector3.ZERO))
	_write_vector3(stream, parsed.get("position", Vector3.ZERO))
	stream.put_u32(vertex_count)
	stream.put_u32(vertices_offset)
	stream.put_u32(face_count)
	stream.put_u32(indices_offset)
	stream.put_u32(materials_offset)

	stream.seek(vertices_offset)
	for raw_vertex in vertices:
		if typeof(raw_vertex) != TYPE_VECTOR3:
			return PackedByteArray()
		_write_vector3(stream, raw_vertex)

	stream.seek(indices_offset)
	for raw_face in faces:
		if typeof(raw_face) != TYPE_DICTIONARY:
			return PackedByteArray()
		var face: Dictionary = raw_face
		stream.put_u32(int(face.get("i1", 0)))
		stream.put_u32(int(face.get("i2", 0)))
		stream.put_u32(int(face.get("i3", 0)))

	stream.seek(materials_offset)
	for raw_face in faces:
		if typeof(raw_face) != TYPE_DICTIONARY:
			return PackedByteArray()
		stream.put_u32(int((raw_face as Dictionary).get("material", 0)))

	return stream.data_array


static func build_minimal(
	vertices: Array,
	face_indices: Array,
	materials: Array,
	position: Vector3 = Vector3.ZERO
) -> PackedByteArray:
	var face_count := materials.size()
	if face_indices.size() != face_count * 3:
		return PackedByteArray()
	var faces: Array = []
	for index in range(face_count):
		faces.append({
			"i1": int(face_indices[index * 3]),
			"i2": int(face_indices[index * 3 + 1]),
			"i3": int(face_indices[index * 3 + 2]),
			"material": int(materials[index]),
		})
	return write_bytes({
		"vertices": vertices,
		"faces": faces,
		"position": position,
	})


static func _write_vector3(stream: StreamPeerBuffer, value: Vector3) -> void:
	stream.put_float(value.x)
	stream.put_float(value.y)
	stream.put_float(value.z)


static func _write_fixed_string(stream: StreamPeerBuffer, text: String, length: int) -> void:
	var bytes := text.to_ascii_buffer()
	for index in range(length):
		if index < bytes.size():
			stream.put_u8(bytes[index])
		else:
			stream.put_u8(0)
