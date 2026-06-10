## Batch TPC to TGA export from indexed GameFS install resources.
class_name TpcGamefsBatchExporter

const KotorMediaToolBridge := preload("../resources/scripts/kotor_media_tool_bridge.gd")


## Export indexed `.tpc` resources to a flat output directory via texture-convert.
static func batch_install(
		gamefs: RefCounted,
		output_dir: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var pykotor_cli_path := str(options.get("pykotor_cli_path", "")).strip_edges()
	var texture_format := str(options.get("texture_format", "")).strip_edges()
	var source_filter := str(options.get("source_filter", "override")).strip_edges().to_lower()
	var query := str(options.get("query", "")).strip_edges()
	var limit := int(options.get("limit", 0))

	if gamefs == null:
		return {"ok": false, "message": "GameFS index is unavailable for batch export."}
	if not gamefs.has_method("list_core_resources") or not gamefs.has_method("load_resource_entry_bytes"):
		return {"ok": false, "message": "GameFS does not support indexed batch export."}
	if output_dir.is_empty() or not DirAccess.dir_exists_absolute(output_dir):
		return {"ok": false, "message": "Output directory not found: %s" % output_dir}

	var entries: Array = gamefs.list_core_resources(query, "tpc", source_filter, limit)
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []
	var temp_paths: Array[String] = []

	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var resref := str(entry.get("resref", "")).strip_edges()
		if resref.is_empty():
			continue
		var tga_path := output_dir.path_join("%s.tga" % resref)
		if skip_existing and FileAccess.file_exists(tga_path):
			skipped.append({
				"resref": resref,
				"tga_path": tga_path,
				"reason": "exists",
			})
			continue

		var input_result := _resolve_input_path(gamefs, entry, temp_paths)
		if not input_result.get("ok", false):
			failed.append({
				"resref": resref,
				"tga_path": tga_path,
				"message": str(input_result.get("message", "Failed to resolve TPC input.")),
			})
			continue

		var tpc_path := str(input_result.get("path", ""))
		var export_result := _export_single(
			tpc_path,
			tga_path,
			pykotor_cli_path,
			texture_format,
			dry_run
		)
		if not export_result.get("ok", false):
			failed.append({
				"resref": resref,
				"tpc_path": tpc_path,
				"tga_path": tga_path,
				"message": str(export_result.get("message", "Export failed")),
			})
			continue

		generated.append({
			"resref": resref,
			"source": str(entry.get("source", "")),
			"tpc_path": tpc_path,
			"tga_path": tga_path,
			"dry_run": dry_run,
		})

	_cleanup_temp_paths(temp_paths)

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"scanned": entries.size(),
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func _resolve_input_path(
		gamefs: RefCounted,
		entry: Dictionary,
		temp_paths: Array[String]
) -> Dictionary:
	var absolute_path := str(entry.get("absolute_path", "")).strip_edges()
	if not absolute_path.is_empty() and FileAccess.file_exists(absolute_path):
		return {"ok": true, "path": absolute_path, "temp": false}

	var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(entry)
	if bytes.is_empty():
		return {"ok": false, "message": "Failed to load TPC bytes for %s." % str(entry.get("resref", ""))}

	var resref := str(entry.get("resref", "texture")).strip_edges()
	var temp_dir := ProjectSettings.globalize_path("user://kotor_tools/tmp/gamefs_batch")
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var temp_path := temp_dir.path_join("%s.tpc" % resref)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Failed to write temporary TPC for %s." % resref}
	file.store_buffer(bytes)
	file.close()
	temp_paths.append(temp_path)
	return {"ok": true, "path": temp_path, "temp": true}


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


static func _cleanup_temp_paths(temp_paths: Array[String]) -> void:
	for path in temp_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch TGA export: %d exported, %d skipped, %d failed." % [
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
