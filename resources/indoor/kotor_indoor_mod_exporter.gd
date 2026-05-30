## Export `.indoor` layouts to `.mod` via PyKotor CLI (`indoor-build`).
class_name KotorIndoorModExporter

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")

const SUBCOMMAND := "indoor-build"
const DEFAULT_CLI_CANDIDATES := ["pykotorcli", "pykotor"]
const PYTHON_CANDIDATES := ["python3", "python"]


static func validate_preflight(config: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var document: KotorIndoorDocument = config.get("document")
	if document == null:
		errors.append("No indoor map is loaded.")
	elif document.get_room_count() <= 0:
		errors.append("Indoor map has no rooms; add at least one kit room before export.")

	var input_path := str(config.get("input_path", "")).strip_edges()
	if input_path.is_empty() and document != null and document.get_room_count() > 0:
		warnings.append("No saved .indoor path; export will write a temporary file for PyKotor.")

	var game_path := str(config.get("game_path", "")).strip_edges()
	if game_path.is_empty():
		errors.append("Configure a KotOR game install path in editor settings.")
	elif not DirAccess.dir_exists_absolute(game_path):
		errors.append("Game install path does not exist: %s" % game_path)

	var kits_path := str(config.get("kits_path", "")).strip_edges()
	if kits_path.is_empty():
		errors.append("Configure an indoor kits folder.")
	elif not DirAccess.dir_exists_absolute(kits_path):
		errors.append("Indoor kits folder does not exist: %s" % kits_path)

	var output_path := str(config.get("output_path", "")).strip_edges()
	if output_path.is_empty():
		errors.append("Choose an output .mod path.")
	elif not output_path.get_extension().to_lower() in ["mod", "erf", "rim", "sav"]:
		warnings.append("Output extension is not .mod; PyKotor may still write the chosen container.")

	var cli := resolve_cli(str(config.get("pykotor_cli_path", "")))
	if cli.get("executable", "").is_empty():
		errors.append(
			"PyKotor CLI not found. Install PyKotor and set kotor_tools/pykotor_cli_path, "
			+ "or ensure pykotorcli is on PATH."
		)

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func resolve_cli(configured_path: String) -> Dictionary:
	var configured := configured_path.strip_edges()
	if not configured.is_empty():
		if _looks_like_python_launcher(configured):
			return {
				"executable": configured,
				"module_args": PackedStringArray(["-m", "pykotor"]),
				"source": "configured_python",
			}
		return {"executable": configured, "module_args": PackedStringArray(), "source": "configured"}

	for candidate in DEFAULT_CLI_CANDIDATES:
		if _command_exists(candidate):
			return {
				"executable": candidate,
				"module_args": PackedStringArray(),
				"source": "path_%s" % candidate,
			}

	for py in PYTHON_CANDIDATES:
		if _command_exists(py):
			return {
				"executable": py,
				"module_args": PackedStringArray(["-m", "pykotor"]),
				"source": "path_%s_module" % py,
			}

	return {"executable": "", "module_args": PackedStringArray(), "source": "missing"}


static func build_command(config: Dictionary) -> Dictionary:
	var preflight := validate_preflight(config)
	if not preflight.get("ok", false):
		return {
			"ok": false,
			"errors": preflight.get("errors", []),
			"warnings": preflight.get("warnings", []),
		}

	var cli := resolve_cli(str(config.get("pykotor_cli_path", "")))
	var input_path := str(config.get("input_path", "")).strip_edges()
	var output_path := _ensure_mod_extension(str(config.get("output_path", "")).strip_edges())
	var game_path := str(config.get("game_path", "")).strip_edges()
	var kits_path := str(config.get("kits_path", "")).strip_edges()

	var args := PackedStringArray()
	args.append_array(cli.get("module_args", PackedStringArray()) as PackedStringArray)
	args.append(SUBCOMMAND)
	args.append("--input")
	args.append(input_path)
	args.append("--output")
	args.append(output_path)
	args.append("--path")
	args.append(game_path)
	args.append("--kits")
	args.append(kits_path)

	var module_filename := str(config.get("module_filename", "")).strip_edges()
	if module_filename.is_empty():
		var document: KotorIndoorDocument = config.get("document")
		if document != null:
			module_filename = document.get_module_id()
	if not module_filename.is_empty():
		args.append("--module-filename")
		args.append(module_filename)

	var game := str(config.get("game", "")).strip_edges()
	if game.is_empty():
		game = infer_game_from_path(game_path)
	if not game.is_empty():
		args.append("--game")
		args.append(game)

	return {
		"ok": true,
		"executable": str(cli.get("executable", "")),
		"arguments": args,
		"warnings": preflight.get("warnings", []),
	}


static func export_indoor_to_mod(config: Dictionary) -> Dictionary:
	var working := config.duplicate(true)
	if working.get("dry_run", false):
		return build_command(working)

	var document: KotorIndoorDocument = working.get("document")
	var input_path := str(working.get("input_path", "")).strip_edges()
	var wrote_temp := false
	if input_path.is_empty():
		if document == null:
			return {"ok": false, "message": "No indoor map is loaded."}
		var temp_result := _write_temp_indoor(document)
		if not temp_result.get("ok", false):
			return temp_result
		input_path = str(temp_result.get("path", ""))
		wrote_temp = true
		working["input_path"] = input_path

	var built := build_command(working)
	if not built.get("ok", false):
		if wrote_temp:
			DirAccess.remove_absolute(input_path)
		return {
			"ok": false,
			"message": _join_lines(built.get("errors", [])),
			"errors": built.get("errors", []),
		}

	var output_path := _ensure_mod_extension(str(working.get("output_path", "")).strip_edges())
	working["output_path"] = output_path
	built = build_command(working)
	if not built.get("ok", false):
		if wrote_temp:
			DirAccess.remove_absolute(input_path)
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

	if wrote_temp:
		DirAccess.remove_absolute(input_path)

	var stdout := ""
	var stderr := ""
	if output.size() >= 1:
		stdout = str(output[0])
	if output.size() >= 2:
		stderr = str(output[1])

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

	if not FileAccess.file_exists(output_path):
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
		"message": "Exported %s" % output_path.get_file(),
		"exit_code": exit_code,
		"stdout": stdout,
		"stderr": stderr,
		"output_path": output_path,
		"warnings": built.get("warnings", []),
	}


