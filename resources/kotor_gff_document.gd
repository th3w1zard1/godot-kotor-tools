@tool
extends RefCounted
class_name KotorGFFDocument

const TypedFieldHelpers := preload("../ui/workspace/typed_field_helpers.gd")

signal changed

const TYPE_LABELS := {
	"ARE": "Area Properties",
	"DLG": "Dialogue",
	"GFF": "Generic GFF",
	"GIT": "Area Layout",
	"IFO": "Module Info",
	"JRL": "Journal",
	"UTC": "Creature Blueprint",
	"UTD": "Door Blueprint",
	"UTE": "Encounter Blueprint",
	"UTI": "Item Blueprint",
	"UTM": "Merchant Blueprint",
	"UTP": "Placeable Blueprint",
	"UTS": "Sound Blueprint",
	"UTT": "Trigger Blueprint",
	"UTW": "Waypoint Blueprint",
}

const SCRIPT_HOOK_FIELDS_BY_TYPE := {
	"UTT": [
		"OnClick",
		"OnDisarm",
		"OnEnter",
		"OnExit",
		"OnHeartbeat",
		"OnUserDefined",
		"OnTrapTriggered",
	],
	"UTD": [
		"OnClick",
		"OnClosed",
		"OnDamaged",
		"OnDeath",
		"OnDisarm",
		"OnHeartbeat",
		"OnLock",
		"OnMeleeAttacked",
		"OnOpen",
		"OnSpellCastAt",
		"OnTrapTriggered",
		"OnUnlock",
		"OnUserDefined",
	],
	"UTP": [
		"OnClick",
		"OnClosed",
		"OnDamaged",
		"OnDeath",
		"OnDisarm",
		"OnHeartbeat",
		"OnLock",
		"OnMeleeAttacked",
		"OnOpen",
		"OnSpellCastAt",
		"OnTrapTriggered",
		"OnUnlock",
		"OnUserDefined",
	],
	"UTC": [
		"ScriptAttacked",
		"ScriptDamaged",
		"ScriptDeath",
		"ScriptDialogue",
		"ScriptDisturbed",
		"ScriptEndDialogu",
		"ScriptEndRound",
		"ScriptHeartbeat",
		"ScriptOnBlocked",
		"ScriptOnNotice",
		"ScriptRested",
		"ScriptSpawn",
		"ScriptSpellAt",
		"ScriptUserDefine",
	],
	"ARE": [
		"OnEnter",
		"OnExit",
		"OnHeartbeat",
		"OnUserDefined",
	],
}

const SCRIPT_FIELD_ALIASES := {
	"OnEnter": "ScriptOnEnter",
	"OnExit": "ScriptOnExit",
	"OnHeartbeat": "ScriptHeartbeat",
	"OnUserDefined": "ScriptUserDefine",
}

const TRAP_SCALAR_FIELDS := [
	"TrapFlag",
	"TrapType",
	"TrapOneShot",
	"TrapDetectable",
	"TrapDetectDC",
	"TrapDisarmable",
	"DisarmDC",
	"KeyName",
]

var file_type: String = ""
var _root: Dictionary = {}
var _owner_resource_ref: WeakRef


func setup(new_file_type: String, root: Dictionary, owner_resource: Resource = null) -> KotorGFFDocument:
	file_type = new_file_type.strip_edges().to_upper()
	_root = root if root != null else {}
	_owner_resource_ref = weakref(owner_resource) if owner_resource != null else null
	return self


func get_root() -> Dictionary:
	return _root


func has_field(name: String) -> bool:
	return _root.has(name)


func get_field(name: String, default_value: Variant = null) -> Variant:
	return _root.get(name, default_value)


func get_string(name: String, default_value: String = "") -> String:
	var value = get_field(name, default_value)
	if value == null:
		return default_value
	return String(value)


func get_int(name: String, default_value: int = 0) -> int:
	return int(get_field(name, default_value))


func get_float(name: String, default_value: float = 0.0) -> float:
	return float(get_field(name, default_value))


func get_bool(name: String, default_value: bool = false) -> bool:
	return bool(get_field(name, 1 if default_value else 0))


func get_resref(name: String, default_value: String = "") -> String:
	return get_string(name, default_value).strip_edges()


func get_struct(name: String) -> Dictionary:
	var value = get_field(name, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func get_struct_list(name: String) -> Array[Dictionary]:
	var value = get_field(name, [])
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) == TYPE_DICTIONARY:
			result.append(entry)
	return result


