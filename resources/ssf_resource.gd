## Creature sound set resource — 28 TLK StrRef slots.
@tool
extends Resource
class_name SSFResource

const SSFParser := preload("../formats/ssf_parser.gd")

@export var strrefs: Array[int] = []


func _init() -> void:
	reset_to_defaults()


func reset_to_defaults() -> void:
	strrefs.clear()
	strrefs.resize(SSFParser.SLOT_COUNT)
	for index in SSFParser.SLOT_COUNT:
		strrefs[index] = -1


func apply_parser_result(parsed: Dictionary) -> void:
	reset_to_defaults()
	var loaded: Variant = parsed.get("strrefs", [])
	if typeof(loaded) != TYPE_ARRAY:
		return
	for index in mini(loaded.size(), SSFParser.SLOT_COUNT):
		strrefs[index] = int(loaded[index])


func to_parser_result() -> Dictionary:
	var copy: Array[int] = []
	copy.resize(SSFParser.SLOT_COUNT)
	for index in SSFParser.SLOT_COUNT:
		copy[index] = get_strref(index)
	return {"strrefs": copy}


func get_strref(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= strrefs.size():
		return -1
	return int(strrefs[slot_index])


func set_strref(slot_index: int, value: int) -> bool:
	if slot_index < 0 or slot_index >= SSFParser.SLOT_COUNT:
		return false
	while strrefs.size() < SSFParser.SLOT_COUNT:
		strrefs.append(-1)
	var normalized := -1 if value < 0 else value
	if strrefs[slot_index] == normalized:
		return false
	strrefs[slot_index] = normalized
	emit_changed()
	return true
