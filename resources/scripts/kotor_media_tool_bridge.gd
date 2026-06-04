## PyKotor CLI bridge for TPC texture export and WAV sound conversion.
class_name KotorMediaToolBridge

const KotorIndoorModExporter := preload("../indoor/kotor_indoor_mod_exporter.gd")

enum Operation { TEXTURE_CONVERT, SOUND_CONVERT }


static func validate_preflight(config: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var operation := int(config.get("operation", Operation.TEXTURE_CONVERT))
	if operation < Operation.TEXTURE_CONVERT or operation > Operation.SOUND_CONVERT:
		errors.append("Unknown media tool operation.")

	var input_path := str(config.get("input_path", "")).strip_edges()
	if input_path.is_empty():
		errors.append("Media input path is required.")
	elif not FileAccess.file_exists(input_path):
		errors.append("Media input file does not exist: %s" % input_path)

	var output_path := str(config.get("output_path", "")).strip_edges()
	if output_path.is_empty() and not input_path.is_empty():
		match operation:
			Operation.TEXTURE_CONVERT:
				output_path = _default_output_path(input_path, "tga")
			Operation.SOUND_CONVERT:
				output_path = _default_output_path(input_path, "wav")
	elif not output_path.is_empty():
		var expected := _expected_extension(operation)
		if output_path.get_extension().to_lower() != expected:
			warnings.append(
				"Output extension is not .%s; PyKotor may still write the chosen path." % expected
			)

	if operation == Operation.TEXTURE_CONVERT and not input_path.is_empty():
		if input_path.get_extension().to_lower() != "tpc":
			warnings.append("Texture convert expects a .tpc source file.")
	if operation == Operation.SOUND_CONVERT and not input_path.is_empty():
		if input_path.get_extension().to_lower() != "wav":
			warnings.append("Sound convert expects a .wav source file.")

	var sound_type := str(config.get("sound_type", "SFX")).strip_edges().to_upper()
	if operation == Operation.SOUND_CONVERT and sound_type not in ["SFX", "VO"]:
		errors.append("Sound type must be SFX or VO.")

	var configured_cli := str(config.get("pykotor_cli_path", "")).strip_edges()
	var cli := KotorIndoorModExporter.resolve_cli(configured_cli)
	var executable := str(cli.get("executable", ""))
	if executable.is_empty():
		errors.append(
			"PyKotor CLI not found. Install PyKotor and set kotor_tools/pykotor_cli_path, "
			+ "or ensure pykotorcli is on PATH."
		)
	elif not configured_cli.is_empty() and not _cli_usable(executable):
		errors.append("PyKotor CLI not found at configured path: %s" % configured_cli)

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings, "output_path": output_path}


static func build_command(config: Dictionary) -> Dictionary:
	var working := config.duplicate(true)
	var inferred_output := str(validate_preflight(working).get("output_path", "")).strip_edges()
	if not inferred_output.is_empty() and str(working.get("output_path", "")).strip_edges().is_empty():
		working["output_path"] = inferred_output

	var preflight := validate_preflight(working)
	if not preflight.get("ok", false):
		return {
			"ok": false,
			"errors": preflight.get("errors", []),
			"warnings": preflight.get("warnings", []),
		}

	var operation := int(working.get("operation", Operation.TEXTURE_CONVERT))
	var cli := KotorIndoorModExporter.resolve_cli(str(working.get("pykotor_cli_path", "")))
	var input_path := str(working.get("input_path", "")).strip_edges()
	var output_path := str(working.get("output_path", preflight.get("output_path", ""))).strip_edges()

	var subcommand := _subcommand_name(operation)
	var args := PackedStringArray()
	args.append_array(cli.get("module_args", PackedStringArray()) as PackedStringArray)
	args.append(subcommand)
	args.append(input_path)
	args.append("--output")
	args.append(output_path)

	match operation:
		Operation.TEXTURE_CONVERT:
			var export_format := str(working.get("texture_format", "")).strip_edges()
			if not export_format.is_empty():
				args.append("--format")
				args.append(export_format)
			var txi_path := str(working.get("txi_path", "")).strip_edges()
			if not txi_path.is_empty():
				args.append("--txi")
				args.append(txi_path)
		Operation.SOUND_CONVERT:
			if bool(working.get("to_clean", true)):
				args.append("--to-clean")
			var sound_type := str(working.get("sound_type", "SFX")).strip_edges().to_upper()
			args.append("--type")
			args.append(sound_type)

	return {
		"ok": true,
		"executable": str(cli.get("executable", "")),
		"arguments": args,
		"warnings": preflight.get("warnings", []),
		"output_path": output_path,
	}


