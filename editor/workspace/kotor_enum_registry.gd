@tool
extends RefCounted
class_name KotorEnumRegistry

const TwoDaParser := preload("../../formats/twoda_parser.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")

const FIELD_TO_2DA := {
	"Gender": "gender",
	"Race": "racialtypes",
	"Appearance_Type": "appearance",
	"Feat": "feat",
}

const LABEL_COLUMNS := ["label", "string", "name", "text"]

var _editor_state_ref: WeakRef
var _cache: Dictionary = {}


func configure(editor_state: RefCounted) -> KotorEnumRegistry:
	var previous_state := _resolve_editor_state()
	if previous_state != null and previous_state.has_signal("gamefs_reindexed"):
		if previous_state.gamefs_reindexed.is_connected(_on_gamefs_reindexed):
			previous_state.gamefs_reindexed.disconnect(_on_gamefs_reindexed)

	_editor_state_ref = weakref(editor_state)
	var current_state := _resolve_editor_state()
	if current_state != null and current_state.has_signal("gamefs_reindexed"):
		if not current_state.gamefs_reindexed.is_connected(_on_gamefs_reindexed):
			current_state.gamefs_reindexed.connect(_on_gamefs_reindexed)
	return self


func clear_cache() -> void:
	_cache.clear()


func cache_size() -> int:
	return _cache.size()


func has_cached_entries() -> bool:
	return not _cache.is_empty()


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


func get_skill_label(skill_index: int) -> String:
	return get_table_row_label("skills", skill_index)


func get_table_row_label(table_resref: String, row_index: int) -> String:
	var values := _load_table_values(table_resref)
	if values.has(row_index):
		return str(values[row_index])
	return ""


func _load_table_values(table_resref: String) -> Dictionary:
	var cache_key := "__table:%s" % table_resref
	if _cache.has(cache_key):
		return _cache[cache_key].get("values", {})
	var from_2da := _load_rows_from_table(table_resref)
	if from_2da.is_empty():
		return {}
	_cache[cache_key] = {"source": "2da", "values": from_2da}
	return from_2da


func _load_from_2da(field_name: String) -> Dictionary:
	var table_resref := String(FIELD_TO_2DA.get(field_name, ""))
	if table_resref.is_empty():
		return {}
	return _load_table_values(table_resref)


func _load_rows_from_table(table_resref: String) -> Dictionary:
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
		var row_index := int(row.get("__row_index", i))
		var label := str(row.get(label_col, "")).strip_edges()
		if label.is_empty():
			label = "Row %d" % row_index
		result[row_index] = label
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
	var editor_state := _resolve_editor_state()
	if editor_state == null:
		return null
	var gamefs = editor_state.get("gamefs")
	return gamefs as RefCounted


func _resolve_editor_state() -> RefCounted:
	if _editor_state_ref == null:
		return null
	return _editor_state_ref.get_ref() as RefCounted
