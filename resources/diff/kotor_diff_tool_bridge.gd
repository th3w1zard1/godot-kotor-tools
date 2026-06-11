## PyKotor KotorDiff CLI bridge for install/file/directory comparison.
class_name KotorDiffToolBridge

const KotorIndoorModExporter := preload("../indoor/kotor_indoor_mod_exporter.gd")

const KOTORDIFF_CANDIDATES := ["kotordiff"]
const PYKOTOR_DIFF_SUBCOMMAND := "diff"


static func validate_preflight(config: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var path1 := str(config.get("path1", "")).strip_edges()
	if path1.is_empty():
		errors.append("KotorDiff path1 is required.")
	elif not _path_exists(path1):
		errors.append("KotorDiff path1 does not exist: %s" % path1)

	var path2 := str(config.get("path2", "")).strip_edges()
	if path2.is_empty():
		errors.append("KotorDiff path2 is required.")
	elif not _path_exists(path2):
		errors.append("KotorDiff path2 does not exist: %s" % path2)

	var output_log := str(config.get("output_log", "")).strip_edges()
	if output_log.is_empty():
		warnings.append("No output log path; KotorDiff may prompt interactively or use its default log file.")

	var configured_cli := str(config.get("kotordiff_cli_path", config.get("pykotor_cli_path", ""))).strip_edges()
	var cli := resolve_cli(configured_cli)
	if str(cli.get("executable", "")).is_empty():
		errors.append(
			"KotorDiff CLI not found. Install kotordiff or PyKotor and set kotor_tools/pykotor_cli_path, "
			+ "or ensure kotordiff/pykotorcli is on PATH."
		)
	elif not configured_cli.is_empty() and not _cli_usable(str(cli.get("executable", ""))):
		errors.append("KotorDiff CLI not found at configured path: %s" % configured_cli)

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func resolve_cli(configured_path: String) -> Dictionary:
	var configured := configured_path.strip_edges()
	if not configured.is_empty():
		if _looks_like_kotordiff(configured):
			return {
				"executable": configured,
				"module_args": PackedStringArray(),
				"source": "configured_kotordiff",
				"cli_kind": "kotordiff",
			}
		if _looks_like_python_launcher(configured):
			return {
				"executable": configured,
				"module_args": PackedStringArray(["-m", "pykotor"]),
				"source": "configured_python",
				"cli_kind": "pykotor",
			}
		return {
			"executable": configured,
			"module_args": PackedStringArray(),
			"source": "configured",
			"cli_kind": "kotordiff",
		}

	for candidate in KOTORDIFF_CANDIDATES:
		if _command_exists(candidate):
			return {
				"executable": candidate,
				"module_args": PackedStringArray(),
				"source": "path_%s" % candidate,
				"cli_kind": "kotordiff",
			}

	var pykotor_cli := KotorIndoorModExporter.resolve_cli("")
	if not str(pykotor_cli.get("executable", "")).is_empty():
		return {
			"executable": str(pykotor_cli.get("executable", "")),
			"module_args": pykotor_cli.get("module_args", PackedStringArray()) as PackedStringArray,
			"source": "path_pykotor_%s" % str(pykotor_cli.get("source", "")),
			"cli_kind": "pykotor",
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

	var configured_cli := str(config.get("kotordiff_cli_path", config.get("pykotor_cli_path", ""))).strip_edges()
	var cli := resolve_cli(configured_cli)
	var path1 := str(config.get("path1", "")).strip_edges()
	var path2 := str(config.get("path2", "")).strip_edges()
	var output_log := str(config.get("output_log", "")).strip_edges()

	var args := PackedStringArray()
	args.append_array(cli.get("module_args", PackedStringArray()) as PackedStringArray)
	if str(cli.get("cli_kind", "")) == "pykotor":
		args.append(PYKOTOR_DIFF_SUBCOMMAND)
	args.append("--path1")
	args.append(path1)
	args.append("--path2")
	args.append(path2)
	if not output_log.is_empty():
		args.append("--output-log")
		args.append(output_log)

	var game := str(config.get("game", "")).strip_edges()
	if game.is_empty():
		var game_path := str(config.get("game_path", path1)).strip_edges()
		game = KotorIndoorModExporter.infer_game_from_path(game_path)
	if str(cli.get("cli_kind", "")) == "pykotor" and game == "k2":
		args.append("--tsl")

	return {
		"ok": true,
		"executable": str(cli.get("executable", "")),
		"arguments": args,
		"warnings": preflight.get("warnings", []),
		"cli_kind": str(cli.get("cli_kind", "")),
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

	var output_log := str(working.get("output_log", "")).strip_edges()
	if exit_code != 0:
		var detail := stderr if not stderr.is_empty() else stdout
		if detail.is_empty():
			detail = "KotorDiff CLI exited with code %d" % exit_code
		return {
			"ok": false,
			"message": detail.strip_edges(),
			"exit_code": exit_code,
			"stdout": stdout,
			"stderr": stderr,
			"output_log": output_log,
		}

	var message := "KotorDiff completed"
	if not output_log.is_empty() and FileAccess.file_exists(output_log):
		message = "KotorDiff log written to %s" % output_log.get_file()
	elif not stdout.is_empty():
		message = stdout.strip_edges().split("\n")[0]

	return {
		"ok": true,
		"message": message,
		"exit_code": exit_code,
		"stdout": stdout,
		"stderr": stderr,
		"output_log": output_log,
		"warnings": built.get("warnings", []),
	}


static func _path_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)


static func _looks_like_kotordiff(path: String) -> bool:
	var base := path.get_file().to_lower()
	return base.contains("kotordiff")


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
