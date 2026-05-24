@tool
extends RefCounted
class_name KotorWorkspaceSession

const OPEN_DOCUMENTS_KEY := "kotor_tools/workspace/open_documents"
const ACTIVE_DOCUMENT_KEY := "kotor_tools/workspace/active_document"


func save_registry(registry: RefCounted) -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings == null or registry == null:
		return
	var entries: Array = registry.call("build_session_entries")
	editor_settings.set_setting(OPEN_DOCUMENTS_KEY, JSON.stringify(entries))
	editor_settings.set_setting(ACTIVE_DOCUMENT_KEY, String(registry.call("get_active_document_key")))


func load_state() -> Dictionary:
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings == null:
		return {"documents": [], "active_key": ""}
	var documents_value: String = String(
		editor_settings.get_setting(OPEN_DOCUMENTS_KEY) if editor_settings.has_setting(OPEN_DOCUMENTS_KEY) else "[]"
	)
	var active_key: String = String(
		editor_settings.get_setting(ACTIVE_DOCUMENT_KEY) if editor_settings.has_setting(ACTIVE_DOCUMENT_KEY) else ""
	)
	var parsed = JSON.parse_string(String(documents_value))
	var documents: Array[Dictionary] = []
	if parsed is Array:
		for entry in parsed:
			if typeof(entry) == TYPE_DICTIONARY:
				var document_entry: Dictionary = entry
				if not String(document_entry.get("source_path", "")).is_empty():
					document_entry["missing_source"] = not FileAccess.file_exists(String(document_entry.get("source_path", "")))
				documents.append(document_entry)
	return {
		"documents": documents,
		"active_key": String(active_key),
	}


func clear_state() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings == null:
		return
	editor_settings.set_setting(OPEN_DOCUMENTS_KEY, "[]")
	editor_settings.set_setting(ACTIVE_DOCUMENT_KEY, "")
