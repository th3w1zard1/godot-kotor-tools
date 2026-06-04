## PyKotor CLI bridge for NSS assemble / NCS decompile / disassemble.
class_name KotorScriptToolBridge

const KotorIndoorModExporter := preload("../indoor/kotor_indoor_mod_exporter.gd")

enum Operation { ASSEMBLE, DECOMPILE, DISASSEMBLE }


static func validate_preflight(config: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var operation := int(config.get("operation", Operation.ASSEMBLE))
	if operation < Operation.ASSEMBLE or operation > Operation.DISASSEMBLE:
		errors.append("Unknown script tool operation.")

	var input_path := str(config.get("input_path", "")).strip_edges()
	if input_path.is_empty():
		errors.append("Script input path is required.")
	elif not FileAccess.file_exists(input_path):
		errors.append("Script input file does not exist: %s" % input_path)

	var output_path := str(config.get("output_path", "")).strip_edges()
	if output_path.is_empty():
		match operation:
			Operation.ASSEMBLE:
				if not input_path.is_empty():
					output_path = _default_output_path(input_path, "ncs")
				else:
					errors.append("Output .ncs path is required.")
			Operation.DECOMPILE:
				if not input_path.is_empty():
					output_path = _default_output_path(input_path, "nss")
				else:
					errors.append("Output .nss path is required.")
			Operation.DISASSEMBLE:
				if not input_path.is_empty():
					output_path = _default_output_path(input_path, "txt")
				else:
					errors.append("Output disassembly path is required.")
	else:
		var expected := _expected_extension(operation)
		if output_path.get_extension().to_lower() != expected:
			warnings.append("Output extension is not .%s; PyKotor may still write the chosen path." % expected)

	if operation == Operation.ASSEMBLE and not input_path.is_empty():
		if input_path.get_extension().to_lower() != "nss":
			warnings.append("Assemble expects an .nss source file.")

	if operation in [Operation.DECOMPILE, Operation.DISASSEMBLE] and not input_path.is_empty():
		if input_path.get_extension().to_lower() != "ncs":
			warnings.append("Decompile/disassemble expects an .ncs bytecode file.")

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

	var operation := int(working.get("operation", Operation.ASSEMBLE))
	var cli := KotorIndoorModExporter.resolve_cli(str(working.get("pykotor_cli_path", "")))
	var input_path := str(working.get("input_path", "")).strip_edges()
	var output_path := str(working.get("output_path", preflight.get("output_path", ""))).strip_edges()
	var game_path := str(working.get("game_path", "")).strip_edges()
	var game := str(working.get("game", "")).strip_edges()
	if game.is_empty() and not game_path.is_empty():
		game = KotorIndoorModExporter.infer_game_from_path(game_path)

	var subcommand := _subcommand_name(operation)
	var args := PackedStringArray()
	args.append_array(cli.get("module_args", PackedStringArray()) as PackedStringArray)
	args.append(subcommand)
	args.append(input_path)
	args.append("--output")
	args.append(output_path)

	match operation:
		Operation.ASSEMBLE:
			for include_dir in collect_include_directories(working):
				args.append("--include")
				args.append(include_dir)
			if game == "k2":
				args.append("--tsl")
			if bool(working.get("debug", false)):
				args.append("--debug")
		Operation.DECOMPILE:
			if game == "k2":
				args.append("--tsl")
		Operation.DISASSEMBLE:
			if not game.is_empty():
				args.append("--game")
				args.append(game)

	if operation == Operation.DISASSEMBLE and bool(working.get("compact", false)):
		args.append("--compact")

	return {
		"ok": true,
		"executable": str(cli.get("executable", "")),
		"arguments": args,
		"warnings": preflight.get("warnings", []),
		"output_path": output_path,
	}


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


static func collect_include_directories(config: Dictionary) -> PackedStringArray:
	var includes := PackedStringArray()
	var seen := {}

	var input_path := str(config.get("input_path", "")).strip_edges()
	if input_path.is_absolute_path():
		_add_include_dir(includes, seen, input_path.get_base_dir())

	var extra: Variant = config.get("include_directories", [])
	if typeof(extra) == TYPE_ARRAY:
		for entry in extra as Array:
			_add_include_dir(includes, seen, str(entry).strip_edges())

	var game_path := str(config.get("game_path", "")).strip_edges()
	if not game_path.is_empty():
		_add_include_dir(includes, seen, game_path.path_join("Override"))
		_add_include_dir(includes, seen, game_path.path_join("override"))
		_add_include_dir(includes, seen, game_path.path_join("data").path_join("scripts"))

	return includes


static func write_temp_nss(source_text: String, resref: String = "compile_temp") -> Dictionary:
	var cache_dir := OS.get_cache_dir().path_join("kotor_tools_script_tools")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(cache_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(cache_dir):
		return {"ok": false, "message": "Failed to create temp script directory."}
	var safe_name := resref.strip_edges()
	if safe_name.is_empty():
		safe_name = "compile_temp"
	var temp_path := cache_dir.path_join("%s_%d.nss" % [safe_name, Time.get_ticks_usec()])
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Failed to write temp NSS file."}
	file.store_string(source_text)
	file.close()
	return {"ok": true, "path": temp_path}


static func write_temp_ncs(bytes: PackedByteArray, resref: String = "decompile_temp") -> Dictionary:
	var cache_dir := OS.get_cache_dir().path_join("kotor_tools_script_tools")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(cache_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(cache_dir):
		return {"ok": false, "message": "Failed to create temp script directory."}
	var safe_name := resref.strip_edges()
	if safe_name.is_empty():
		safe_name = "decompile_temp"
	var temp_path := cache_dir.path_join("%s_%d.ncs" % [safe_name, Time.get_ticks_usec()])
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Failed to write temp NCS file."}
	file.store_buffer(bytes)
	file.close()
	return {"ok": true, "path": temp_path}


static func _subcommand_name(operation: int) -> String:
	match operation:
		Operation.DECOMPILE:
			return "decompile"
		Operation.DISASSEMBLE:
			return "disassemble"
		_:
			return "assemble"


static func _expected_extension(operation: int) -> String:
	match operation:
		Operation.DECOMPILE:
			return "nss"
		Operation.DISASSEMBLE:
			return "txt"
		_:
			return "ncs"


static func _default_output_path(input_path: String, extension: String) -> String:
	return input_path.get_basename() + "." + extension


static func _add_include_dir(includes: PackedStringArray, seen: Dictionary, path: String) -> void:
	if path.is_empty() or seen.has(path):
		return
	if not DirAccess.dir_exists_absolute(path):
		return
	seen[path] = true
	includes.append(path)


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
