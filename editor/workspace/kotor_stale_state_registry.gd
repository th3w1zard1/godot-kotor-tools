@tool
extends RefCounted
class_name KotorStaleStateRegistry

var _stale_reasons: Dictionary = {}


func mark_stale(key: String, reason: String = "") -> void:
	if key.is_empty():
		return
	_stale_reasons[key] = reason


func clear_stale(key: String) -> void:
	_stale_reasons.erase(key)


func clear_all() -> void:
	_stale_reasons.clear()


func is_stale(key: String) -> bool:
	return _stale_reasons.has(key)


func get_reason(key: String) -> String:
	return str(_stale_reasons.get(key, ""))


func snapshot() -> Dictionary:
	return _stale_reasons.duplicate(true)
