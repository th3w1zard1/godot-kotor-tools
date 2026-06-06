@tool
extends SceneTree

const VISParser := preload("../../formats/vis_parser.gd")
const VISWriter := preload("../../formats/vis_writer.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_write_visibility_map()
	_test_round_trip_rooms()
	_test_format_visibility_summary()
	print("✓ VIS writer tests passed")
	quit()


func _test_write_visibility_map() -> void:
	var text := VISWriter.write_visibility_map({
		"room_b": ["room_c", "room_a"],
		"room_a": ["room_a"],
	})
	assert(text.contains("room_a 1"))
	assert(text.contains("room_b 2"))
	assert(text.find("  room_a") >= 0)
	assert(text.find("  room_c") >= 0)
	print("✓ VIS writer visibility map passed")


func _test_round_trip_rooms() -> void:
	var original := {
		"rooms": {
			"room_b": ["room_b", "room_a"],
			"room_a": ["room_a"],
		},
	}
	var parsed := VISParser.parse_bytes(VISWriter.write_bytes(original))
	assert(VISParser.room_count(parsed) == 2)
	var rooms: Dictionary = parsed.get("rooms", {})
	var room_a_children: Array = rooms.get("room_a", [])
	var room_b_children: Array = rooms.get("room_b", [])
	assert(room_a_children == ["room_a"])
	assert(room_b_children.has("room_a"))
	assert(room_b_children.has("room_b"))
	print("✓ VIS writer round trip passed")


func _test_format_visibility_summary() -> void:
	var summary := KotorModuleContext.format_visibility_summary({
		"rooms": {
			"room_a": ["room_a"],
			"room_b": ["room_b"],
		},
	})
	assert(summary.contains("VIS: 2 room visibility"))
	print("✓ VIS writer visibility summary passed")
