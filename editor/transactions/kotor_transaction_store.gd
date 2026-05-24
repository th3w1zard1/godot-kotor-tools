@tool
extends RefCounted
class_name KotorTransactionStore

const TRANSACTIONS_SETTINGS_KEY := "kotor_tools/workspace/transaction_history"

var _transactions: Array[Dictionary] = []
var _next_id := 1
var _loaded := false


func record_transaction(entry: Dictionary) -> Dictionary:
	_ensure_loaded()
	var stored := entry.duplicate(true)
	if str(stored.get("id", "")).is_empty():
		stored["id"] = "tx-%04d" % _next_id
		_next_id += 1
	
	# Normalize transaction metadata with required fields for UI
	stored["timestamp"] = Time.get_ticks_msec()
	stored["status"] = stored.get("status", "applied")
	stored["restore_eligible"] = bool(stored.get("rollback_available", false)) and stored.get("action", "") != "noop"
	
	_transactions.append(stored)
	_persist_transactions()
	return stored.duplicate(true)


func get_transaction(transaction_id: String) -> Dictionary:
	_ensure_loaded()
	for entry in _transactions:
		if str(entry.get("id", "")) == transaction_id:
			return entry.duplicate(true)
	return {}


func list_transactions() -> Array[Dictionary]:
	_ensure_loaded()
	var results: Array[Dictionary] = []
	for entry in _transactions:
		results.append(entry.duplicate(true))
	return results


func get_transactions_for_session() -> Array[Dictionary]:
	_ensure_loaded()
	var results: Array[Dictionary] = []
	for entry in _transactions:
		var metadata := {
			"id": entry.get("id", ""),
			"kind": entry.get("kind", ""),
			"action": entry.get("action", ""),
			"target_path": entry.get("target_path", ""),
			"file_name": entry.get("file_name", ""),
			"rollback_available": entry.get("rollback_available", false),
			"rollback_mode": entry.get("rollback_mode", ""),
			"status": entry.get("status", ""),
			"restore_eligible": entry.get("restore_eligible", false),
			"timestamp": entry.get("timestamp", 0),
		}
		results.append(metadata)
	return results


func clear_transactions() -> void:
	_ensure_loaded()
	_transactions.clear()
	_next_id = 1
	_persist_transactions()


func _ensure_loaded() -> void:
	if _loaded:
		return
	_load_persisted_transactions()
	_loaded = true


func _persist_transactions() -> void:
	if not _is_editor_available():
		return
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings == null:
		return
	var session_data: Array[Dictionary] = []
	for entry in _transactions:
		var metadata := {
			"id": entry.get("id", ""),
			"kind": entry.get("kind", ""),
			"action": entry.get("action", ""),
			"target_path": entry.get("target_path", ""),
			"file_name": entry.get("file_name", ""),
			"rollback_available": entry.get("rollback_available", false),
			"rollback_mode": entry.get("rollback_mode", ""),
			"status": entry.get("status", "applied"),
			"restore_eligible": entry.get("restore_eligible", false),
			"timestamp": entry.get("timestamp", 0),
		}
		session_data.append(metadata)
	editor_settings.set_setting(TRANSACTIONS_SETTINGS_KEY, JSON.stringify(session_data))


func _load_persisted_transactions() -> void:
	if not _is_editor_available():
		return
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings == null:
		return
	var persisted_value: String = String(
		editor_settings.get_setting(TRANSACTIONS_SETTINGS_KEY) if editor_settings.has_setting(TRANSACTIONS_SETTINGS_KEY) else "[]"
	)
	var parsed = JSON.parse_string(persisted_value)
	if parsed is Array:
		for entry in parsed:
			if typeof(entry) == TYPE_DICTIONARY:
				var tx_entry: Dictionary = entry
				_transactions.append(tx_entry)
				var id_str := str(tx_entry.get("id", ""))
				if id_str.begins_with("tx-"):
					var num_str := id_str.substr(3)
					var num := num_str.to_int()
					if num >= _next_id:
						_next_id = num + 1


func _is_editor_available() -> bool:
	if not Engine.is_editor_hint():
		return false
	if EditorInterface.get_editor_settings() == null:
		return false
	return true
