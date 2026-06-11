## Batch WOK copy from a flat filesystem folder.
class_name BwmBatchExporter

const BwmGamefsBatchExporter := preload("bwm_gamefs_batch_exporter.gd")
const BwmMetadataHelper := preload("../editor/tools/bwm_metadata_helper.gd")

const WALKMESH_SOURCE_EXTENSIONS := {
	"wok": true,
	"bwm": true,
}
const WALKMESH_OUTPUT_EXTENSION := "wok"


## Copy each `.wok` or `.bwm` in `source_dir` to `{resref}.wok` in `output_dir`.
static func batch_directory(
		source_dir: String,
		output_dir: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var include_metadata := bool(options.get("include_metadata", true))

	if source_dir.is_empty() or not DirAccess.dir_exists_absolute(source_dir):
		return {"ok": false, "message": "Source directory not found: %s" % source_dir}
	if output_dir.is_empty() or not DirAccess.dir_exists_absolute(output_dir):
		return {"ok": false, "message": "Output directory not found: %s" % output_dir}

	var dir := DirAccess.open(source_dir)
	if dir == null:
		return {"ok": false, "message": "Failed to open source directory: %s" % source_dir}

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
		var extension := entry_name.get_extension().to_lower()
		if not WALKMESH_SOURCE_EXTENSIONS.get(extension, false):
			continue

		var resref := entry_name.get_basename()
		var source_wok := source_dir.path_join(entry_name)
		var dest_wok := output_dir.path_join("%s.%s" % [resref, WALKMESH_OUTPUT_EXTENSION])

		if skip_existing and FileAccess.file_exists(dest_wok):
			skipped.append({
				"resref": resref,
				"wok_path": dest_wok,
				"reason": "exists",
			})
			continue

		var wok_bytes := FileAccess.get_file_as_bytes(source_wok)
		if wok_bytes.is_empty():
			failed.append({
				"resref": resref,
				"wok_path": dest_wok,
				"message": "Failed to read WOK bytes.",
			})
			continue

		if not dry_run:
			var wok_error := _write_bytes(dest_wok, wok_bytes)
			if wok_error != OK:
				failed.append({
					"resref": resref,
					"wok_path": dest_wok,
					"message": "Failed to write WOK (error %d)" % wok_error,
				})
				continue

		var record := {
			"resref": resref,
			"source_wok": source_wok,
			"wok_path": dest_wok,
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

	dir.list_dir_end()

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func format_report(result: Dictionary) -> String:
	return BwmGamefsBatchExporter.format_report(result)


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
	return "Folder batch WOK export: %d exported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