static func infer_game_from_path(game_path: String) -> String:
	var lower := game_path.to_lower().replace("\\", "/")
	if lower.contains("swkotor2") or lower.contains("kotor2") or lower.contains("/tsl"):
		return "k2"
	if lower.contains("swkotor") or lower.contains("kotor"):
		return "k1"
	return ""


static func _ensure_mod_extension(path: String) -> String:
	if path.get_extension().to_lower() == "mod":
		return path
	if path.get_extension().is_empty():
		return "%s.mod" % path
	return path.get_basename() + ".mod"


static func _write_temp_indoor(document: KotorIndoorDocument) -> Dictionary:
	var cache_dir := OS.get_cache_dir().path_join("kotor_tools_indoor_export")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(cache_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(cache_dir):
		return {"ok": false, "message": "Failed to create temp export directory."}
	var temp_path := cache_dir.path_join("export_%d.indoor" % Time.get_ticks_usec())
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Failed to write temp indoor file."}
	file.store_buffer(document.serialize_to_bytes())
	file.close()
	return {"ok": true, "path": temp_path}


static func _looks_like_python_launcher(path: String) -> bool:
	var base := path.get_file().to_lower()
	return base.begins_with("python") or path.ends_with("py")


static func _command_exists(command: String) -> bool:
	if command.is_empty():
		return false
	if command.contains("/") or command.contains("\\"):
		return FileAccess.file_exists(command) or DirAccess.dir_exists_absolute(command)
	var output: Array = []
	var exit_code := OS.execute("which", PackedStringArray([command]), output, true)
	return exit_code == 0


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)
