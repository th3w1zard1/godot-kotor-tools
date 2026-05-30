@tool
extends SceneTree

const KotorScriptToolBridge := preload("../../resources/scripts/kotor_script_tool_bridge.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_assemble_command()
	_test_decompile_command()
	_test_disassemble_command()
	_test_preflight_missing_cli()
	_test_include_directories()
	print("✓ Script tool bridge tests passed")
	quit()


func _test_assemble_command() -> void:
	var nss_path := "/tmp/kotor_script_tool_%d.nss" % Time.get_ticks_usec()
	var ncs_path := nss_path.get_basename() + ".ncs"
	var include_dir := "/tmp/kotor_script_includes_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(include_dir)
	_write_empty_file(nss_path)
	var config := {
		"operation": KotorScriptToolBridge.Operation.ASSEMBLE,
		"input_path": nss_path,
		"output_path": ncs_path,
		"game_path": "/games/swkotor2",
		"pykotor_cli_path": "/bin/true",
		"include_directories": [include_dir],
	}
	var built := KotorScriptToolBridge.build_command(config)
	assert(built.get("ok", false))
	assert(str(built.get("executable", "")) == "/bin/true")
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("assemble"))
	assert(args.has(nss_path))
	assert(args.has("--output"))
	assert(args.has(ncs_path))
	assert(args.has("--include"))
	assert(args.has(include_dir))
	assert(args.has("--tsl"))

	var dry_config := config.duplicate(true)
	dry_config["dry_run"] = true
	var dry := KotorScriptToolBridge.run_tool(dry_config)
	assert(dry.get("ok", false))
	DirAccess.remove_absolute(nss_path)
	DirAccess.remove_absolute(include_dir)
	print("✓ Script tool assemble command passed")


func _test_decompile_command() -> void:
	var ncs_path := "/tmp/kotor_script_tool_%d.ncs" % Time.get_ticks_usec()
	var nss_path := ncs_path.get_basename() + ".nss"
	_write_empty_file(ncs_path)
	var config := {
		"operation": KotorScriptToolBridge.Operation.DECOMPILE,
		"input_path": ncs_path,
		"output_path": nss_path,
		"game_path": "/games/swkotor",
		"pykotor_cli_path": "/bin/true",
	}
	var built := KotorScriptToolBridge.build_command(config)
	assert(built.get("ok", false))
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("decompile"))
	assert(args.has(ncs_path))
	assert(not args.has("--tsl"))
	DirAccess.remove_absolute(ncs_path)
	print("✓ Script tool decompile command passed")


func _test_disassemble_command() -> void:
	var ncs_path := "/tmp/kotor_script_tool_%d.ncs" % Time.get_ticks_usec()
	var txt_path := ncs_path.get_basename() + ".txt"
	_write_empty_file(ncs_path)
	var config := {
		"operation": KotorScriptToolBridge.Operation.DISASSEMBLE,
		"input_path": ncs_path,
		"output_path": txt_path,
		"game_path": "/games/swkotor2",
		"pykotor_cli_path": "/bin/true",
		"compact": true,
	}
	var built := KotorScriptToolBridge.build_command(config)
	assert(built.get("ok", false))
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("disassemble"))
	assert(args.has("--game"))
	assert(args.has("k2"))
	assert(args.has("--compact"))
	DirAccess.remove_absolute(ncs_path)
	print("✓ Script tool disassemble command passed")


func _write_empty_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("")
	file.close()


func _test_preflight_missing_cli() -> void:
	var config := {
		"operation": KotorScriptToolBridge.Operation.ASSEMBLE,
		"input_path": "/bin/true",
		"output_path": "/tmp/out.ncs",
		"pykotor_cli_path": "/nonexistent/pykotorcli",
	}
	var preflight := KotorScriptToolBridge.validate_preflight(config)
	assert(not preflight.get("ok", true))
	print("✓ Script tool preflight validation passed")


func _test_include_directories() -> void:
	var root := "/tmp/kotor_script_tool_bridge_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root.path_join("scripts"))
	DirAccess.make_dir_recursive_absolute(root.path_join("Override"))
	var includes := KotorScriptToolBridge.collect_include_directories({
		"input_path": root.path_join("scripts/foo.nss"),
		"game_path": root,
	})
	assert(includes.has(root.path_join("scripts")))
	assert(includes.has(root.path_join("Override")))
	DirAccess.remove_absolute(root.path_join("Override"))
	DirAccess.remove_absolute(root.path_join("scripts"))
	DirAccess.remove_absolute(root)
	print("✓ Script tool include directories passed")
