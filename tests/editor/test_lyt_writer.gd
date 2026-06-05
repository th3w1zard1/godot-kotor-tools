@tool
extends SceneTree

const LYTParser := preload("../../formats/lyt_parser.gd")
const LYTWriter := preload("../../formats/lyt_writer.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_write_room_layout()
	_test_round_trip_full_layout()
	_test_format_layout_summary()
	print("✓ LYT writer tests passed")
	quit()


func _test_write_room_layout() -> void:
	var text := LYTWriter.write_text({
		"rooms": [{"model": "room_a", "position": Vector3(1.0, 2.0, 3.0)}],
		"tracks": [],
		"obstacles": [],
		"doorhooks": [],
	})
	assert(text.contains("roomcount 1"))
	assert(text.contains("roommodel room_a 1.000000 2.000000 3.000000"))
	print("✓ LYT writer room layout passed")


func _test_round_trip_full_layout() -> void:
	var original := {
		"file_dependencies": ["test.dlg"],
		"rooms": [{"model": "room_a", "position": Vector3(0.0, 0.0, 0.0)}],
		"tracks": [{"model": "track01", "position": Vector3(1.0, 0.0, 1.0)}],
		"obstacles": [{"model": "obs01", "position": Vector3(2.0, 0.0, 2.0)}],
		"doorhooks": [
			{
				"name": "hook_a",
				"door": "door01",
				"room": "room_a",
				"position": Vector3(3.0, 0.0, 3.0),
			},
		],
	}
	var roundtrip := LYTParser.parse_bytes(LYTWriter.write_bytes(original))
	assert((roundtrip.get("rooms", []) as Array).size() == 1)
	assert((roundtrip.get("tracks", []) as Array).size() == 1)
	assert((roundtrip.get("obstacles", []) as Array).size() == 1)
	assert((roundtrip.get("doorhooks", []) as Array).size() == 1)
	print("✓ LYT writer round trip passed")


func _test_format_layout_summary() -> void:
	var summary := KotorModuleContext.format_layout_summary({
		"rooms": [{}],
		"tracks": [{}, {}],
		"obstacles": [],
		"doorhooks": [{}],
	})
	assert(summary.contains("1 room"))
	assert(summary.contains("2 track"))
	print("✓ LYT writer layout summary passed")
