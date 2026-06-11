## Batch TGA/PNG to TPC import from indexed GameFS override images.
class_name TpcGamefsBatchImporter

const TpcBatchConverter := preload("tpc_batch_converter.gd")


## Convert indexed override images to `.tpc` files written under the install override folder.
static func batch_install_to_override(
		gamefs: RefCounted,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var alpha_test := float(options.get("alpha_test", 0.0))
	var source_filter := str(options.get("source_filter", "override")).strip_edges().to_lower()
	var query := str(options.get("query", "")).strip_edges()
	var limit := int(options.get("limit", 0))

	if gamefs == null:
		return {"ok": false, "message": "GameFS index is unavailable for batch import."}
	if not gamefs.has_method("list_core_resources"):
		return {"ok": false, "message": "GameFS does not support indexed batch import."}

	var override_path := _resolve_override_path(gamefs)
	if override_path.is_empty():
		return {"ok": false, "message": "Override folder is unavailable for batch import."}

	var candidates := _collect_candidates(gamefs, override_path, source_filter, query, limit)
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []

	for candidate in candidates:
		var resref := str(candidate.get("resref", "")).strip_edges()
		var image_path := str(candidate.get("image_path", "")).strip_edges()
		if resref.is_empty() or image_path.is_empty():
			continue

		var tpc_path := override_path.path_join("%s.tpc" % resref)
		if skip_existing and FileAccess.file_exists(tpc_path):
			skipped.append({
				"resref": resref,
				"image_path": image_path,
				"tpc_path": tpc_path,
				"reason": "exists",
			})
			continue

		if dry_run:
			generated.append({
				"resref": resref,
				"image_path": image_path,
				"tpc_path": tpc_path,
				"dry_run": true,
			})
			continue

		var result := TpcBatchConverter.convert_from_image_file(image_path, {"alpha_test": alpha_test})
		if not result.get("ok", false):
			failed.append({
				"resref": resref,
				"image_path": image_path,
				"tpc_path": tpc_path,
				"message": str(result.get("message", "Conversion failed")),
			})
			continue

		var write_error := _write_bytes(tpc_path, result.get("bytes", PackedByteArray()) as PackedByteArray)
		if write_error != OK:
			failed.append({
				"resref": resref,
				"image_path": image_path,
				"tpc_path": tpc_path,
				"message": "Failed to write TPC (error %d)" % write_error,
			})
			continue

		generated.append({
			"resref": resref,
			"image_path": image_path,
			"tpc_path": tpc_path,
			"width": int(result.get("width", 0)),
			"height": int(result.get("height", 0)),
		})

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"scanned": candidates.size(),
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func _collect_candidates(
		gamefs: RefCounted,
		override_path: String,
		source_filter: String,
		query: String,
		limit: int
) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var candidates: Array[Dictionary] = []

	if source_filter.is_empty() or source_filter == "override":
		for entry in gamefs.list_core_resources(query, "tga", "override", 0):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var candidate := _candidate_from_entry(entry as Dictionary)
			if candidate.is_empty():
				continue
			var resref := str(candidate.get("resref", ""))
			if seen.has(resref):
				continue
			seen[resref] = true
			candidates.append(candidate)
			if limit > 0 and candidates.size() >= limit:
				return candidates

		_append_override_png_candidates(override_path, query, limit, seen, candidates)

	return candidates


static func _candidate_from_entry(entry: Dictionary) -> Dictionary:
	var resref := str(entry.get("resref", "")).strip_edges()
	var absolute_path := str(entry.get("absolute_path", "")).strip_edges()
	if resref.is_empty() or absolute_path.is_empty() or not FileAccess.file_exists(absolute_path):
		return {}
	return {
		"resref": resref,
		"image_path": absolute_path,
		"extension": str(entry.get("extension", "")),
		"source": str(entry.get("source", "")),
	}


static func _append_override_png_candidates(
		override_path: String,
		query: String,
		limit: int,
		seen: Dictionary,
		candidates: Array[Dictionary]
) -> void:
	if override_path.is_empty() or not DirAccess.dir_exists_absolute(override_path):
		return
	var normalized_query := query.strip_edges().to_lower()
	var dir := DirAccess.open(override_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "png":
			continue
		var resref := file_name.get_basename()
		if resref.is_empty() or seen.has(resref):
			continue
		if not normalized_query.is_empty() and not resref.to_lower().contains(normalized_query):
			continue
		seen[resref] = true
		candidates.append({
			"resref": resref,
			"image_path": override_path.path_join(file_name),
			"extension": "png",
			"source": "override",
		})
		if limit > 0 and candidates.size() >= limit:
			break
	dir.list_dir_end()


static func _resolve_override_path(gamefs: RefCounted) -> String:
	if gamefs.has_method("ensure_override_path"):
		return str(gamefs.call("ensure_override_path")).strip_edges()
	if gamefs.has_method("get"):
		return str(gamefs.get("override_path")).strip_edges()
	return ""


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
	return "Install batch TPC import: %d imported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
