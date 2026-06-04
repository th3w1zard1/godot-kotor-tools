@tool
extends SceneTree

const LIPParser := preload("../../formats/lip_parser.gd")
const LIPWriter := preload("../../formats/lip_writer.gd")
const LIPCompare := preload("../../formats/lip_compare.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_keyframe_shape_diff()
	_test_length_and_count_diff()
	_test_invalid_bytes_fallback()
	_test_identical_no_report()
	_test_pipeline_wiring()
	print("✓ LIP compare tests passed")
	quit()


func _test_keyframe_shape_diff() -> void:
	var base := _make_lip_bytes(2.0, [{"time": 0.0, "shape": 0}, {"time": 2.0, "shape": 0}])
	var mod := _make_lip_bytes(2.0, [{"time": 0.0, "shape": 1}, {"time": 2.0, "shape": 0}])
	var report := LIPCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("LIP differs") >= 0)
	assert(report.find("keyframe 0") >= 0)
	assert(report.find("NEUTRAL") >= 0)
	assert(report.find("EE") >= 0)
	print("✓ LIP keyframe shape diff passed")


func _test_length_and_count_diff() -> void:
	var base := _make_lip_bytes(1.0, [{"time": 0.0, "shape": 0}])
	var mod := _make_lip_bytes(2.5, [{"time": 0.0, "shape": 0}, {"time": 2.5, "shape": 3}])
	var report := LIPCompare.build_difference_report(base, mod)
	assert(report.find("length:") >= 0)
	assert(report.find("keyframe count: 1 -> 2") >= 0)
	print("✓ LIP length and count diff passed")


func _test_invalid_bytes_fallback() -> void:
	assert(LIPCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(8)
	assert(LIPCompare.build_difference_report(short, short).is_empty())
	print("✓ LIP invalid bytes fallback passed")


func _test_identical_no_report() -> void:
	var bytes := _make_lip_bytes(1.5, [{"time": 0.0, "shape": 2}, {"time": 1.5, "shape": 0}])
	assert(LIPCompare.build_difference_report(bytes, bytes).is_empty())
	print("✓ LIP identical no report passed")


func _test_pipeline_wiring() -> void:
	var base := _make_lip_bytes(1.0, [{"time": 0.0, "shape": 0}])
	var mod := _make_lip_bytes(1.0, [{"time": 0.0, "shape": 4}])
	var report := KotorModdingPipeline._build_difference_report("lip", base, mod)
	assert(not report.is_empty())
	assert(report.find("LIP differs") >= 0)
	print("✓ LIP pipeline wiring passed")


func _make_lip_bytes(length: float, keyframes: Array) -> PackedByteArray:
	return LIPWriter.serialize_keyframes(length, keyframes)
