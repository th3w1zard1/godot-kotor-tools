## Batch MDL import from a flat filesystem folder into install override.
class_name MdlGamefsBatchImporter

const MdlBatchExporter := preload("mdl_batch_exporter.gd")
const MdlGamefsBatchExporter := preload("mdl_gamefs_batch_exporter.gd")


## Copy each `.mdl` in `source_dir` (and paired `.mdx` when present) into the install override folder.
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

	var result := MdlBatchExporter.batch_directory(source_dir, override_path, options)
	var generated: Array = result.get("generated", [])
	var skipped: Array = result.get("skipped", [])
	var failed: Array = result.get("failed", [])
	result["summary"] = _format_summary(generated.size(), skipped.size(), failed.size())
	return result


## Copy indexed `.mdl` resources (and paired `.mdx` when present) into override.
static func batch_install_to_override(
		gamefs: RefCounted,
		options: Dictionary = {}
) -> Dictionary:
	if gamefs == null:
		return {"ok": false, "message": "GameFS index is unavailable for batch import."}

	var override_path := _resolve_override_path(gamefs)
	if override_path.is_empty():
		return {"ok": false, "message": "Override folder is unavailable for batch import."}
	if not DirAccess.dir_exists_absolute(override_path):
		DirAccess.make_dir_recursive_absolute(override_path)

	var copy_options := options.duplicate()
	if not copy_options.has("source_filter"):
		copy_options["source_filter"] = ""

	var result := MdlGamefsBatchExporter.batch_install(gamefs, override_path, copy_options)
	var generated: Array = result.get("generated", [])
	var skipped: Array = result.get("skipped", [])
	var failed: Array = result.get("failed", [])
	result["summary"] = _format_install_copy_summary(
		generated.size(),
		skipped.size(),
		failed.size(),
	)
	return result


static func format_report(result: Dictionary) -> String:
	if result.has("scanned"):
		return MdlGamefsBatchExporter.format_report(result)
	return MdlBatchExporter.format_report(result)


static func _resolve_override_path(gamefs: RefCounted) -> String:
	if gamefs.has_method("ensure_override_path"):
		return str(gamefs.call("ensure_override_path")).strip_edges()
	if gamefs.has_method("get"):
		return str(gamefs.get("override_path")).strip_edges()
	return ""


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch MDL import: %d imported, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]


static func _format_install_copy_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Install batch MDL copy to override: %d copied, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
