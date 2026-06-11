## Batch WAV sound-convert import from a flat filesystem folder into install override.
class_name WavGamefsBatchImporter

const WavBatchConverter := preload("wav_batch_converter.gd")


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
	result["summary"] = _format_summary(generated.size(), skipped.size(), failed.size())
	return result


static func format_report(result: Dictionary) -> String:
	return WavBatchConverter.format_report(result)


static func _resolve_override_path(gamefs: RefCounted) -> String:
	if gamefs.has_method("ensure_override_path"):
		return str(gamefs.call("ensure_override_path")).strip_edges()
	if gamefs.has_method("get"):
		return str(gamefs.get("override_path")).strip_edges()
	return ""


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch WAV import: %d imported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
