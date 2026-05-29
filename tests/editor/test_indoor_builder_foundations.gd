@tool
extends SceneTree

const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorBuilderWorkspaceEditor := preload(
	"../../ui/workspace/editors/indoor_builder_workspace_editor.gd"
)


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_io_round_trip()
	_test_document_room_mutations()
	_test_layout_bounds_and_records()
	_test_room_world_corners()
	_test_extension_allowed()
	print("✓ Indoor builder foundation tests passed")
	quit()


func _test_io_round_trip() -> void:
	var original := _sample_map_data()
	var bytes := KotorIndoorMapIO.write_bytes(original)
	var parsed := KotorIndoorMapIO.parse_bytes(bytes)
	assert(parsed.size() > 0)
	assert(str(parsed.get("module_id", "")) == "test01")
	var rooms: Variant = parsed.get("rooms", [])
	assert(typeof(rooms) == TYPE_ARRAY)
	assert((rooms as Array).size() == 1)
	var room: Dictionary = (rooms as Array)[0]
	assert(is_equal_approx(float(room.get("rotation", 0.0)), 0.5))


func _test_document_room_mutations() -> void:
	var document := KotorIndoorDocument.new()
	var sample := _sample_map_data()
	assert(document.load_from_bytes(KotorIndoorMapIO.write_bytes(sample)))
	assert(document.get_room_count() == 1)
	assert(document.set_room_position(0, 12.0, -3.0))
	assert(document.set_room_rotation(0, 1.25))
	var record := document.find_room_record(0)
	assert(is_equal_approx(float(record.get("x", 0.0)), 12.0))
	assert(is_equal_approx(float(record.get("y", 0.0)), -3.0))
	assert(is_equal_approx(float(record.get("rotation", 0.0)), 1.25))
	assert(not document.set_room_position(99, 0.0, 0.0))
	var round_trip := KotorIndoorMapIO.parse_bytes(document.serialize_to_bytes())
	var rooms: Variant = round_trip.get("rooms", [])
	var room: Dictionary = (rooms as Array)[0]
	var position: Variant = room.get("position", [])
	assert(typeof(position) == TYPE_ARRAY)
	assert(is_equal_approx(float((position as Array)[0]), 12.0))
	assert(is_equal_approx(float((position as Array)[1]), -3.0))


func _test_layout_bounds_and_records() -> void:
	var document := KotorIndoorDocument.new()
	assert(document.load_from_bytes(KotorIndoorMapIO.write_bytes(_sample_map_data())))
	var records := document.get_room_records()
	assert(records.size() == 1)
	assert(str(records[0].get("label", "")).contains("room_a"))
	var bounds := document.get_layout_bounds()
	assert(bounds.size.x > 0.0)
	assert(bounds.size.y > 0.0)


func _test_room_world_corners() -> void:
	var record := {
		"x": 0.0,
		"y": 0.0,
		"rotation": 0.0,
		"flip_x": false,
		"flip_y": false,
		"half_width": 2.0,
		"half_height": 1.0,
	}
	var corners := KotorIndoorDocument._room_world_corners(record)
	assert(corners.size() == 4)
	assert(corners.has(Vector2(-2.0, -1.0)))
	assert(corners.has(Vector2(2.0, 1.0)))


func _test_extension_allowed() -> void:
	assert(KotorIndoorBuilderWorkspaceEditor.indoor_extension_allowed("indoor"))
	assert(not KotorIndoorBuilderWorkspaceEditor.indoor_extension_allowed("git"))


func _sample_map_data() -> Dictionary:
	return {
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [
			{
				"id": "room_a",
				"name": "room_a",
				"bwm": "",
				"mdl": "",
				"mdx": "",
				"hooks": [],
			},
		],
		"rooms": [
			{
				"position": [1.0, 2.0, 0.0],
				"rotation": 0.5,
				"flip_x": false,
				"flip_y": false,
				"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
				"component": "room_a",
			},
		],
	}