func get_locstring(name: String) -> Dictionary:
	var value = get_field(name, {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	if not value.has("strref") or not value.has("strings"):
		return {}
	return value


func get_locstring_text(name: String, default_value: String = "") -> String:
	return describe_locstring(get_locstring(name), default_value)


func set_field(name: String, value: Variant) -> bool:
	if _root.get(name, null) == value:
		return false
	_root[name] = value
	_notify_changed()
	return true


func get_field_at_path(path: Array) -> Variant:
	var current: Variant = _root
	for segment in path:
		if typeof(current) == TYPE_DICTIONARY:
			if not current.has(segment):
				return null
			current = current[segment]
		elif typeof(current) == TYPE_ARRAY and typeof(segment) == TYPE_INT:
			var list := current as Array
			if segment < 0 or segment >= list.size():
				return null
			current = list[segment]
		else:
			return null
	return current


func set_field_at_path(path: Array, value: Variant) -> bool:
	if path.is_empty():
		return false
	var parent_path: Array = path.slice(0, path.size() - 1)
	var key: Variant = path[path.size() - 1]
	var parent: Variant = _root if parent_path.is_empty() else get_field_at_path(parent_path)
	if typeof(parent) == TYPE_DICTIONARY:
		if not parent.has(key):
			return false
		if parent.get(key) == value:
			return false
		parent[key] = value
		_notify_changed()
		return true
	if typeof(parent) == TYPE_ARRAY and typeof(key) == TYPE_INT:
		var list := parent as Array
		var index := key as int
		if index < 0 or index >= list.size():
			return false
		if list[index] == value:
			return false
		list[index] = value
		_notify_changed()
		return true
	return false


func insert_struct_at_array(array_field_name: String, index: int, struct_value: Dictionary) -> bool:
	if not _root.has(array_field_name):
		return false
	var array = _root[array_field_name]
	if typeof(array) != TYPE_ARRAY:
		return false
	var arr := array as Array
	if index < 0 or index > arr.size():
		return false
	arr.insert(index, struct_value)
	_notify_changed()
	return true


func remove_struct_from_array(array_field_name: String, index: int) -> bool:
	if not _root.has(array_field_name):
		return false
	var array = _root[array_field_name]
	if typeof(array) != TYPE_ARRAY:
		return false
	var arr := array as Array
	if index < 0 or index >= arr.size():
		return false
	arr.remove_at(index)
	_notify_changed()
	return true


func reorder_array_item(array_field_name: String, from_index: int, to_index: int) -> bool:
	if not _root.has(array_field_name):
		return false
	var array = _root[array_field_name]
	if typeof(array) != TYPE_ARRAY:
		return false
	var arr := array as Array
	if from_index < 0 or from_index >= arr.size() or to_index < 0 or to_index >= arr.size():
		return false
	if from_index == to_index:
		return false
	var item = arr[from_index]
	arr.remove_at(from_index)
	arr.insert(to_index, item)
	_notify_changed()
	return true


func coerce_scalar_edit_text(text: String, current: Variant) -> Variant:
	match typeof(current):
		TYPE_INT:
			var stripped := text.strip_edges()
			return int(stripped) if stripped.is_valid_int() else current
		TYPE_FLOAT:
			var stripped_float := text.strip_edges()
			return float(stripped_float) if stripped_float.is_valid_float() else current
		TYPE_BOOL:
			var normalized := text.strip_edges().to_lower()
			if normalized in ["true", "1", "yes"]:
				return true
			if normalized in ["false", "0", "no"]:
				return false
			return current
		_:
			return text.strip_edges()


func set_string(name: String, value: String) -> bool:
	return set_field(name, value)


func set_int(name: String, value: int) -> bool:
	return set_field(name, value)


func set_bool(name: String, value: bool) -> bool:
	return set_field(name, 1 if value else 0)


func set_locstring_text(name: String, text: String, language_id: int = 0) -> bool:
	var locstring := get_locstring(name)
	if locstring.is_empty():
		locstring = {
			"strref": 0xFFFFFFFF,
			"strings": {},
		}
	var strings: Dictionary = locstring.get("strings", {})
	var normalized := text.strip_edges()
	if normalized.is_empty():
		strings.erase(language_id)
	else:
		if String(strings.get(language_id, "")) == normalized:
			return false
		strings[language_id] = normalized
	locstring["strings"] = strings
	return set_field(name, locstring)


func validate_resref(text: String) -> String:
	var trimmed := text.strip_edges()
	const MAX_RESREF_LENGTH := 16
	if trimmed.length() <= MAX_RESREF_LENGTH:
		return trimmed
	return trimmed.substr(0, MAX_RESREF_LENGTH)


func get_type_label() -> String:
	return TYPE_LABELS.get(file_type, "%s Resource" % file_type if not file_type.is_empty() else "GFF Resource")


func get_display_name() -> String:
	var title := get_locstring_text("LocName")
	if title.is_empty():
		title = get_locstring_text("Name")
	if title.is_empty():
		title = get_locstring_text("Mod_Name")
	if title.is_empty():
		title = get_string("Tag")
	if title.is_empty():
		title = get_resref("TemplateResRef")
	return title if not title.is_empty() else get_type_label()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_locstring_text("LocName"))
	_append_summary_line(lines, "Tag", get_string("Tag"))
	_append_summary_line(lines, "Template", get_resref("TemplateResRef"))
	return lines


func build_summary_text() -> String:
	var lines := get_summary_lines()
	return "\n".join(lines)


func mark_changed() -> void:
	_notify_changed()


static func describe_locstring(locstring: Dictionary, default_value: String = "") -> String:
	if locstring.is_empty():
		return default_value
	var strings = locstring.get("strings", {})
	if typeof(strings) == TYPE_DICTIONARY:
		if strings.has(0):
			var english := String(strings.get(0, "")).strip_edges()
			if not english.is_empty():
				return english
		for language_id in strings.keys():
			var text := String(strings.get(language_id, "")).strip_edges()
			if not text.is_empty():
				return text
	var strref := int(locstring.get("strref", 0xFFFFFFFF))
	if strref >= 0 and strref != 0xFFFFFFFF:
		return "StrRef %d" % strref
	return default_value


static func join_non_empty(parts: Array[String], separator: String = " ") -> String:
	var filtered: Array[String] = []
	for part in parts:
		var text := part.strip_edges()
		if not text.is_empty():
			filtered.append(text)
	return separator.join(filtered)


func get_script_resref(field_name: String) -> String:
	var primary := get_resref(field_name)
	if not primary.is_empty():
		return primary
	if SCRIPT_FIELD_ALIASES.has(field_name):
		return get_resref(SCRIPT_FIELD_ALIASES[field_name])
	return ""


func append_script_hook_summary_lines(lines: Array[String]) -> void:
	var fields: Array = SCRIPT_HOOK_FIELDS_BY_TYPE.get(file_type, [])
	for field_name_variant in fields:
		var field_name := String(field_name_variant)
		var script_ref := get_script_resref(field_name)
		if script_ref.is_empty():
			continue
		_append_summary_line(lines, field_name, script_ref)


func append_trap_scalar_summary_lines(lines: Array[String]) -> void:
	for field_name in TRAP_SCALAR_FIELDS:
		if not has_field(field_name):
			continue
		var value: Variant = get_field(field_name, null)
		if value == null:
			continue
		if typeof(value) == TYPE_STRING and String(value).strip_edges().is_empty():
			continue
		if field_name == "TrapType" and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
			var trap_index := int(value)
			var label := TypedFieldHelpers.get_enum_display_name("TrapType", trap_index)
			if label.begins_with("Unknown"):
				_append_summary_line(lines, field_name, trap_index)
			else:
				_append_summary_line(lines, field_name, "%d (%s)" % [trap_index, label])
			continue
		_append_summary_line(lines, field_name, value)


func append_enum_summary_line(
	lines: Array[String],
	field_name: String,
	label: String = ""
) -> void:
	if not has_field(field_name):
		return
	var value: Variant = get_field(field_name, null)
	if value == null:
		return
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		_append_summary_line(lines, label if not label.is_empty() else field_name, value)
		return
	var enum_index := int(value)
	var display := TypedFieldHelpers.get_enum_display_name(field_name, enum_index)
	var summary_label := label if not label.is_empty() else field_name
	if display.begins_with("Unknown"):
		_append_summary_line(lines, summary_label, enum_index)
	else:
		_append_summary_line(lines, summary_label, "%d (%s)" % [enum_index, display])


func _append_summary_line(lines: Array[String], label: String, value: Variant) -> void:
	var text := _summary_value_text(value)
	if text.is_empty():
		return
	lines.append("%s: %s" % [label, text])


func _summary_value_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return ""
		TYPE_STRING:
			return String(value).strip_edges()
		TYPE_BOOL:
			return "Yes" if value else "No"
		TYPE_DICTIONARY:
			return describe_locstring(value)
		TYPE_ARRAY:
			return "%d entries" % (value as Array).size()
		_:
			return str(value)


func _notify_changed() -> void:
	changed.emit()
	if _owner_resource_ref == null:
		return
	var owner: Resource = _owner_resource_ref.get_ref()
	if owner != null:
		owner.emit_changed()


