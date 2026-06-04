@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_parse_minimal_triangle()
	_test_walkable_materials()
	_test_compute_bounds()
	_test_invalid_header()
	print("✓ BWM parser tests passed")
	quit()


func _test_parse_minimal_triangle() -> void:
	var bytes := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var parsed := BWMParser.parse_bytes(bytes)
	assert(not parsed.is_empty())
	assert(parsed.get("vertex_count", 0) == 3)
	assert(parsed.get("face_count", 0) == 1)
	var faces: Array = parsed.get("faces", [])
	assert(faces.size() == 1)
	assert(int(faces[0].get("material", -1)) == 1)
	print("✓ BWM minimal triangle parse passed")


func _test_walkable_materials() -> void:
	assert(BWMParser.is_walkable_material(1))
	assert(BWMParser.is_walkable_material(30))
	assert(not BWMParser.is_walkable_material(0))
	assert(not BWMParser.is_walkable_material(14))
	print("✓ BWM walkable material IDs passed")


func _test_compute_bounds() -> void:
	var bytes := _build_minimal_wok(
		[Vector3(1.0, 2.0, 3.0), Vector3(5.0, 2.0, 3.0), Vector3(1.0, 8.0, 3.0)],
		[0, 1, 2],
		[2]
	)
	var parsed := BWMParser.parse_bytes(bytes)
	var bounds := BWMParser.compute_bounds(parsed)
	assert(bounds.size.x > 0.0)
	assert(bounds.size.y > 0.0)
	assert(is_equal_approx(bounds.position.x, 1.0))
	assert(is_equal_approx(bounds.position.y, 2.0))
	print("✓ BWM bounds computation passed")


func _test_invalid_header() -> void:
	assert(BWMParser.parse_bytes(PackedByteArray()).is_empty())
	assert(BWMParser.parse_bytes("not-a-walkmesh".to_utf8_buffer()).is_empty())
	print("✓ BWM invalid header rejection passed")


static func _build_minimal_wok(vertices: Array, face_indices: Array, materials: Array) -> PackedByteArray:
	var vertex_count := vertices.size()
	var face_count := materials.size()
	assert(face_indices.size() == face_count * 3)

	var vertices_offset := BWMParser.HEADER_SIZE
	var indices_offset := vertices_offset + vertex_count * 12
	var materials_offset := indices_offset + face_count * 12
	var total_size := materials_offset + face_count * 4

	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.resize(total_size)

	_write_fixed_string(stream, BWMParser.MAGIC, 4)
	_write_fixed_string(stream, BWMParser.VERSION, 4)
	stream.put_u32(0)
	for _i in range(5):
		_write_vector3(stream, Vector3.ZERO)
	stream.put_u32(vertex_count)
	stream.put_u32(vertices_offset)
	stream.put_u32(face_count)
	stream.put_u32(indices_offset)
	stream.put_u32(materials_offset)

	stream.seek(vertices_offset)
	for vertex in vertices:
		_write_vector3(stream, vertex)

	stream.seek(indices_offset)
	for index in face_indices:
		stream.put_u32(index)

	stream.seek(materials_offset)
	for material_id in materials:
		stream.put_u32(material_id)

	return stream.data_array


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
