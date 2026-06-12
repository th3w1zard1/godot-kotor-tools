## resources/savegame_inspector_resource.gd
## Read-only snapshot of savegame inspection results.
@tool
extends Resource
class_name SavegameInspectorResource

const SavegameInspector := preload("../formats/savegame_inspector.gd")

@export var source_path: String = ""
@export var file_name: String = "savegame.sav"
@export var inspection: Dictionary = {}


static func from_bytes(
	bytes: PackedByteArray,
	source_path: String = "",
	file_name: String = "savegame.sav"
) -> SavegameInspectorResource:
	var resource: SavegameInspectorResource = load(
		"res://resources/savegame_inspector_resource.gd"
	).new()
	resource.source_path = source_path
	resource.file_name = file_name.get_file() if not file_name.is_empty() else "savegame.sav"
	resource.inspection = SavegameInspector.inspect_bytes(bytes)
	return resource


func is_valid() -> bool:
	return bool(inspection.get("ok", false))


func get_error() -> String:
	return str(inspection.get("error", ""))


func get_metadata() -> Dictionary:
	var metadata = inspection.get("metadata", {})
	return metadata if typeof(metadata) == TYPE_DICTIONARY else {}


func get_entry_summaries() -> Array:
	var entries = inspection.get("entries", [])
	return entries if typeof(entries) == TYPE_ARRAY else []


func get_summary_lines() -> Array[String]:
	if not is_valid():
		var lines_invalid: Array[String] = []
		var error_text := get_error()
		if not error_text.is_empty():
			lines_invalid.append(error_text)
		else:
			lines_invalid.append("Save inspection failed.")
		return lines_invalid

	var metadata := get_metadata()
	var lines: Array[String] = []
	var save_name := str(metadata.get("save_name", ""))
	if not save_name.is_empty():
		lines.append("Save: %s" % save_name)
	var last_module := str(metadata.get("last_module", ""))
	if not last_module.is_empty():
		lines.append("Module: %s" % last_module)
	var area_name := str(metadata.get("area_name", ""))
	if not area_name.is_empty():
		lines.append("Area: %s" % area_name)
	var time_label := str(metadata.get("time_played_label", ""))
	if not time_label.is_empty():
		lines.append("Time played: %s" % time_label)
	var pc_name := str(metadata.get("pc_name", ""))
	if not pc_name.is_empty():
		lines.append("PC: %s" % pc_name)
	var party_count := int(metadata.get("party_member_count", 0))
	if party_count > 0:
		lines.append("Party members: %d" % party_count)
	var global_count := int(metadata.get("global_variable_count", 0))
	if global_count > 0:
		lines.append("Global variables: %d" % global_count)
	lines.append("Archive members: %d" % int(inspection.get("entry_count", 0)))
	return lines


func build_summary_text() -> String:
	var lines := get_summary_lines()
	return "\n".join(lines)
