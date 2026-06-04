## HoloPatcher CLI bridge for TSL patch validate/install from the editor.
class_name HoloPatcherToolBridge

const HOLOPATCHER_CANDIDATES := ["holopatcher"]
const PYTHON_CANDIDATES := ["python3", "python"]
const MODE_VALIDATE := "validate"
const MODE_INSTALL := "install"


static func validate_preflight(config: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var game_dir := str(config.get("game_dir", config.get("game_path", ""))).strip_edges()
	if game_dir.is_empty():
		errors.append("HoloPatcher game directory is required.")
	elif not DirAccess.dir_exists_absolute(game_dir):
		errors.append("HoloPatcher game directory does not exist: %s" % game_dir)

	var tslpatchdata := str(config.get("tslpatchdata", "")).strip_edges()
	if tslpatchdata.is_empty():
		errors.append("HoloPatcher tslpatchdata path is required.")
	elif not _path_exists(tslpatchdata):
		errors.append("HoloPatcher tslpatchdata path does not exist: %s" % tslpatchdata)

	var mode := _normalize_mode(str(config.get("mode", MODE_VALIDATE)))
	if mode.is_empty():
		errors.append("HoloPatcher mode must be validate or install.")

	var configured_cli := str(
		config.get("holopatcher_cli_path", config.get("pykotor_cli_path", ""))
	).strip_edges()
	var cli := resolve_cli(configured_cli)
	if str(cli.get("executable", "")).is_empty():
		errors.append(
			"HoloPatcher CLI not found. Install holopatcher and set kotor_tools/pykotor_cli_path, "
			+ "or ensure holopatcher is on PATH."
		)
	elif not configured_cli.is_empty() and not _cli_usable(str(cli.get("executable", ""))):
		errors.append("HoloPatcher CLI not found at configured path: %s" % configured_cli)

	if mode == MODE_INSTALL:
		warnings.append("Install mode will modify the configured game directory.")

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func resolve_cli(configured_path: String) -> Dictionary:
	var configured := configured_path.strip_edges()
	if not configured.is_empty():
		if _looks_like_holopatcher(configured):
			return {
				"executable": configured,
				"module_args": PackedStringArray(),
				"source": "configured_holopatcher",
				"cli_kind": "holopatcher",
			}
		if _looks_like_python_launcher(configured):
			return {
				"executable": configured,
				"module_args": PackedStringArray(["-m", "holopatcher"]),
				"source": "configured_python",
				"cli_kind": "holopatcher_module",
			}
		return {
			"executable": configured,
			"module_args": PackedStringArray(),
			"source": "configured",
			"cli_kind": "holopatcher",
		}

	for candidate in HOLOPATCHER_CANDIDATES:
		if _command_exists(candidate):
			return {
				"executable": candidate,
				"module_args": PackedStringArray(),
				"source": "path_%s" % candidate,
				"cli_kind": "holopatcher",
			}

	for py in PYTHON_CANDIDATES:
		if not _command_exists(py):
			continue
		var output: Array = []
		var exit_code := OS.execute(py, PackedStringArray(["-m", "holopatcher", "--help"]), output, true)
		if exit_code == 0:
			return {
				"executable": py,
				"module_args": PackedStringArray(["-m", "holopatcher"]),
				"source": "path_%s_module" % py,
				"cli_kind": "holopatcher_module",
			}

	return {
		"executable": "",
		"module_args": PackedStringArray(),
		"source": "missing",
		"cli_kind": "",
	}


static func build_command(config: Dictionary) -> Dictionary:
	var preflight := validate_preflight(config)
	if not preflight.get("ok", false):
		return {
			"ok": false,
			"errors": preflight.get("errors", []),
			"warnings": preflight.get("warnings", []),
		}

	var configured_cli := str(
		config.get("holopatcher_cli_path", config.get("pykotor_cli_path", ""))
	).strip_edges()
	var cli := resolve_cli(configured_cli)
	var game_dir := str(config.get("game_dir", config.get("game_path", ""))).strip_edges()
	var tslpatchdata := str(config.get("tslpatchdata", "")).strip_edges()
	var mode := _normalize_mode(str(config.get("mode", MODE_VALIDATE)))

	var args := PackedStringArray()
	args.append_array(cli.get("module_args", PackedStringArray()) as PackedStringArray)
	args.append(game_dir)
	args.append(tslpatchdata)
	if mode == MODE_VALIDATE:
		args.append("--validate")
	elif mode == MODE_INSTALL:
		args.append("--install")
	args.append("--console")

	return {
		"ok": true,
		"executable": str(cli.get("executable", "")),
		"arguments": args,
		"warnings": preflight.get("warnings", []),
		"cli_kind": str(cli.get("cli_kind", "")),
		"mode": mode,
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

	if exit_code != 0:
		var detail := stderr if not stderr.is_empty() else stdout
		if detail.is_empty():
			detail = "HoloPatcher CLI exited with code %d" % exit_code
		return {
			"ok": false,
			"message": detail.strip_edges(),
			"exit_code": exit_code,
			"stdout": stdout,
			"stderr": stderr,
			"mode": built.get("mode", ""),
		}

	var message := "HoloPatcher %s completed" % str(built.get("mode", "run"))
	if not stdout.is_empty():
		message = stdout.strip_edges().split("\n")[0]

	return {
		"ok": true,
		"message": message,
		"exit_code": exit_code,
		"stdout": stdout,
		"stderr": stderr,
		"mode": built.get("mode", ""),
		"warnings": built.get("warnings", []),
	}


static func _normalize_mode(mode: String) -> String:
	var normalized := mode.strip_edges().to_lower()
	if normalized in [MODE_VALIDATE, MODE_INSTALL]:
		return normalized
	return ""


static func _path_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)


static func _looks_like_holopatcher(path: String) -> bool:
	var base := path.get_file().to_lower()
	return base.contains("holopatcher")


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


static func _cli_usable(command: String) -> bool:
	return _command_exists(command)


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)
