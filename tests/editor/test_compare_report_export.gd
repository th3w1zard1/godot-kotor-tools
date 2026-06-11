@tool
extends SceneTree

const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


var _report_path := ""


func _initialize() -> void:
	_report_path = "/tmp/kotor_compare_report_export_%d.txt" % Time.get_ticks_usec()
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_rejects_empty_path()
	_test_rejects_empty_text()
	_test_writes_utf8_report()
	_test_export_compare_result_uses_details()
	_test_format_compare_result_text()
	_cleanup()
	print("✓ Compare report export tests passed")
	quit()


func _test_rejects_empty_path() -> void:
	var result := KotorModdingPipeline.export_text_report_to_path("", "report body")
	assert(not result.get("ok", true))
	print("✓ Compare report export empty path passed")


func _test_rejects_empty_text() -> void:
	var result := KotorModdingPipeline.export_text_report_to_path(_report_path, "   ")
	assert(not result.get("ok", true))
	print("✓ Compare report export empty text passed")


func _test_writes_utf8_report() -> void:
	var body := "Override compare scan (1 resources)\n  Different: 1"
	var result := KotorModdingPipeline.export_text_report_to_path(_report_path, body)
	assert(result.get("ok", false))
	assert(FileAccess.file_exists(_report_path))
	var file := FileAccess.open(_report_path, FileAccess.READ)
	assert(file != null)
	assert(file.get_as_text() == body)
	file.close()
	print("✓ Compare report export write passed")


func _test_export_compare_result_uses_details() -> void:
	var compare_result := {
		"message": "Override differs from core for demo.2da",
		"details": "2DA differs: +1 row(s).",
		"core_entry": {"location": "chitin.key::demo.2da"},
		"override_entry": {"location": "override/demo.2da"},
	}
	var result := KotorModdingPipeline.export_compare_result_to_path(_report_path, compare_result)
	assert(result.get("ok", false))
	var file := FileAccess.open(_report_path, FileAccess.READ)
	assert(file != null)
	var text := file.get_as_text()
	file.close()
	assert(text.find("demo.2da") >= 0)
	assert(text.find("2DA differs") >= 0)
	assert(text.find("override/demo.2da") >= 0)
	print("✓ Compare report export compare result passed")


func _test_format_compare_result_text() -> void:
	var formatted := KotorModdingPipeline.format_compare_result_text({
		"message": "Override scan complete",
		"details": "Override compare scan (0 resources)",
	})
	assert(formatted.find("Override scan complete") >= 0)
	assert(formatted.find("Override compare scan") >= 0)
	print("✓ Compare report export formatter passed")


func _cleanup() -> void:
	if FileAccess.file_exists(_report_path):
		DirAccess.remove_absolute(_report_path)
