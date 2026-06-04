@tool
extends SceneTree

const KotorGameFS := preload("../../gamefs/kotor_gamefs.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = "/tmp/kotor_override_batch_compare_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_empty_override_folder()
	_test_override_only_resource()
	_test_report_formatter_includes_diff_details()
	_cleanup()
	print("✓ Override batch compare tests passed")
	quit()


func _test_empty_override_folder() -> void:
	var gamefs := KotorGameFS.new()
	gamefs.index_install(_install_root)
	var result := KotorModdingPipeline.compare_all_overrides(gamefs)
	assert(result.get("ok", false))
	assert(str(result.get("status", "")) == "empty")
	var counts: Dictionary = result.get("counts", {})
	assert(int(counts.get("total", -1)) == 0)
	print("✓ Override batch compare empty folder passed")


func _test_override_only_resource() -> void:
	var gamefs := KotorGameFS.new()
	_write_text("override/testonly.2da", "2DA V2.0\n\nlabel\n0 only\n")
	gamefs.index_install(_install_root)
	var result := KotorModdingPipeline.compare_all_overrides(gamefs)
	assert(result.get("ok", false))
	var counts: Dictionary = result.get("counts", {})
	assert(int(counts.get("total", 0)) == 1)
	assert(int(counts.get("override_only", 0)) == 1)
	assert(int(counts.get("different", 0)) == 0)
	var report := str(result.get("details", ""))
	assert(report.find("testonly.2da") >= 0)
	assert(report.find("OVERRIDE_ONLY") >= 0)
	print("✓ Override batch compare override-only passed")


func _test_report_formatter_includes_diff_details() -> void:
	var counts := {"total": 1, "identical": 0, "different": 1, "override_only": 0}
	var entries := [
		{
			"label": "demo.2da",
			"status": "different",
			"message": "Override differs from core for demo.2da",
			"details": "2DA differs: +1 row(s).",
		},
	]
	var report := KotorModdingPipeline.build_override_compare_report(counts, entries)
	assert(report.find("demo.2da") >= 0)
	assert(report.find("DIFFERENT") >= 0)
	assert(report.find("2DA differs") >= 0)
	print("✓ Override batch compare report formatter passed")


func _write_text(relative_path: String, text: String) -> void:
	var path := _install_root.path_join(relative_path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(text)
	file.close()


func _cleanup() -> void:
	_remove_dir_recursive(_install_root)


func _remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var child := path.path_join(entry)
		if dir.current_is_dir():
			_remove_dir_recursive(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
