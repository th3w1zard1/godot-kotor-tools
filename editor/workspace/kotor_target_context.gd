@tool
extends RefCounted
class_name KotorTargetContext

signal state_changed

const DEFAULT_RESULT_LIMIT := 256

var _editor_state: RefCounted
var _controller: RefCounted
var _index_state := "idle"
var _status_text := "No game path configured"


func setup(editor_state: RefCounted, controller: RefCounted = null) -> KotorTargetContext:
	_editor_state = editor_state
	_controller = controller
	_connect_editor_state()
	_refresh_state()
	return self


func get_index_state() -> String:
	return _index_state


func get_status_text() -> String:
	return _status_text


func has_ready_target() -> bool:
	return _index_state == "ready"


func list_resources(query: String = "", limit: int = DEFAULT_RESULT_LIMIT) -> Array[Dictionary]:
	return list_resources_filtered(query, "", limit)


func list_resources_filtered(
	query: String = "",
	resource_type: String = "",
	limit: int = DEFAULT_RESULT_LIMIT
) -> Array[Dictionary]:
	var gamefs := _resolve_gamefs()
	if gamefs == null:
		return []
	var type_filter: Variant = resource_type.strip_edges().to_lower() if not resource_type.is_empty() else null
	return gamefs.list_core_resources(query, type_filter, "", limit)


func list_variants(entry: Dictionary) -> Array[Dictionary]:
	var gamefs := _resolve_gamefs()
	if gamefs == null or entry.is_empty():
		return []
	if gamefs.has_method("list_resource_variants_for_entry"):
		return gamefs.call("list_resource_variants_for_entry", entry)
	return gamefs.list_resource_variants(
		str(entry.get("resref", "")),
		int(entry.get("resource_type", -1))
	)


func load_entry_bytes(entry: Dictionary) -> PackedByteArray:
	var gamefs := _resolve_gamefs()
	if gamefs == null or entry.is_empty():
		return PackedByteArray()
	return gamefs.load_resource_entry_bytes(entry)


func get_gamefs() -> RefCounted:
	return _resolve_gamefs()


func switch_target(path: String, allow_dirty_switch: bool = false) -> Dictionary:
	var blocked := _can_switch_target()
	if blocked.get("blocked", false) and not allow_dirty_switch:
		return blocked
	_index_state = "indexing"
	_status_text = "Indexing %s..." % path.get_file()
	state_changed.emit()
	if _editor_state != null and _editor_state.has_method("set_game_path"):
		_editor_state.call("set_game_path", path)
	_refresh_state()
	return {
		"ok": has_ready_target(),
		"state": _index_state,
		"status_text": _status_text,
	}


func _connect_editor_state() -> void:
	if _editor_state == null or not _editor_state.has_signal("gamefs_reindexed"):
		return
	var callback := Callable(self, "_on_editor_state_reindexed")
	if not _editor_state.gamefs_reindexed.is_connected(callback):
		_editor_state.gamefs_reindexed.connect(callback)


func _on_editor_state_reindexed(status_text: String) -> void:
	_status_text = status_text
	_refresh_state()
	state_changed.emit()


func _refresh_state() -> void:
	var gamefs := _resolve_gamefs()
	if _editor_state == null:
		_index_state = "error"
		_status_text = "No editor state available"
		return
	if not _editor_state.has_method("has_valid_game_path") or not _editor_state.call("has_valid_game_path"):
		_index_state = "error"
		_status_text = "No valid target configured"
		return
	if gamefs != null and gamefs.has_method("has_indexed_resources") and gamefs.call("has_indexed_resources"):
		_index_state = "ready"
		_status_text = _editor_state.call("get_game_path_status")
		return
	_index_state = "error"
	_status_text = _editor_state.call("get_game_path_status") if _editor_state.has_method("get_game_path_status") else "Target index is unavailable"


func _resolve_gamefs() -> RefCounted:
	if _editor_state == null:
		return null
	var gamefs = _editor_state.get("gamefs")
	return gamefs as RefCounted


func _can_switch_target() -> Dictionary:
	if _controller == null:
		return {"ok": true, "blocked": false}
	var registry = _controller.get("document_registry")
	if registry == null or not registry.has_method("get_active_document_entry"):
		return {"ok": true, "blocked": false}
	var active_entry: Dictionary = registry.call("get_active_document_entry")
	if bool(active_entry.get("dirty", false)):
		return {
			"ok": false,
			"blocked": true,
			"message": "Resolve dirty workspace documents before switching targets.",
			"actions": ["save", "export", "install", "discard", "cancel"],
		}
	return {"ok": true, "blocked": false}
