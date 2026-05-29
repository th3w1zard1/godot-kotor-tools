@tool
extends "../kotor_gff_document.gd"
class_name KotorGITDocument

const LIST_FIELDS := {
	"Creatures": "Creature List",
	"Doors": "Door List",
	"Encounters": "Encounter List",
	"Placeables": "Placeable List",
	"Sounds": "SoundList",
	"Stores": "StoreList",
	"Triggers": "TriggerList",
	"Waypoints": "WaypointList",
}

const CATEGORY_COLORS := {
	"Creatures": Color(0.95, 0.35, 0.35),
	"Doors": Color(0.45, 0.75, 0.95),
	"Encounters": Color(0.95, 0.65, 0.25),
	"Placeables": Color(0.55, 0.85, 0.45),
	"Sounds": Color(0.75, 0.55, 0.95),
	"Stores": Color(0.95, 0.85, 0.35),
	"Triggers": Color(0.95, 0.45, 0.75),
	"Waypoints": Color(0.35, 0.85, 0.85),
}


func get_total_instance_count() -> int:
	return get_instance_records().size()


func get_display_name() -> String:
	return "%s (%d placed objects)" % [get_type_label(), get_total_instance_count()]


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	for label in LIST_FIELDS:
		_append_summary_line(lines, label, get_struct_list(LIST_FIELDS[label]).size())
	return lines


func get_instance_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for category in LIST_FIELDS:
		var list_field := String(LIST_FIELDS[category])
		var instances := get_struct_list(list_field)
		for index in instances.size():
			var instance := instances[index]
			var record := _build_instance_record(category, list_field, index, instance)
			if not record.is_empty():
				records.append(record)
	return records


func get_layout_bounds(padding: float = 2.0) -> Rect2:
	var records := get_instance_records()
	if records.is_empty():
		return Rect2(-padding, -padding, padding * 2.0, padding * 2.0)
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for record in records:
		min_x = minf(min_x, float(record.get("x", 0.0)))
		min_y = minf(min_y, float(record.get("y", 0.0)))
		max_x = maxf(max_x, float(record.get("x", 0.0)))
		max_y = maxf(max_y, float(record.get("y", 0.0)))
	if min_x == max_x:
		min_x -= padding
		max_x += padding
	if min_y == max_y:
		min_y -= padding
		max_y += padding
	return Rect2(
		min_x - padding,
		min_y - padding,
		(max_x - min_x) + padding * 2.0,
		(max_y - min_y) + padding * 2.0
	)


static func category_color(category: String) -> Color:
	return CATEGORY_COLORS.get(category, Color(0.8, 0.8, 0.8))


func find_instance_record(category: String, index: int) -> Dictionary:
	for record in get_instance_records():
		if str(record.get("category", "")) == category and int(record.get("index", -1)) == index:
			return record
	return {}


func _build_instance_record(
	category: String,
	list_field: String,
	index: int,
	instance: Dictionary
) -> Dictionary:
	if instance.is_empty():
		return {}
	var template := _read_resref(instance, "TemplateResRef")
	var tag := _read_string(instance, "Tag")
	if template.is_empty() and tag.is_empty() and not _has_position(instance):
		return {}
	return {
		"category": category,
		"list_field": list_field,
		"index": index,
		"path": [list_field, index],
		"x": _read_float(instance, "XPosition"),
		"y": _read_float(instance, "YPosition"),
		"z": _read_float(instance, "ZPosition"),
		"template": template,
		"tag": tag,
		"bearing": _read_bearing(instance),
	}


func _has_position(instance: Dictionary) -> bool:
	return instance.has("XPosition") or instance.has("YPosition") or instance.has("ZPosition")


func _read_bearing(instance: Dictionary) -> float:
	if instance.has("Bearing"):
		return float(instance.get("Bearing", 0.0))
	var xo := _read_float(instance, "XOrientation")
	var yo := _read_float(instance, "YOrientation")
	var zo := _read_float(instance, "ZOrientation")
	var wo := _read_float(instance, "WOrientation")
	if xo == 0.0 and yo == 0.0 and zo == 0.0 and wo == 0.0:
		return 0.0
	return atan2(2.0 * (wo * zo + xo * yo), 1.0 - 2.0 * (yo * yo + zo * zo))


func _read_float(instance: Dictionary, field_name: String) -> float:
	if not instance.has(field_name):
		return 0.0
	return float(instance.get(field_name, 0.0))


func _read_string(instance: Dictionary, field_name: String) -> String:
	if not instance.has(field_name):
		return ""
	return String(instance.get(field_name, "")).strip_edges()


func _read_resref(instance: Dictionary, field_name: String) -> String:
	return _read_string(instance, field_name)
