@tool
extends SceneTree

const HoloPatcherToolBridge := preload("../../resources/patch/holo_patcher_tool_bridge.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var fixture_root := _create_fixture_directories()
	_test_preflight_missing_paths(fixture_root)
	_test_preflight_missing_cli(fixture_root)
	_test_build_holopatcher_validate_command(fixture_root)
	_test_build_holopatcher_install_command(fixture_root)
	_test_build_holopatcher_module_command(fixture_root)
	_test_dry_run(fixture_root)
	_cleanup_fixture(fixture_root)
	print("✓ HoloPatcher tool bridge tests passed")
	quit()


func _test_preflight_missing_paths(fixture_root: String) -> void:
	var preflight := HoloPatcherToolBridge.validate_preflight({
		"game_dir": "",
		"tslpatchdata": fixture_root.path_join("tslpatchdata"),
		"holopatcher_cli_path": "/bin/true",
	})
	assert(not preflight.get("ok", true))
	print("✓ HoloPatcher bridge preflight missing paths passed")


func _test_preflight_missing_cli(fixture_root: String) -> void:
	var preflight := HoloPatcherToolBridge.validate_preflight({
		"game_dir": fixture_root,
		"tslpatchdata": fixture_root.path_join("tslpatchdata"),
		"holopatcher_cli_path": "/nonexistent/holopatcher",
	})
	assert(not preflight.get("ok", true))
	print("✓ HoloPatcher bridge preflight missing CLI passed")


func _test_build_holopatcher_validate_command(fixture_root: String) -> void:
	var tslpatchdata := fixture_root.path_join("tslpatchdata")
	var built := HoloPatcherToolBridge.build_command({
		"game_dir": fixture_root,
		"tslpatchdata": tslpatchdata,
		"mode": HoloPatcherToolBridge.MODE_VALIDATE,
		"holopatcher_cli_path": "/bin/true",
	})
	assert(built.get("ok", false))
	assert(str(built.get("executable", "")) == "/bin/true")
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has(fixture_root))
	assert(args.has(tslpatchdata))
	assert(args.has("--validate"))
	assert(args.has("--console"))
	print("✓ HoloPatcher bridge validate command passed")


func _test_build_holopatcher_install_command(fixture_root: String) -> void:
	var tslpatchdata := fixture_root.path_join("tslpatchdata")
	var built := HoloPatcherToolBridge.build_command({
		"game_dir": fixture_root,
		"tslpatchdata": tslpatchdata,
		"mode": HoloPatcherToolBridge.MODE_INSTALL,
		"holopatcher_cli_path": "/bin/true",
	})
	assert(built.get("ok", false))
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("--install"))
	print("✓ HoloPatcher bridge install command passed")


func _test_build_holopatcher_module_command(fixture_root: String) -> void:
	var tslpatchdata := fixture_root.path_join("tslpatchdata")
	var built := HoloPatcherToolBridge.build_command({
		"game_dir": fixture_root,
		"tslpatchdata": tslpatchdata,
		"mode": HoloPatcherToolBridge.MODE_VALIDATE,
		"holopatcher_cli_path": "python3",
	})
	assert(built.get("ok", false))
	assert(str(built.get("cli_kind", "")) == "holopatcher_module")
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("-m"))
	assert(args.has("holopatcher"))
	print("✓ HoloPatcher bridge module command passed")


func _test_dry_run(fixture_root: String) -> void:
	var result := HoloPatcherToolBridge.run_tool({
		"dry_run": true,
		"game_dir": fixture_root,
		"tslpatchdata": fixture_root.path_join("tslpatchdata"),
		"mode": HoloPatcherToolBridge.MODE_VALIDATE,
		"holopatcher_cli_path": "/bin/true",
	})
	assert(result.get("ok", false))
	assert(str(result.get("executable", "")) == "/bin/true")
	print("✓ HoloPatcher bridge dry run passed")


func _create_fixture_directories() -> String:
	var root: String = "/tmp/holo_patcher_tool_bridge_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root.path_join("tslpatchdata"))
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
