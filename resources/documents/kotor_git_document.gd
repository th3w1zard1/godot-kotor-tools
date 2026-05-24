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


func get_total_instance_count() -> int:
	var total := 0
	for field_name in LIST_FIELDS.values():
		total += get_struct_list(field_name).size()
	return total


func get_display_name() -> String:
	return "%s (%d placed objects)" % [get_type_label(), get_total_instance_count()]


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	for label in LIST_FIELDS:
		_append_summary_line(lines, label, get_struct_list(LIST_FIELDS[label]).size())
	return lines
