@tool
extends SceneTree

const KotorMediaToolBridge := preload("../../resources/scripts/kotor_media_tool_bridge.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_texture_convert_command()
	_test_sound_convert_command()
	_test_preflight_missing_cli()
	print("✓ Media tool bridge tests passed")
	quit()


func _test_texture_convert_command() -> void:
	var tpc_path := "/tmp/kotor_media_tool_%d.tpc" % Time.get_ticks_usec()
	var tga_path := tpc_path.get_basename() + ".tga"
	_write_empty_file(tpc_path)
	var config := {
		"operation": KotorMediaToolBridge.Operation.TEXTURE_CONVERT,
		"input_path": tpc_path,
		"output_path": tga_path,
		"pykotor_cli_path": "/bin/true",
	}
	var built := KotorMediaToolBridge.build_command(config)
	assert(built.get("ok", false))
	assert(str(built.get("executable", "")) == "/bin/true")
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("texture-convert"))
	assert(args.has(tpc_path))
	assert(args.has("--output"))
	assert(args.has(tga_path))
	DirAccess.remove_absolute(tpc_path)
	print("✓ Media texture-convert command passed")


func _test_sound_convert_command() -> void:
	var wav_path := "/tmp/kotor_media_tool_%d.wav" % Time.get_ticks_usec()
	var out_path := wav_path.get_basename() + "_clean.wav"
	_write_empty_file(wav_path)
	var config := {
		"operation": KotorMediaToolBridge.Operation.SOUND_CONVERT,
		"input_path": wav_path,
		"output_path": out_path,
		"to_clean": true,
		"sound_type": "VO",
		"pykotor_cli_path": "/bin/true",
	}
	var built := KotorMediaToolBridge.build_command(config)
	assert(built.get("ok", false))
	var args: PackedStringArray = built.get("arguments", PackedStringArray())
	assert(args.has("sound-convert"))
	assert(args.has("--to-clean"))
	assert(args.has("--type"))
	assert(args.has("VO"))
	DirAccess.remove_absolute(wav_path)
	print("✓ Media sound-convert command passed")


func _test_preflight_missing_cli() -> void:
	var config := {
		"operation": KotorMediaToolBridge.Operation.TEXTURE_CONVERT,
		"input_path": "/bin/true",
		"output_path": "/tmp/out.tga",
		"pykotor_cli_path": "/nonexistent/pykotorcli",
	}
	var preflight := KotorMediaToolBridge.validate_preflight(config)
	assert(not preflight.get("ok", true))
	print("✓ Media tool preflight validation passed")


func _write_empty_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("")
	file.close()
