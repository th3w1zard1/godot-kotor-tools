@tool
extends RefCounted
class_name KotorTLKDocument

signal changed

const TLKResource := preload("../tlk_resource.gd")

const SEARCH_RESULT_LIMIT := 200

var _resource: TLKResource


func setup(resource: TLKResource) -> KotorTLKDocument:
	_resource = resource
	return self


func get_resource() -> TLKResource:
	return _resource


func entry_count() -> int:
	return _resource.entries.size() if _resource != null else 0


func get_entry(strref: int) -> Dictionary:
	if _resource == null:
		return {}
	return _resource.get_entry(strref)


func set_entry_text(strref: int, text: String) -> bool:
	if _resource == null:
		return false
	if not _resource.set_entry_text(strref, text):
		return false
	changed.emit()
	return true


func search(query: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if _resource == null:
		return results
	var normalized := query.strip_edges()
	if normalized.is_empty():
		return results
	if normalized.is_valid_int():
		var strref := normalized.to_int()
		var entry := _resource.get_entry(strref)
		if not entry.is_empty():
			results.append(entry)
		return results
	var lower_query := normalized.to_lower()
	for entry: Dictionary in _resource.entries:
		var text := String(entry.get("text", ""))
		if text.to_lower().contains(lower_query):
			results.append(entry.duplicate(true))
			if results.size() >= SEARCH_RESULT_LIMIT:
				break
	return results


func build_summary_text() -> String:
	if _resource == null:
		return "No TLK loaded."
	return "TLK Talk Table\nStrings: %d\nLanguage ID: %d" % [
		_resource.entries.size(),
		_resource.language_id,
	]


func validate() -> Array[String]:
	var issues: Array[String] = []
	if _resource == null:
		issues.append("No TLK resource is loaded.")
		return issues
	for index in range(_resource.entries.size()):
		var entry: Dictionary = _resource.entries[index]
		if int(entry.get("strref", index)) != index:
			issues.append("Entry %d reports mismatched StrRef %s." % [index, entry.get("strref", index)])
	return issues


func build_validation_report() -> String:
	var issues := validate()
	if issues.is_empty():
		return "TLK validation passed.\n- StrRef ordering is contiguous."
	return "TLK validation issues:\n- %s" % "\n- ".join(issues)
