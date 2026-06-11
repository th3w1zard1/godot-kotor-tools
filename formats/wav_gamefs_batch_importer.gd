## Batch WAV sound-convert import from filesystem folders and indexed override WAVs.
class_name WavGamefsBatchImporter

const WavBatchConverter := preload("wav_batch_converter.gd")


## Convert indexed override `.wav` resources to `{resref}_clean.wav` in override.
static func batch_install_to_override(
		gamefs: RefCounted,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var sound_type := str(options.get("sound_type", "SFX")).strip_edges().to_upper()
	var source_filter := str(options.get("source_filter", "override")).strip_edges().to_lower()
	var query := str(options.get("query", "")).strip_edges()
	var limit := int(options.get("limit", 0))
	var convert_options := {
		"pykotor_cli_path": str(options.get("pykotor_cli_path", "")).strip_edges(),
		"sound_type": sound_type,
		"to_clean": bool(options.get("to_clean", true)),
		"dry_run": dry_run,
	}

	if gamefs == null:
		return {"ok": false, "message": "GameFS index is unavailable for batch import."}
	if not gamefs.has_method("list_core_resources"):
		return {"ok": false, "message": "GameFS does not support indexed batch import."}

	var override_path := _resolve_override_path(gamefs)
	if override_path.is_empty():
		return {"ok": false, "message": "Override folder is unavailable for batch import."}

	var candidates := _collect_wav_candidates(gamefs, override_path, source_filter, query, limit)
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []

	for candidate in candidates:
		var resref := str(candidate.get("resref", "")).strip_edges()
		var wav_path := str(candidate.get("wav_path", "")).strip_edges()
		if resref.is_empty() or wav_path.is_empty():
			continue

		var output_path := WavBatchConverter.clean_output_path_for_resref(override_path, resref)
		if skip_existing and FileAccess.file_exists(output_path):
			skipped.append({
				"resref": resref,
				"wav_path": wav_path,
				"output_path": output_path,
				"reason": "exists",
			})
			continue

		var result := WavBatchConverter.convert_file(wav_path, output_path, convert_options)
		if not result.get("ok", false):
			failed.append({
				"resref": resref,
				"wav_path": wav_path,
				"output_path": output_path,
				"message": str(result.get("message", "Conversion failed")),
			})
			continue

		generated.append({
			"resref": resref,
			"wav_path": wav_path,
			"output_path": output_path,
			"sound_type": sound_type,
			"dry_run": dry_run,
		})

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"scanned": candidates.size(),
		"summary": _format_install_summary(generated.size(), skipped.size(), failed.size()),
	}


## Convert each `.wav` in `source_dir` and write `{resref}_clean.wav` into override.
static func batch_folder_to_override(
		gamefs: RefCounted,
		source_dir: String,
		options: Dictionary = {}
) -> Dictionary:
	if gamefs == null:
		return {"ok": false, "message": "GameFS index is unavailable for batch import."}

	var override_path := _resolve_override_path(gamefs)
	if override_path.is_empty():
		return {"ok": false, "message": "Override folder is unavailable for batch import."}
	if source_dir.is_empty() or not DirAccess.dir_exists_absolute(source_dir):
		return {"ok": false, "message": "Source directory not found: %s" % source_dir}

	var result := WavBatchConverter.batch_directory_to_output(source_dir, override_path, options)
	var generated: Array = result.get("generated", [])
	var skipped: Array = result.get("skipped", [])
	var failed: Array = result.get("failed", [])
	result["summary"] = _format_folder_summary(generated.size(), skipped.size(), failed.size())
	return result


static func format_report(result: Dictionary) -> String:
	return WavBatchConverter.format_report(result)


static func _collect_wav_candidates(
		gamefs: RefCounted,
		override_path: String,
		source_filter: String,
		query: String,
		limit: int
) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var candidates: Array[Dictionary] = []

	if source_filter.is_empty() or source_filter == "override":
		for entry in gamefs.list_core_resources(query, "wav", "override", 0):
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

		_append_override_wav_candidates(override_path, query, limit, seen, candidates)

	return candidates


static func _candidate_from_entry(entry: Dictionary) -> Dictionary:
	var resref := str(entry.get("resref", "")).strip_edges()
	if resref.is_empty() or resref.ends_with("_clean"):
		return {}

	var absolute_path := str(entry.get("absolute_path", "")).strip_edges()
	if absolute_path.is_empty() or not FileAccess.file_exists(absolute_path):
		return {}

	return {
		"resref": resref,
		"wav_path": absolute_path,
		"extension": str(entry.get("extension", "")),
		"source": str(entry.get("source", "")),
	}


static func _append_override_wav_candidates(
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
		if file_name.get_extension().to_lower() != "wav":
			continue
		var resref := file_name.get_basename()
		if resref.is_empty() or resref.ends_with("_clean") or seen.has(resref):
			continue
		if not normalized_query.is_empty() and not resref.to_lower().contains(normalized_query):
			continue
		seen[resref] = true
		candidates.append({
			"resref": resref,
			"wav_path": override_path.path_join(file_name),
			"extension": "wav",
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


static func _format_install_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch WAV convert: %d converted, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]


static func _format_folder_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch WAV import: %d imported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
