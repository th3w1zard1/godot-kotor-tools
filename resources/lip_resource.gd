## Lip-sync animation resource — duration and viseme keyframes.
@tool
extends Resource
class_name LIPResource

const LIPParser := preload("../formats/lip_parser.gd")

@export var length: float = 0.0
@export var keyframes: Array = []


func reset_to_defaults() -> void:
	length = 0.0
	keyframes = []


func apply_parser_result(parsed: Dictionary) -> void:
	reset_to_defaults()
	length = maxf(0.0, float(parsed.get("length", 0.0)))
	var loaded: Variant = parsed.get("keyframes", [])
	if typeof(loaded) != TYPE_ARRAY:
		return
	for entry in loaded:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var time := maxf(0.0, float(entry.get("time", 0.0)))
		var shape := clampi(int(entry.get("shape", 0)), 0, LIPParser.SHAPE_COUNT - 1)
		keyframes.append({"time": time, "shape": shape})
	sort_keyframes()


func to_parser_result() -> Dictionary:
	var copy: Array = []
	for entry in keyframes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		copy.append({
			"time": float(entry.get("time", 0.0)),
			"shape": clampi(int(entry.get("shape", 0)), 0, LIPParser.SHAPE_COUNT - 1),
		})
	return {"length": length, "keyframes": copy}


func sort_keyframes() -> void:
	LIPParser.sort_keyframes_array(keyframes)


func get_keyframe_count() -> int:
	return keyframes.size()


func get_keyframe(index: int) -> Dictionary:
	if index < 0 or index >= keyframes.size():
		return {}
	var entry: Variant = keyframes[index]
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	return entry


func set_keyframe(index: int, time: float, shape: int) -> bool:
	if index < 0:
		return false
	while keyframes.size() <= index:
		keyframes.append({"time": 0.0, "shape": 0})
	var normalized_shape := clampi(shape, 0, LIPParser.SHAPE_COUNT - 1)
	var normalized_time := maxf(0.0, time)
	var current: Dictionary = keyframes[index]
	if float(current.get("time", -1.0)) == normalized_time and int(current.get("shape", -1)) == normalized_shape:
		return false
	keyframes[index] = {"time": normalized_time, "shape": normalized_shape}
	sort_keyframes()
	emit_changed()
	return true


func add_keyframe(time: float, shape: int) -> void:
	keyframes.append({
		"time": maxf(0.0, time),
		"shape": clampi(shape, 0, LIPParser.SHAPE_COUNT - 1),
	})
	sort_keyframes()
	emit_changed()


func remove_keyframe_at(index: int) -> bool:
	if index < 0 or index >= keyframes.size():
		return false
	keyframes.remove_at(index)
	emit_changed()
	return true


func set_length(value: float) -> bool:
	var normalized := maxf(0.0, value)
	if is_equal_approx(length, normalized):
		return false
	length = normalized
	emit_changed()
	return true
