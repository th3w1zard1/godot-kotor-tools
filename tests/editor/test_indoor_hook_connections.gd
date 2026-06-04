@tool
extends SceneTree

const KotorIndoorHookConnections := preload(
	"../../resources/indoor/kotor_indoor_hook_connections.gd"
)
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_hook_world_position_rotation()
	_test_rebuild_connections_between_aligned_rooms()
	_test_document_hook_summary()
	print("✓ Indoor hook connection tests passed")
	quit()


func _test_hook_world_position_rotation() -> void:
	var room := {
		"position": [1.0, 2.0, 0.0],
		"rotation": 90.0,
		"flip_x": false,
		"flip_y": false,
	}
	var hook := {"position": [1.0, 0.0, 0.0]}
	var world := KotorIndoorHookConnections.hook_world_position(room, hook)
	assert(is_equal_approx(world.x, 1.0))
	assert(is_equal_approx(world.y, 3.0))


func _test_rebuild_connections_between_aligned_rooms() -> void:
	var rooms := [
		{
			"position": [0.0, 0.0, 0.0],
			"rotation": 0.0,
			"flip_x": false,
			"flip_y": false,
			"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
			"component": "room_a",
		},
		{
			"position": [2.0, 0.0, 0.0],
			"rotation": 0.0,
			"flip_x": false,
			"flip_y": false,
			"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
			"component": "room_b",
		},
	]
	var hooks_by_component := {
		"room_a": [{"position": [1.0, 0.0, 0.0]}],
		"room_b": [{"position": [-1.0, 0.0, 0.0]}],
	}
	var connections := KotorIndoorHookConnections.rebuild_connections(
		rooms,
		func(room_index: int, room: Dictionary) -> Array:
			var component_id := str(room.get("component", ""))
			return hooks_by_component.get(component_id, []) as Array
	)
	assert(connections.size() == 2)
	var room_a_connections: Array = connections[0]
	var room_b_connections: Array = connections[1]
	assert(int(room_a_connections[0]) == 1)
	assert(int(room_b_connections[0]) == 0)


func _test_document_hook_summary() -> void:
	var document := KotorIndoorDocument.new()
	var map_data := {
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
				"hooks": [{"position": [1.0, 0.0, 0.0]}],
			},
			{
				"id": "room_b",
				"name": "room_b",
				"bwm": "",
				"hooks": [{"position": [-1.0, 0.0, 0.0]}],
			},
		],
		"rooms": [
			{
				"position": [0.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
				"component": "room_a",
			},
			{
				"position": [2.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
				"component": "room_b",
			},
		],
	}
	document.load_from_dictionary(map_data)
	var counts := document.get_hook_connection_counts()
	assert(int(counts.get("connected", 0)) == 2)
	var summaries := document.get_room_hook_summaries(0)
	assert(summaries.size() == 1)
	assert(str(summaries[0]).contains("room 1"))
