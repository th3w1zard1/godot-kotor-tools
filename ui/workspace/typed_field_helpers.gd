@tool
extends RefCounted
class_name TypedFieldHelpers


const ENUM_FIELD_MAPPING := {
	"Gender": {
		0: "Male",
		1: "Female",
	},
	"Race": {
		0: "Droid",
		1: "Wookiee",
		2: "Unknown",
		3: "Human",
		4: "Selkath",
		5: "Twilek",
	},
	"Appearance_Type": {
		0: "Human Male",
		1: "Human Female",
		2: "Droid Male",
		3: "Droid Female",
		4: "Wookiee Male",
		5: "Wookiee Female",
		6: "Selkath Male",
		7: "Selkath Female",
		8: "Twilek Male",
		9: "Twilek Female",
		10: "Unknown",
	},
}

const MAX_RESREF_LENGTH := 16

const RESREF_TYPE_HINTS := {
	"Script": "nss",
	"Sound": "wav",
	"VO_ResRef": "wav",
	"TemplateResRef": "utc",
	"InventoryRes": "uti",
	"Conversation": "dlg",
	"PortraitId": "tga",
}

const LOCSTRING_LANGUAGE_IDS := [0, 1, 2, 3, 4, 5]


static func has_enum_hints(field_name: String, registry: RefCounted = null) -> bool:
	return not get_enum_values(field_name, registry).is_empty()


static func get_enum_values(field_name: String, registry: RefCounted = null) -> Dictionary:
	if registry != null and registry.has_method("get_enum_values"):
		var dynamic_values: Dictionary = registry.get_enum_values(field_name)
		if not dynamic_values.is_empty():
			return dynamic_values
	return ENUM_FIELD_MAPPING.get(field_name, {})


static func get_enum_display_name(field_name: String, value: int, registry: RefCounted = null) -> String:
	var mapping: Dictionary = get_enum_values(field_name, registry)
	if mapping.has(value):
		return mapping[value]
	return "Unknown (%d)" % value


static func validate_enum_value(field_name: String, value: int, registry: RefCounted = null) -> bool:
	var mapping: Dictionary = get_enum_values(field_name, registry)
	if mapping.is_empty():
		return true
	if mapping.has(value):
		return true
	if registry != null and registry.has_method("get_enum_source"):
		if registry.get_enum_source(field_name) == "2da":
			return true
	return false


static func get_enum_options_as_array(field_name: String, registry: RefCounted = null) -> Array[String]:
	var options: Array[String] = []
	var mapping: Dictionary = get_enum_values(field_name, registry)
	var keys = mapping.keys() as Array
	keys.sort()
	for key in keys:
		options.append("%d: %s" % [key, mapping[key]])
	return options


static func is_resref_field(field_name: String) -> bool:
	return "Ref" in field_name


static func validate_resref(text: String) -> String:
	var trimmed := text.strip_edges()
	if trimmed.length() <= MAX_RESREF_LENGTH:
		return trimmed
	return trimmed.substr(0, MAX_RESREF_LENGTH)


static func get_resref_validation_hint() -> String:
	return "Max %d characters" % MAX_RESREF_LENGTH


static func get_resref_type_hint(field_name: String) -> String:
	var lower_field := field_name.strip_edges()
	if RESREF_TYPE_HINTS.has(lower_field):
		return RESREF_TYPE_HINTS[lower_field]
	if lower_field.ends_with("Script"):
		return "nss"
	if lower_field.ends_with("Sound"):
		return "wav"
	return ""


static func normalize_picker_selection(entry: Dictionary) -> String:
	var resref := String(entry.get("resref", "")).strip_edges()
	return validate_resref(resref)


static func parse_enum_option_index(option_text: String) -> int:
	var colon_index := option_text.find(": ")
	if colon_index <= 0:
		return int(option_text) if option_text.is_valid_int() else -1
	return int(option_text.substr(0, colon_index))


static func find_enum_option_index(field_name: String, value: int, registry: RefCounted = null) -> int:
	var options := get_enum_options_as_array(field_name, registry)
	for i in options.size():
		if parse_enum_option_index(options[i]) == value:
			return i
	return -1


static func is_item_resref_field(field_name: String, path: Array = []) -> bool:
	var lower := field_name.strip_edges()
	if lower == "InventoryRes":
		return true
	if lower.ends_with("ItemRes"):
		return true
	if lower == "ResRef" and _path_contains_segment(path, "itemList"):
		return true
	return false


static func _path_contains_segment(path: Array, segment: String) -> bool:
	for part in path:
		if str(part) == segment:
			return true
	return false


# Hybrid Validation Helpers for Q6 DLG Array Mutations

static func is_required_field(field_name: String) -> bool:
	# Fields that must have valid values to prevent broken data
	var lower_field := field_name.strip_edges().to_lower()
	
	# DLG: Index field must be valid
	if lower_field == "index":
		return true
	
	# GFF Generic: Operator and Script fields (Q7)
	if lower_field in ["operator", "script"]:
		return true
	
	# ActionID fields (Q7 UTC)
	if lower_field == "actionid":
		return true
	
	return false


static func validate_required_field(field_name: String, value: Variant, entry_list_size: int = -1) -> bool:
	var lower_field := field_name.strip_edges().to_lower()
	
	# DLG Index validation
	if lower_field == "index":
		if entry_list_size < 0:
			return true  # Can't validate yet, allow it
		var index_value := int(value) if typeof(value) == TYPE_INT else -1
		return index_value >= 0 and index_value < entry_list_size
	
	# GFF Operator validation (0-2 for AND/OR/NOT)
	if lower_field == "operator":
		var op_value := int(value) if typeof(value) == TYPE_INT else -1
		return op_value >= 0 and op_value <= 2
	
	# Script ResRef validation (non-empty, max 16 chars)
	if lower_field == "script":
		var script_value := String(value).strip_edges()
		return not script_value.is_empty() and script_value.length() <= MAX_RESREF_LENGTH
	
	# ActionID validation (-1 = no action, >= 0 = valid)
	if lower_field == "actionid":
		var action_value := int(value) if typeof(value) == TYPE_INT else -99
		return action_value >= -1
	
	return true


static func get_validation_warning(field_name: String, value: Variant) -> String:
	var lower_field := field_name.strip_edges().to_lower()
	var str_value := String(value).strip_edges()
	
	# DLG optional field warnings
	if lower_field in ["comment", "active"]:
		if str_value.is_empty():
			return "Field is empty (optional)"
	
	# GFF optional field warnings
	if lower_field == "eventid":
		var int_value := int(value) if typeof(value) == TYPE_INT else -1
		if int_value == 0:
			return "EventID is 0 (default); confirm this is intended"
	
	if lower_field == "parameter":
		var int_value := int(value) if typeof(value) == TYPE_INT else -1
		if int_value == 0:
			return "Parameter is 0 (default); may need adjustment"
	
	if lower_field == "flags":
		var int_value := int(value) if typeof(value) == TYPE_INT else -1
		if int_value == 0:
			return "Flags is 0 (no flags set); confirm this is intended"
	
	if lower_field == "actionid":
		var action_value := int(value) if typeof(value) == TYPE_INT else -1
		if action_value == -1:
			return "ActionID is -1 (no action linked); modder must set this"
	
	return ""
