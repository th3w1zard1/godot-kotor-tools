@tool
extends SceneTree

const BatchDirectoryScanner := preload("../../formats/batch_directory_scanner.gd")

var _test_root := ""


func _initialize() -> void:
	_test_root = ProjectSettings.globalize_path("user://batch_directory_scanner_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_test_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_flat_scan()
	_test_recursive_scan()
	_test_recursive_ignores_unsupported_extensions()
	_cleanup()
	print("✓ Batch directory scanner tests passed")
	quit()


func _test_flat_scan() -> void:
	var root := _test_root.path_join("flat")
	DirAccess.make_dir_recursive_absolute(root.path_join("ignored"))
	_write_png(root.path_join("top.png"), 4, 4)
	_write_png(root.path_join("ignored").path_join("nested.png"), 4, 4)

	var paths := BatchDirectoryScanner.list_files(root, PackedStringArray(["png"]), false)
	assert(paths.size() == 1)
	assert(paths[0].ends_with("top.png"))
	print("✓ Batch directory scanner flat scan passed")


func _test_recursive_scan() -> void:
	var root := _test_root.path_join("recursive")
	var nested := root.path_join("nested").path_join("deep")
	DirAccess.make_dir_recursive_absolute(nested)
	_write_png(root.path_join("root.png"), 4, 4)
	_write_png(nested.path_join("deep.png"), 4, 4)

	var paths := BatchDirectoryScanner.list_files(root, PackedStringArray(["png"]), true)
	assert(paths.size() == 2)
	assert(paths[0].ends_with("deep.png"))
	assert(paths[1].ends_with("root.png"))
	print("✓ Batch directory scanner recursive scan passed")


func _test_recursive_ignores_unsupported_extensions() -> void:
	var root := _test_root.path_join("filtered")
	DirAccess.make_dir_recursive_absolute(root.path_join("child"))
	_write_png(root.path_join("keep.png"), 4, 4)
	_write_file(root.path_join("child").path_join("skip.txt"), "nope".to_utf8_buffer())

	var paths := BatchDirectoryScanner.list_files(root, PackedStringArray(["png"]), true)
	assert(paths.size() == 1)
	assert(paths[0].ends_with("keep.png"))
	print("✓ Batch directory scanner extension filter passed")


func _write_png(path: String, width: int, height: int) -> void:
	var parent := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent):
		DirAccess.make_dir_recursive_absolute(parent)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.8, 1.0))
	assert(image.save_png(path) == OK)


func _write_file(path: String, bytes: PackedByteArray) -> void:
	var parent := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent):
		DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(_test_root):
		_remove_dir_recursive(_test_root)


func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry == "." or entry == "..":
			continue
		var full := path.path_join(entry)
		if dir.current_is_dir():
			_remove_dir_recursive(full)
		elif FileAccess.file_exists(full):
			DirAccess.remove_absolute(full)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
