## Batch WAV copy from a flat or recursive filesystem folder.
class_name WavBatchExporter

const BatchDirectoryScanner := preload("batch_directory_scanner.gd")
const WavGamefsBatchExporter := preload("wav_gamefs_batch_exporter.gd")
const WavMetadata := preload("wav_metadata.gd")

const SUPPORTED_EXTENSIONS := ["wav"]


## Copy each `.wav` in `source_dir` to `{resref}.wav` in `output_dir`.
## Options: `skip_existing`, `dry_run`, `include_metadata`, `recursive`.
static func batch_directory(
		source_dir: String,
		output_dir: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var include_metadata := bool(options.get("include_metadata", true))
	var recursive := bool(options.get("recursive", false))

	if source_dir.is_empty() or not DirAccess.dir_exists_absolute(source_dir):
		return {"ok": false, "message": "Source directory not found: %s" % source_dir}
	if output_dir.is_empty() or not DirAccess.dir_exists_absolute(output_dir):
		return {"ok": false, "message": "Output directory not found: %s" % output_dir}

	var wav_paths := BatchDirectoryScanner.list_files(
		source_dir,
		PackedStringArray(SUPPORTED_EXTENSIONS),
		recursive
	)
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []
	var seen_resrefs: Dictionary = {}

	for wav_path in wav_paths:
		var resref := wav_path.get_file().get_basename()
		if recursive and seen_resrefs.has(resref):
			failed.append({
				"resref": resref,
				"source_wav": wav_path,
				"wav_path": output_dir.path_join("%s.wav" % resref),
				"message": "Duplicate resref across subfolders: %s" % resref,
			})
			continue
		seen_resrefs[resref] = wav_path

		var dest_wav := output_dir.path_join("%s.wav" % resref)
		if skip_existing and FileAccess.file_exists(dest_wav):
			skipped.append({
				"resref": resref,
				"wav_path": dest_wav,
				"reason": "exists",
			})
			continue

		var wav_bytes := FileAccess.get_file_as_bytes(wav_path)
		if wav_bytes.is_empty():
			failed.append({
				"resref": resref,
				"wav_path": dest_wav,
				"message": "Failed to read WAV bytes.",
			})
			continue

		if not dry_run:
			var wav_error := _write_bytes(dest_wav, wav_bytes)
			if wav_error != OK:
				failed.append({
					"resref": resref,
					"wav_path": dest_wav,
					"message": "Failed to write WAV (error %d)" % wav_error,
				})
				continue

		var record := {
			"resref": resref,
			"source_wav": wav_path,
			"wav_path": dest_wav,
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
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func format_report(result: Dictionary) -> String:
	return WavGamefsBatchExporter.format_report(result)


static func _format_metadata_summary(meta: Dictionary) -> String:
	if not meta.get("ok", false):
		return "Invalid WAV"
	return "%s, %d ch, %d Hz, %.2f s" % [
		meta.get("format_label", "?"),
		int(meta.get("channels", 0)),
		int(meta.get("sample_rate", 0)),
		float(meta.get("duration_seconds", 0.0)),
	]


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
	return "Folder batch WAV export: %d exported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
