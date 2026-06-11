@tool
extends SceneTree

const BWMWriter := preload("../../formats/bwm_writer.gd")
const BwmCompare := preload("../../formats/bwm_compare.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_vertex_count_diff()
	_test_walkable_face_diff()
	_test_identical_no_report()
	_test_invalid_bytes_fallback()
	_test_pipeline_wiring()
	print("✓ BWM compare tests passed")
	quit()


func _test_vertex_count_diff() -> void:
	var base := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var mod := _build_minimal_wok(
		[
			Vector3(0.0, 0.0, 0.0),
			Vector3(2.0, 0.0, 0.0),
			Vector3(0.0, 2.0, 0.0),
			Vector3(1.0, 1.0, 0.0),
		],
		[0, 1, 2],
		[1]
	)
	var report := BwmCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("WOK differs") >= 0)
	assert(report.find("vertices: 3 -> 4") >= 0)
	print("✓ BWM vertex count diff passed")


func _test_walkable_face_diff() -> void:
	var base := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var mod := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2],
		[0]
	)
	var report := BwmCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("walkable faces: 1 -> 0") >= 0)
	print("✓ BWM walkable face diff passed")


func _test_identical_no_report() -> void:
	var bytes := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	assert(BwmCompare.build_difference_report(bytes, bytes).is_empty())
	print("✓ BWM identical no report passed")


func _test_invalid_bytes_fallback() -> void:
	assert(BwmCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(32)
	assert(BwmCompare.build_difference_report(short, short).is_empty())
	print("✓ BWM invalid bytes fallback passed")


func _test_pipeline_wiring() -> void:
	var base := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var mod := _build_minimal_wok(
		[
			Vector3(0.0, 0.0, 0.0),
			Vector3(2.0, 0.0, 0.0),
			Vector3(0.0, 2.0, 0.0),
			Vector3(1.0, 1.0, 0.0),
		],
		[0, 1, 2],
		[1]
	)
	var report := KotorModdingPipeline._build_difference_report("wok", base, mod)
	assert(not report.is_empty())
	assert(report.find("WOK differs") >= 0)
	assert(report.find("vertices:") >= 0)
	print("✓ BWM pipeline wiring passed")


static func _build_minimal_wok(vertices: Array, face_indices: Array, materials: Array) -> PackedByteArray:
	return BWMWriter.build_minimal(vertices, face_indices, materials)