static func run_texture_convert(
		input_path: String,
		output_path: String,
		pykotor_cli_path: String = "",
		texture_format: String = "",
		txi_path: String = ""
) -> Dictionary:
	return run_tool({
		"operation": Operation.TEXTURE_CONVERT,
		"input_path": input_path,
		"output_path": output_path,
		"pykotor_cli_path": pykotor_cli_path,
		"texture_format": texture_format,
		"txi_path": txi_path,
	})


static func run_sound_convert(
		input_path: String,
		output_path: String,
		to_clean: bool = true,
		sound_type: String = "SFX",
		pykotor_cli_path: String = ""
) -> Dictionary:
	return run_tool({
		"operation": Operation.SOUND_CONVERT,
		"input_path": input_path,
		"output_path": output_path,
		"to_clean": to_clean,
		"sound_type": sound_type,
		"pykotor_cli_path": pykotor_cli_path,
	})


static func run_tool(config: Dictionary) -> Dictionary:
	var working := config.duplicate(true)
	if working.get("dry_run", false):
		return build_command(working)

	var built := build_command(working)
	if not built.get("ok", false):
		return {
			"ok": false,
			"message": _join_lines(built.get("errors", [])),
			"errors": built.get("errors", []),
		}

	var output: Array = []
	var exit_code := OS.execute(
		str(built.get("executable", "")),
		built.get("arguments", PackedStringArray()) as PackedStringArray,
		output,
		true
	)

	var stdout := ""
	var stderr := ""
	if output.size() >= 1:
		stdout = str(output[0])
	if output.size() >= 2:
		stderr = str(output[1])

	var output_path := str(built.get("output_path", ""))
	if exit_code != 0:
		var detail := stderr if not stderr.is_empty() else stdout
		if detail.is_empty():
			detail = "PyKotor CLI exited with code %d" % exit_code
		return {
			"ok": false,
			"message": detail.strip_edges(),
			"exit_code": exit_code,
			"stdout": stdout,
			"stderr": stderr,
			"output_path": output_path,
		}

	if not output_path.is_empty() and not FileAccess.file_exists(output_path):
		return {
			"ok": false,
			"message": "PyKotor reported success but output file was not created: %s" % output_path,
			"exit_code": exit_code,
			"stdout": stdout,
			"stderr": stderr,
			"output_path": output_path,
		}

	return {
		"ok": true,
		"message": "Wrote %s" % output_path.get_file(),
		"exit_code": exit_code,
		"stdout": stdout,
		"stderr": stderr,
		"output_path": output_path,
		"warnings": built.get("warnings", []),
	}


static func write_temp_bytes(
		bytes: PackedByteArray,
		resref: String,
		extension: String,
		cache_subdir: String = "kotor_tools_media"
) -> Dictionary:
	var cache_dir := OS.get_cache_dir().path_join(cache_subdir)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(cache_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(cache_dir):
		return {"ok": false, "message": "Failed to create temp media directory."}
	var safe_name := resref.strip_edges()
	if safe_name.is_empty():
		safe_name = "media_temp"
	var temp_path := cache_dir.path_join("%s_%d.%s" % [safe_name, Time.get_ticks_usec(), extension])
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Failed to write temp %s file." % extension}
	file.store_buffer(bytes)
	file.close()
	return {"ok": true, "path": temp_path}


static func _subcommand_name(operation: int) -> String:
	match operation:
		Operation.SOUND_CONVERT:
			return "sound-convert"
		_:
			return "texture-convert"


static func _expected_extension(operation: int) -> String:
	match operation:
		Operation.SOUND_CONVERT:
			return "wav"
		_:
			return "tga"


static func _default_output_path(input_path: String, extension: String) -> String:
	return input_path.get_basename() + "." + extension


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)


static func _cli_usable(command: String) -> bool:
	if command.is_empty():
		return false
	if command.contains("/") or command.contains("\\"):
		return FileAccess.file_exists(command) or DirAccess.dir_exists_absolute(command)
	var output: Array = []
	var exit_code := OS.execute("which", PackedStringArray([command]), output, true)
	return exit_code == 0
