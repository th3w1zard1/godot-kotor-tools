@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const BWMWriter := preload("../../formats/bwm_writer.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_parse_minimal_triangle()
	_test_walkable_materials()
	_test_compute_bounds()
	_test_invalid_header()
	_test_toggle_face_walkable()
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


func _test_toggle_face_walkable() -> void:
	var bytes := _build_minimal_wok(
		[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[0, 1, 2],
		[BWMParser.DEFAULT_WALKABLE_MATERIAL]
	)
	var parsed := BWMParser.parse_bytes(bytes)
	assert(int(parsed.get("face_count", 0)) == 1)
	assert(BWMParser.get_face_material(parsed, 0) == BWMParser.DEFAULT_WALKABLE_MATERIAL)
	BWMParser.set_face_material(parsed, 0, BWMParser.DEFAULT_UNWALKABLE_MATERIAL)
	assert(BWMParser.get_face_material(parsed, 0) == BWMParser.DEFAULT_UNWALKABLE_MATERIAL)
	BWMParser.toggle_face_walkable(parsed, 0)
	assert(BWMParser.get_face_material(parsed, 0) == BWMParser.DEFAULT_WALKABLE_MATERIAL)
	print("✓ BWM face material toggle passed")


static func _build_minimal_wok(vertices: Array, face_indices: Array, materials: Array) -> PackedByteArray:
	return BWMWriter.build_minimal(vertices, face_indices, materials)
