@tool
extends SceneTree

const MDLParser := preload("../../formats/mdl_parser.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_parse_minimal_triangle()
	_test_compute_bounds()
	_test_invalid_header()
	print("✓ MDL parser tests passed")
	quit()


func _test_parse_minimal_triangle() -> void:
	var mdl_bytes := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2]
	)
	var parsed := MDLParser.parse_bytes(mdl_bytes)
	assert(not parsed.is_empty())
	assert(parsed.get("vertex_count", 0) == 3)
	assert(parsed.get("face_count", 0) == 1)
	var faces: Array = parsed.get("faces", [])
	assert(faces.size() == 1)
	assert(int(faces[0].get("i1", -1)) == 0)
	assert(int(faces[0].get("i2", -1)) == 1)
	assert(int(faces[0].get("i3", -1)) == 2)
	print("✓ MDL minimal triangle parse passed")


func _test_compute_bounds() -> void:
	var mdl_bytes := _build_minimal_mdl(
		[Vector3(1.0, 2.0, 3.0), Vector3(5.0, 2.0, 3.0), Vector3(1.0, 8.0, 3.0)],
		[0, 1, 2]
	)
	var parsed := MDLParser.parse_bytes(mdl_bytes)
	var bounds := MDLParser.compute_bounds(parsed)
	assert(bounds.size.x > 0.0)
	assert(bounds.size.y > 0.0)
	assert(is_equal_approx(bounds.position.x, 1.0))
	assert(is_equal_approx(bounds.position.y, 2.0))
	print("✓ MDL bounds computation passed")


func _test_invalid_header() -> void:
	assert(MDLParser.parse_bytes(PackedByteArray()).is_empty())
	assert(MDLParser.parse_bytes("not-a-model".to_utf8_buffer()).is_empty())
	print("✓ MDL invalid header rejection passed")


static func _build_minimal_mdl(vertices: Array, face_indices: Array) -> PackedByteArray:
	assert(vertices.size() == 3)
	assert(face_indices.size() == 3)

	const DATA_OFFSET := 12
	const MODEL_HEADER_SIZE := 196
	const NODE_HEADER_SIZE := 80
	const TRIMESH_HEADER_K1_SIZE := 332
	const FACE_SIZE := 32

	var node_offset := MODEL_HEADER_SIZE
	var trimesh_offset := node_offset + NODE_HEADER_SIZE
	var vertices_offset := trimesh_offset + TRIMESH_HEADER_K1_SIZE
	var faces_offset := vertices_offset + vertices.size() * 12
	var total_data_size := faces_offset + FACE_SIZE

	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.resize(DATA_OFFSET + total_data_size)

	stream.seek(DATA_OFFSET)
	stream.put_u32(MDLParser.K1_GEOMETRY_TOKEN0)
	stream.put_u32(MDLParser.K1_GEOMETRY_TOKEN1)
	_write_fixed_string(stream, "testmdl", 32)
	stream.put_u32(node_offset)
	stream.seek(DATA_OFFSET + MODEL_HEADER_SIZE)

	stream.seek(DATA_OFFSET + node_offset)
	stream.put_u16(MDLParser.FLAG_HEADER | MDLParser.FLAG_MESH)
	stream.put_u16(0)
	stream.put_u16(0)
	stream.put_u16(0)
	stream.put_u32(node_offset)
	stream.put_u32(0xFFFFFFFF)
	_write_vector3(stream, Vector3.ZERO)
	stream.put_float(1.0)
	stream.put_float(0.0)
	stream.put_float(0.0)
	stream.put_float(0.0)
	for _i in range(9):
		stream.put_u32(0)

	stream.seek(DATA_OFFSET + trimesh_offset)
	stream.put_u32(MDLParser.K1_TRIMESH_TOKEN0)
	stream.put_u32(MDLParser.K1_TRIMESH_TOKEN1)
	stream.put_u32(faces_offset)
	stream.put_u32(1)
	stream.put_u32(1)
	_write_vector3(stream, Vector3.ZERO)
	_write_vector3(stream, Vector3.ZERO)
	stream.put_float(0.0)
	_write_vector3(stream, Vector3.ZERO)
	_write_vector3(stream, Vector3.ZERO)
	_write_vector3(stream, Vector3.ZERO)
	stream.put_u32(0)
	stream.seek(stream.get_position() + 64)
	stream.seek(stream.get_position() + 24)
	stream.seek(stream.get_position() + 36)
	stream.seek(stream.get_position() + 12)
	stream.seek(stream.get_position() + 8)
	stream.put_u32(0)
	for _i in range(4):
		stream.put_float(0.0)
	stream.put_u32(0)
	stream.put_u32(0)
	stream.put_u32(0)
	stream.seek(stream.get_position() + 40)
	stream.put_u16(vertices.size())
	stream.put_u16(0)
	stream.seek(stream.get_position() + 6)
	stream.put_u16(0)
	stream.put_float(0.0)
	stream.put_u32(0)
	stream.put_u32(0)
	stream.put_u32(vertices_offset)

	stream.seek(DATA_OFFSET + vertices_offset)
	for vertex in vertices:
		_write_vector3(stream, vertex)

	stream.seek(DATA_OFFSET + faces_offset)
	_write_vector3(stream, Vector3(0.0, 1.0, 0.0))
	stream.put_float(0.0)
	stream.put_u32(0)
	stream.put_u16(0xFFFF)
	stream.put_u16(0xFFFF)
	stream.put_u16(0xFFFF)
	stream.put_u16(face_indices[0])
	stream.put_u16(face_indices[1])
	stream.put_u16(face_indices[2])

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
