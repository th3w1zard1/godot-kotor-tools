@tool
extends RefCounted
class_name KotorDocumentRegistry

const GFFResource := preload("../../resources/gff_resource.gd")

const BLOCKED_ACTIONS := ["save", "export", "install", "discard", "cancel"]

var _documents: Dictionary = {}
var _active_key := ""


func register_document(
		editor_kind: String,
		resource: Variant,
		document: Variant,
		source_path: String = "",
		file_name: String = "",
		selection: Dictionary = {}
) -> Dictionary:
	var key := _build_key(editor_kind, source_path, file_name)
	var entry: Dictionary = _documents.get(key, {})
	if entry.is_empty():
		entry = {
			"key": key,
			"editor_kind": editor_kind,
			"dirty": false,
			"stale": false,
			"stale_reason": "",
			"missing_source": false,
			"selection": {},
			"snapshot": _snapshot_resource(resource),
		}
	entry["resource"] = resource
	entry["document"] = document
	entry["editor_kind"] = editor_kind
	entry["source_path"] = source_path if source_path.is_absolute_path() else ""
	entry["file_name"] = file_name.get_file() if not file_name.is_empty() else key
	entry["title"] = entry["file_name"]
	if not selection.is_empty():
		entry["selection"] = selection.duplicate(true)
	_documents[key] = entry
	return entry.duplicate(true)


func register_missing_entry(entry: Dictionary) -> void:
	var key := str(entry.get("key", ""))
	if key.is_empty():
		key = _build_key(
			str(entry.get("editor_kind", "")),
			str(entry.get("source_path", "")),
			str(entry.get("file_name", ""))
		)
	entry["key"] = key
	entry["missing_source"] = true
	entry["dirty"] = bool(entry.get("dirty", false))
	entry["stale"] = bool(entry.get("stale", false))
	entry["stale_reason"] = str(entry.get("stale_reason", ""))
	_documents[key] = entry.duplicate(true)


func list_documents(editor_kind: String = "") -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var keys: Array[String] = []
	for key in _documents.keys():
		keys.append(str(key))
	keys.sort()
	for key in keys:
		var entry: Dictionary = _documents.get(key, {})
		if not editor_kind.is_empty() and str(entry.get("editor_kind", "")) != editor_kind:
			continue
		results.append(entry.duplicate(true))
	return results


func get_document_entry(key: String) -> Dictionary:
	return (_documents.get(key, {}) as Dictionary).duplicate(true)


func remove_document(key: String) -> void:
	if not _documents.has(key):
		return
	_documents.erase(key)
	if _active_key == key:
		_active_key = ""


func get_document_resource(key: String):
	var entry: Dictionary = _documents.get(key, {})
	return entry.get("resource", null)


func get_document_object(key: String):
	var entry: Dictionary = _documents.get(key, {})
	return entry.get("document", null)


func get_active_document_key() -> String:
	return _active_key


func get_active_document_entry() -> Dictionary:
	return get_document_entry(_active_key)


func can_activate_document(key: String) -> Dictionary:
	if key == _active_key or _active_key.is_empty():
		return {"ok": true, "blocked": false}
	var current: Dictionary = _documents.get(_active_key, {})
	if bool(current.get("dirty", false)):
		return {
			"ok": false,
			"blocked": true,
			"message": "Save, export, install, or discard the active document before switching.",
			"actions": BLOCKED_ACTIONS.duplicate(),
			"active_key": _active_key,
			"target_key": key,
		}
	return {"ok": true, "blocked": false}


func activate_document(key: String, allow_dirty_switch: bool = false) -> Dictionary:
	if not _documents.has(key):
		return {"ok": false, "blocked": false, "message": "Unknown document %s" % key}
	var check := can_activate_document(key)
	if check.get("blocked", false) and not allow_dirty_switch:
		return check
	_active_key = key
	return {"ok": true, "blocked": false, "entry": get_document_entry(key)}


func update_dirty(key: String, dirty: bool) -> void:
	if not _documents.has(key):
		return
	var entry: Dictionary = _documents.get(key, {})
	entry["dirty"] = dirty
	_documents[key] = entry


func update_selection(key: String, selection: Dictionary) -> void:
	if not _documents.has(key):
		return
	var entry: Dictionary = _documents.get(key, {})
	entry["selection"] = selection.duplicate(true)
	_documents[key] = entry


func mark_stale(key: String, reason: String) -> void:
	if not _documents.has(key):
		return
	var entry: Dictionary = _documents.get(key, {})
	entry["stale"] = true
	entry["stale_reason"] = reason
	_documents[key] = entry


func clear_stale(key: String) -> void:
	if not _documents.has(key):
		return
	var entry: Dictionary = _documents.get(key, {})
	entry["stale"] = false
	entry["stale_reason"] = ""
	_documents[key] = entry


func mark_missing_source(key: String) -> void:
	if not _documents.has(key):
		return
	var entry: Dictionary = _documents.get(key, {})
	entry["missing_source"] = true
	_documents[key] = entry


func discard_document(key: String) -> Dictionary:
	if not _documents.has(key):
		return {"ok": false, "message": "Unknown document %s" % key}
	var entry: Dictionary = _documents.get(key, {})
	var snapshot: Dictionary = entry.get("snapshot", {})
	if snapshot.is_empty():
		return {"ok": false, "message": "No discard snapshot is available for %s" % key}
	var script = snapshot.get("resource_script", null)
	if script == null:
		return {"ok": false, "message": "No resource script is available for %s" % key}
	var resource = script.new()
	if resource.has_method("setup_from_parser_result"):
		resource.call("setup_from_parser_result", {
			"file_type": snapshot.get("file_type", ""),
			"root": (snapshot.get("gff_data", {}) as Dictionary).duplicate(true),
			"schema": (snapshot.get("schema_data", {}) as Dictionary).duplicate(true),
		})
	var document = resource.call("create_document") if resource.has_method("create_document") else null
	entry["resource"] = resource
	entry["document"] = document
	entry["dirty"] = false
	entry["stale"] = false
	entry["stale_reason"] = ""
	entry["missing_source"] = false
	_documents[key] = entry
	return {
		"ok": true,
		"entry": entry.duplicate(true),
		"resource": resource,
		"document": document,
	}


func build_session_entries() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for entry in list_documents():
		results.append({
			"key": str(entry.get("key", "")),
			"editor_kind": str(entry.get("editor_kind", "")),
			"source_path": str(entry.get("source_path", "")),
			"file_name": str(entry.get("file_name", "")),
			"selection": (entry.get("selection", {}) as Dictionary).duplicate(true),
			"dirty": bool(entry.get("dirty", false)),
			"stale": bool(entry.get("stale", false)),
			"stale_reason": str(entry.get("stale_reason", "")),
			"missing_source": bool(entry.get("missing_source", false)),
		})
	return results


func _build_key(editor_kind: String, source_path: String, file_name: String) -> String:
	if source_path.is_absolute_path():
		return "%s:%s" % [editor_kind, source_path]
	return "%s:%s" % [editor_kind, file_name.get_file() if not file_name.is_empty() else "untitled"]


func _snapshot_resource(resource: Variant) -> Dictionary:
	if resource == null:
		return {}
	if not resource is GFFResource:
		return {}
	var gff_resource := resource as GFFResource
	return {
		"resource_script": gff_resource.get_script(),
		"file_type": gff_resource.file_type,
		"gff_data": gff_resource.gff_data.duplicate(true),
		"schema_data": gff_resource.schema_data.duplicate(true),
	}
