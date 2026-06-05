@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const BWMWriter := preload("../../formats/bwm_writer.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_write_minimal_triangle()
	_test_round_trip_preserves_geometry()
	_test_write_empty_returns_empty()
	print("✓ BWM writer tests passed")
	quit()


func _test_write_minimal_triangle() -> void:
	var bytes := BWMWriter.build_minimal(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	assert(not bytes.is_empty())
	var parsed := BWMParser.parse_bytes(bytes)
	assert(parsed.get("vertex_count", 0) == 3)
	assert(parsed.get("face_count", 0) == 1)
	print("✓ BWM writer minimal triangle passed")


func _test_round_trip_preserves_geometry() -> void:
	var original := BWMWriter.build_minimal(
		[Vector3(1.0, 2.0, 3.0), Vector3(5.0, 2.0, 3.0), Vector3(1.0, 8.0, 3.0)],
		[0, 1, 2],
		[2],
		Vector3(0.5, 0.0, -1.0)
	)
	var parsed := BWMParser.parse_bytes(original)
	var roundtrip := BWMParser.parse_bytes(BWMWriter.write_bytes(parsed))
	assert(roundtrip.get("vertex_count", 0) == 3)
	assert(roundtrip.get("face_count", 0) == 1)
	var faces: Array = roundtrip.get("faces", [])
	assert(int(faces[0].get("material", -1)) == 2)
	var position: Vector3 = roundtrip.get("position", Vector3.ZERO)
	assert(position.is_equal_approx(Vector3(0.5, 0.0, -1.0)))
	print("✓ BWM writer round trip passed")


func _test_write_empty_returns_empty() -> void:
	assert(BWMWriter.write_bytes({}).is_empty())
	assert(BWMWriter.build_minimal([], [], []).is_empty())
	print("✓ BWM writer empty input passed")
