## Batch MDL copy from a flat or recursive filesystem folder (with optional MDX sidecar).
class_name MdlBatchExporter

const BatchDirectoryScanner := preload("batch_directory_scanner.gd")
const MdlGamefsBatchExporter := preload("mdl_gamefs_batch_exporter.gd")
const MdlModelMetadataHelper := preload("../editor/tools/mdl_model_metadata_helper.gd")

const SUPPORTED_EXTENSIONS := ["mdl"]


## Copy each `.mdl` in `source_dir` to `output_dir`, including paired `.mdx` when present.
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

	var mdl_paths := BatchDirectoryScanner.list_files(
		source_dir,
		PackedStringArray(SUPPORTED_EXTENSIONS),
		recursive
	)
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []
	var seen_resrefs: Dictionary = {}

	for source_mdl in mdl_paths:
		var resref := source_mdl.get_file().get_basename()
		if recursive and seen_resrefs.has(resref):
			failed.append({
				"resref": resref,
				"source_mdl": source_mdl,
				"mdl_path": output_dir.path_join("%s.mdl" % resref),
				"message": "Duplicate resref across subfolders: %s" % resref,
			})
			continue
		seen_resrefs[resref] = source_mdl

		var dest_mdl := output_dir.path_join("%s.mdl" % resref)
		var dest_mdx := output_dir.path_join("%s.mdx" % resref)
		var source_mdx := source_mdl.get_base_dir().path_join("%s.mdx" % resref)

		if skip_existing and FileAccess.file_exists(dest_mdl):
			skipped.append({
				"resref": resref,
				"mdl_path": dest_mdl,
				"reason": "exists",
			})
			continue

		var mdl_bytes := FileAccess.get_file_as_bytes(source_mdl)
		if mdl_bytes.is_empty():
			failed.append({
				"resref": resref,
				"mdl_path": dest_mdl,
				"message": "Failed to read MDL bytes.",
			})
			continue

		var mdx_bytes := PackedByteArray()
		if FileAccess.file_exists(source_mdx):
			mdx_bytes = FileAccess.get_file_as_bytes(source_mdx)

		var wrote_mdx := false
		if not dry_run:
			var mdl_error := _write_bytes(dest_mdl, mdl_bytes)
			if mdl_error != OK:
				failed.append({
					"resref": resref,
					"mdl_path": dest_mdl,
					"message": "Failed to write MDL (error %d)" % mdl_error,
				})
				continue
			if not mdx_bytes.is_empty():
				var mdx_error := _write_bytes(dest_mdx, mdx_bytes)
				if mdx_error != OK:
					failed.append({
						"resref": resref,
						"mdl_path": dest_mdl,
						"mdx_path": dest_mdx,
						"message": "Failed to write MDX (error %d)" % mdx_error,
					})
					continue
				wrote_mdx = true

		var record := {
			"resref": resref,
			"source_mdl": source_mdl,
			"mdl_path": dest_mdl,
			"mdx_path": dest_mdx if wrote_mdx or (dry_run and not mdx_bytes.is_empty()) else "",
			"has_mdx": not mdx_bytes.is_empty(),
			"dry_run": dry_run,
		}
		if include_metadata:
			var metadata := MdlModelMetadataHelper.summarize_bytes(mdl_bytes, mdx_bytes)
			if metadata.get("ok", false):
				record["vertex_count"] = int(metadata.get("vertex_count", 0))
				record["face_count"] = int(metadata.get("face_count", 0))
				record["metadata_summary"] = MdlModelMetadataHelper.format_summary(metadata)
		generated.append(record)

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func format_report(result: Dictionary) -> String:
	return MdlGamefsBatchExporter.format_report(result)


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
	return "Folder batch MDL export: %d exported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
