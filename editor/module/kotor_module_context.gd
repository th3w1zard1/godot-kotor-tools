@tool
extends RefCounted
class_name KotorModuleContext

const MODULE_EXTENSIONS := ["git", "are", "ifo"]


static func module_resref_from_file_name(file_name: String) -> String:
	var base := file_name.get_file().get_basename().strip_edges().to_lower()
	return base


static func find_module_bundle(gamefs: RefCounted, module_resref: String) -> Dictionary:
	var normalized := module_resref.strip_edges().to_lower()
	if normalized.is_empty() or gamefs == null:
		return {}
	var bundle := {
		"module_resref": normalized,
		"git": {},
		"are": {},
		"ifo": {},
	}
	if not gamefs.has_method("list_core_resources"):
		return bundle
	var entries: Array = gamefs.list_core_resources(normalized, null, "", 512)
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		if str(entry.get("resref", "")).strip_edges().to_lower() != normalized:
			continue
		var extension := str(entry.get("extension", "")).strip_edges().to_lower()
		if extension in MODULE_EXTENSIONS and bundle.get(extension, {}).is_empty():
			bundle[extension] = entry.duplicate(true)
	return bundle


static func describe_bundle(bundle: Dictionary) -> String:
	if bundle.is_empty():
		return "No module bundle"
	var parts: Array[String] = []
	for extension in MODULE_EXTENSIONS:
		var entry: Dictionary = bundle.get(extension, {})
		if entry.is_empty():
			parts.append("%s: missing" % extension.to_upper())
		else:
			parts.append("%s: %s" % [extension.to_upper(), entry.get("source", "indexed")])
	return " · ".join(parts)
