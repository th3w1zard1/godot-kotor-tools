@tool
extends SceneTree

const SSFParser := preload("../../formats/ssf_parser.gd")
const SSFWriter := preload("../../formats/ssf_writer.gd")
const SSFCompare := preload("../../formats/ssf_compare.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_slot_diff()
	_test_multiple_slot_diff()
	_test_invalid_bytes_fallback()
	_test_identical_no_report()
	_test_pipeline_wiring()
	print("✓ SSF compare tests passed")
	quit()


func _test_slot_diff() -> void:
	var base := _make_ssf_bytes({0: 100, 6: 200})
	var mod := _make_ssf_bytes({0: 101, 6: 200})
	var report := SSFCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("SSF differs") >= 0)
	assert(report.find("BATTLE_CRY_1") >= 0)
	assert(report.find("100 -> 101") >= 0)
	print("✓ SSF slot diff passed")


func _test_multiple_slot_diff() -> void:
	var base := _make_ssf_bytes({15: -1, 16: 500})
	var mod := _make_ssf_bytes({15: 42, 16: 501})
	var report := SSFCompare.build_difference_report(base, mod)
	assert(report.find("DEAD") >= 0)
	assert(report.find("(none) -> 42") >= 0)
	assert(report.find("CRITICAL_HIT") >= 0)
	print("✓ SSF multiple slot diff passed")


func _test_invalid_bytes_fallback() -> void:
	assert(SSFCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(8)
	assert(SSFCompare.build_difference_report(short, short).is_empty())
	print("✓ SSF invalid bytes fallback passed")


func _test_identical_no_report() -> void:
	var bytes := _make_ssf_bytes({0: 1, 3: 2})
	assert(SSFCompare.build_difference_report(bytes, bytes).is_empty())
	print("✓ SSF identical no report passed")


func _test_pipeline_wiring() -> void:
	var base := _make_ssf_bytes({0: 10})
	var mod := _make_ssf_bytes({0: 11})
	var report := KotorModdingPipeline._build_difference_report("ssf", base, mod)
	assert(not report.is_empty())
	assert(report.find("SSF differs") >= 0)
	print("✓ SSF pipeline wiring passed")


func _make_ssf_bytes(slot_values: Dictionary) -> PackedByteArray:
	var strrefs: Array[int] = []
	strrefs.resize(SSFParser.SLOT_COUNT)
	for index in SSFParser.SLOT_COUNT:
		strrefs[index] = -1
	for slot_index in slot_values.keys():
		strrefs[int(slot_index)] = int(slot_values[slot_index])
	return SSFWriter.serialize_strrefs(strrefs)
