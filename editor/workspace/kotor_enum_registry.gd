@tool
extends RefCounted
class_name KotorEnumRegistry

const TwoDaParser := preload("../../formats/twoda_parser.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")

const FIELD_TO_2DA := {
	"Gender": "gender",
	"Race": "racialtypes",
	"Appearance_Type": "appearance",
}

const LABEL_COLUMNS := ["label", "string", "name", "text"]

var _editor_state: RefCounted
var _cache: Dictionary = {}


func configure(editor_state: RefCounted) -> KotorEnumRegistry:
	_editor_state = editor_state
	if _editor_state != null and _editor_state.has_signal("gamefs_reindexed"):
		if not _editor_state.gamefs_reindexed.is_connected(_on_gamefs_reindexed):
			_editor_state.gamefs_reindexed.connect(_on_gamefs_reindexed)
	return self


func clear_cache() -> void:
	_cache.clear()


func get_enum_values(field_name: String) -> Dictionary:
	if _cache.has(field_name):
		return _cache[field_name].get("values", {})

	var from_2da := _load_from_2da(field_name)
	if not from_2da.is_empty():
		_cache[field_name] = {"source": "2da", "values": from_2da}
		return from_2da

	var static_values: Dictionary = TypedFieldHelpers.ENUM_FIELD_MAPPING.get(field_name, {})
	_cache[field_name] = {"source": "static", "values": static_values}
	return static_values


func get_enum_source(field_name: String) -> String:
	get_enum_values(field_name)
	if _cache.has(field_name):
		return str(_cache[field_name].get("source", "none"))
	return "none"


func has_enum_hints(field_name: String) -> bool:
	return not get_enum_values(field_name).is_empty()


func _on_gamefs_reindexed(_status_text: String) -> void:
	clear_cache()


func _load_from_2da(field_name: String) -> Dictionary:
	var table_resref := String(FIELD_TO_2DA.get(field_name, ""))
	if table_resref.is_empty():
		return {}

	var gamefs := _resolve_gamefs()
	if gamefs == null:
		return {}

	var entry: Dictionary = gamefs.call("resolve_resource", table_resref, "2da")
	if entry.is_empty():
		return {}

	var bytes: PackedByteArray = gamefs.call("load_resource_entry_bytes", entry)
	if bytes.is_empty():
		return {}

	var parsed := TwoDaParser.parse_bytes(bytes)
	return _rows_to_enum(parsed)


func _rows_to_enum(parsed: Dictionary) -> Dictionary:
	var result := {}
	var rows: Array = parsed.get("rows", [])
	var columns = parsed.get("columns", PackedStringArray())
	var label_col := _find_label_column(columns)
	for i in rows.size():
		var row: Dictionary = rows[i] if typeof(rows[i]) == TYPE_DICTIONARY else {}
		var label := str(row.get(label_col, "")).strip_edges()
		if label.is_empty():
			label = "Row %d" % i
		result[i] = label
	return result


func _find_label_column(columns) -> String:
	if typeof(columns) == TYPE_PACKED_STRING_ARRAY:
		for candidate in LABEL_COLUMNS:
			if columns.has(candidate):
				return candidate
		if columns.size() > 0:
			return columns[0]
	return "label"


func _resolve_gamefs() -> RefCounted:
	if _editor_state == null:
		return null
	var gamefs = _editor_state.get("gamefs")
	return gamefs as RefCounted
