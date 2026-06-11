@tool
extends SceneTree

const KotorDiffToolBridge := preload("../../resources/diff/kotor_diff_tool_bridge.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var fixture_root := _create_fixture_directories()
	_test_preflight_missing_paths(fixture_root)
	_test_preflight_missing_cli(fixture_root)
	_test_build_kotordiff_command(fixture_root)
	_test_build_pykotor_diff_command(fixture_root)
	_test_dry_run(fixture_root)
	_cleanup_fixture(fixture_root)
	print("✓ KotorDiff tool bridge tests passed")
	quit()


func _test_preflight_missing_paths(fixture_root: String) -> void:
	var preflight := KotorDiffToolBridge.validate_preflight({
		"path1": "",
		"path2": fixture_root,
		"kotordiff_cli_path": "/bin/true",
	})
	assert(not preflight.get("ok", true))
	print("✓ KotorDiff bridge preflight missing paths passed")


func _test_preflight_missing_cli(fixture_root: String) -> void:
	var preflight := KotorDiffToolBridge.validate_preflight({
		"path1": fixture_root,
		"path2": fixture_root.path_join("override"),
		"kotordiff_cli_path": "/nonexistent/kotordiff",
	})
	assert(not preflight.get("ok", true))
	print("✓ KotorDiff bridge preflight missing CLI passed")


func _test_build_kotordiff_command(fixture_root: String) -> void:
	var path2 := fixture_root.path_join("override")
	var output_log := fixture_root.path_join("diff.log")
	var built := KotorDiffToolBridge.build_command({
		"path1": fixture_root,
		"path2": path2,
		"output_log": output_log,
		"kotordiff_cli_path": "/bin/true",
	})
	assert(built.get("ok", false))
	assert(str(built.get("executable", "")) == "/bin/true")
	assert(str(built.get("cli_kind", "")) == "kotordiff")
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("--path1"))
	assert(args.has(fixture_root))
	assert(args.has("--path2"))
	assert(args.has(path2))
	assert(args.has("--output-log"))
	assert(args.has(output_log))
	print("✓ KotorDiff bridge kotordiff command passed")


func _test_build_pykotor_diff_command(fixture_root: String) -> void:
	var path2 := fixture_root.path_join("override")
	var built := KotorDiffToolBridge.build_command({
		"path1": fixture_root,
		"path2": path2,
		"output_log": fixture_root.path_join("pykotor-diff.log"),
		"pykotor_cli_path": "python3",
	})
	assert(built.get("ok", false))
	assert(str(built.get("cli_kind", "")) == "pykotor")
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("-m"))
	assert(args.has("pykotor"))
	assert(args.has("diff"))
	print("✓ KotorDiff bridge pykotor diff command passed")


func _test_dry_run(fixture_root: String) -> void:
	var result := KotorDiffToolBridge.run_tool({
		"dry_run": true,
		"path1": fixture_root,
		"path2": fixture_root.path_join("override"),
		"output_log": fixture_root.path_join("dry.log"),
		"kotordiff_cli_path": "/bin/true",
	})
	assert(result.get("ok", false))
	assert(str(result.get("executable", "")) == "/bin/true")
	print("✓ KotorDiff bridge dry run passed")


func _create_fixture_directories() -> String:
	var root: String = "/tmp/kotor_diff_tool_bridge_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root.path_join("override"))
	return root


func _cleanup_fixture(root: String) -> void:
	_remove_dir_recursive(root)


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
