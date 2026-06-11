## Batch WOK export from indexed GameFS install resources.
class_name BwmGamefsBatchExporter

const BwmMetadataHelper := preload("../editor/tools/bwm_metadata_helper.gd")


## Export indexed `.wok` resources to a flat output directory.
static func batch_install(
		gamefs: RefCounted,
		output_dir: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var include_metadata := bool(options.get("include_metadata", true))
	var source_filter := str(options.get("source_filter", "override")).strip_edges().to_lower()
	var query := str(options.get("query", "")).strip_edges()
	var limit := int(options.get("limit", 0))

	if gamefs == null:
		return {"ok": false, "message": "GameFS index is unavailable for batch export."}
	if not gamefs.has_method("list_core_resources") or not gamefs.has_method("load_resource_entry_bytes"):
		return {"ok": false, "message": "GameFS does not support indexed batch export."}
	if output_dir.is_empty() or not DirAccess.dir_exists_absolute(output_dir):
		return {"ok": false, "message": "Output directory not found: %s" % output_dir}

	var entries: Array = gamefs.list_core_resources(query, "wok", source_filter, limit)
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []

	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var resref := str(entry.get("resref", "")).strip_edges()
		if resref.is_empty():
			continue

		var wok_path := output_dir.path_join("%s.wok" % resref)
		if skip_existing and FileAccess.file_exists(wok_path):
			skipped.append({
				"resref": resref,
				"wok_path": wok_path,
				"reason": "exists",
			})
			continue

		var wok_bytes := _load_entry_bytes(gamefs, entry)
		if wok_bytes.is_empty():
			failed.append({
				"resref": resref,
				"wok_path": wok_path,
				"message": "Failed to load WOK bytes.",
			})
			continue

		if not dry_run:
			var wok_error := _write_bytes(wok_path, wok_bytes)
			if wok_error != OK:
				failed.append({
					"resref": resref,
					"wok_path": wok_path,
					"message": "Failed to write WOK (error %d)" % wok_error,
				})
				continue

		var record := {
			"resref": resref,
			"source": str(entry.get("source", "")),
			"wok_path": wok_path,
			"dry_run": dry_run,
		}
		if include_metadata:
			var metadata := BwmMetadataHelper.summarize_bytes(wok_bytes)
			if metadata.get("ok", false):
				record["vertex_count"] = int(metadata.get("vertex_count", 0))
				record["face_count"] = int(metadata.get("face_count", 0))
				record["walkable_face_count"] = int(metadata.get("walkable_face_count", 0))
				record["metadata_summary"] = BwmMetadataHelper.format_summary(metadata)
		generated.append(record)

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"scanned": entries.size(),
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func format_report(result: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(str(result.get("summary", "Install batch WOK export finished.")))
	var generated: Array = result.get("generated", [])
	for raw_record in generated:
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = raw_record
		var line := "%s → %s" % [
			str(record.get("resref", "")),
			str(record.get("wok_path", "")).get_file(),
		]
		if record.has("metadata_summary"):
			line += " — %s" % str(record.get("metadata_summary", ""))
		lines.append(line)
	var failed: Array = result.get("failed", [])
	for raw_failure in failed:
		if typeof(raw_failure) != TYPE_DICTIONARY:
			continue
		var failure: Dictionary = raw_failure
		lines.append("FAILED %s: %s" % [
			str(failure.get("resref", "")),
			str(failure.get("message", "?")),
		])
	return "\n".join(lines)


static func _load_entry_bytes(gamefs: RefCounted, entry: Dictionary) -> PackedByteArray:
	var absolute_path := str(entry.get("absolute_path", "")).strip_edges()
	if not absolute_path.is_empty() and FileAccess.file_exists(absolute_path):
		return FileAccess.get_file_as_bytes(absolute_path)
	return gamefs.load_resource_entry_bytes(entry)


static func _write_bytes(path: String, bytes: PackedByteArray) -> Error:
	if bytes.is_empty():
		return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	file.close()
	return OK


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch WOK export: %d exported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
