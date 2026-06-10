## Batch TPC to TGA export via PyKotor texture-convert CLI bridge.
class_name TpcBatchExporter

const KotorMediaToolBridge := preload("../resources/scripts/kotor_media_tool_bridge.gd")


## Export each `.tpc` in a flat directory to a matching `.tga` via texture-convert.
static func batch_directory(
		dir_path: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var pykotor_cli_path := str(options.get("pykotor_cli_path", "")).strip_edges()
	var texture_format := str(options.get("texture_format", "")).strip_edges()

	if dir_path.is_empty() or not DirAccess.dir_exists_absolute(dir_path):
		return {"ok": false, "message": "Directory not found: %s" % dir_path}

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return {"ok": false, "message": "Failed to open directory: %s" % dir_path}

	dir.list_dir_begin()
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []

	while true:
		var entry_name := dir.get_next()
		if entry_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if entry_name.get_extension().to_lower() != "tpc":
			continue

		var tpc_path := dir_path.path_join(entry_name)
		var tga_path := _tga_path_for_tpc(tpc_path)
		if skip_existing and FileAccess.file_exists(tga_path):
			skipped.append({"tpc_path": tpc_path, "tga_path": tga_path, "reason": "exists"})
			continue

		var result := _export_single(tpc_path, tga_path, pykotor_cli_path, texture_format, dry_run)
		if not result.get("ok", false):
			failed.append({
				"tpc_path": tpc_path,
				"tga_path": tga_path,
				"message": str(result.get("message", "Export failed")),
			})
			continue

		generated.append({
			"tpc_path": tpc_path,
			"tga_path": tga_path,
			"dry_run": dry_run,
		})

	dir.list_dir_end()

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func _export_single(
		tpc_path: String,
		tga_path: String,
		pykotor_cli_path: String,
		texture_format: String,
		dry_run: bool
) -> Dictionary:
	var config := {
		"operation": KotorMediaToolBridge.Operation.TEXTURE_CONVERT,
		"input_path": tpc_path,
		"output_path": tga_path,
		"pykotor_cli_path": pykotor_cli_path,
		"texture_format": texture_format,
		"dry_run": dry_run,
	}
	if dry_run:
		var built := KotorMediaToolBridge.build_command(config)
		if not built.get("ok", false):
			return {
				"ok": false,
				"message": _join_lines(built.get("errors", [])),
			}
		return {"ok": true, "message": "Command ready."}

	return KotorMediaToolBridge.run_texture_convert(
		tpc_path,
		tga_path,
		pykotor_cli_path,
		texture_format
	)


static func _tga_path_for_tpc(tpc_path: String) -> String:
	return "%s.tga" % tpc_path.get_basename()


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Batch TGA export: %d exported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)
