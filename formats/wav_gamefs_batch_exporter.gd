## Batch WAV export from indexed GameFS install resources.
class_name WavGamefsBatchExporter

const WavMetadata := preload("wav_metadata.gd")


## Export indexed `.wav` resources to a flat output directory.
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

	var entries: Array = gamefs.list_core_resources(query, "wav", source_filter, limit)
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

		var wav_path := output_dir.path_join("%s.wav" % resref)
		if skip_existing and FileAccess.file_exists(wav_path):
			skipped.append({
				"resref": resref,
				"wav_path": wav_path,
				"reason": "exists",
			})
			continue

		var wav_bytes := _load_entry_bytes(gamefs, entry)
		if wav_bytes.is_empty():
			failed.append({
				"resref": resref,
				"wav_path": wav_path,
				"message": "Failed to load WAV bytes.",
			})
			continue

		if not dry_run:
			var wav_error := _write_bytes(wav_path, wav_bytes)
			if wav_error != OK:
				failed.append({
					"resref": resref,
					"wav_path": wav_path,
					"message": "Failed to write WAV (error %d)" % wav_error,
				})
				continue

		var record := {
			"resref": resref,
			"source": str(entry.get("source", "")),
			"wav_path": wav_path,
			"dry_run": dry_run,
		}
		if include_metadata:
			var metadata := WavMetadata.parse_bytes(wav_bytes)
			if metadata.get("ok", false):
				record["channels"] = int(metadata.get("channels", 0))
				record["sample_rate"] = int(metadata.get("sample_rate", 0))
				record["duration_seconds"] = float(metadata.get("duration_seconds", 0.0))
				record["format_label"] = str(metadata.get("format_label", ""))
				record["metadata_summary"] = _format_metadata_summary(metadata)
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
	lines.append(str(result.get("summary", "Install batch WAV export finished.")))
	var generated: Array = result.get("generated", [])
	for raw_record in generated:
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = raw_record
		var line := "%s → %s" % [
			str(record.get("resref", "")),
			str(record.get("wav_path", "")).get_file(),
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


static func _format_metadata_summary(meta: Dictionary) -> String:
	if not meta.get("ok", false):
		return "Invalid WAV"
	return "%s, %d ch, %d Hz, %.2f s" % [
		meta.get("format_label", "?"),
		int(meta.get("channels", 0)),
		int(meta.get("sample_rate", 0)),
		float(meta.get("duration_seconds", 0.0)),
	]


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
	return "Install batch WAV export: %d exported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
