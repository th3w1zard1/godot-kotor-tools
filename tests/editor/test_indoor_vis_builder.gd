@tool
extends SceneTree

const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorBuildManifest := preload("../../resources/indoor/kotor_indoor_build_manifest.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")
const KotorIndoorVisBuilder := preload("../../resources/indoor/kotor_indoor_vis_builder.gd")
const VISParser := preload("../../formats/vis_parser.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_rooms_error()
	_test_single_room_self_visibility()
	_test_connected_room_visibility()
	_test_vis_round_trip()
	_test_duplicate_component_visibility_union()
	_test_manifest_includes_vis()
	print("✓ Indoor VIS builder tests passed")
	quit()


func _test_no_rooms_error() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [],
	})
	var result := KotorIndoorVisBuilder.build_from_document(document)
	assert(not result.get("ok", true))
	print("✓ Indoor VIS builder no rooms error passed")


func _test_single_room_self_visibility() -> void:
	var document := _document_with_embedded_rooms(["room_a"])
	var result := KotorIndoorVisBuilder.build_from_document(document)
	assert(result.get("ok", false))
	var text := str(result.get("text", ""))
	assert(text.find("room_a 1") >= 0)
	assert(text.find("  room_a") >= 0)
	print("✓ Indoor VIS builder self visibility passed")


func _test_connected_room_visibility() -> void:
	var document := _document_with_connected_rooms()
	var result := KotorIndoorVisBuilder.build_from_document(document)
	assert(result.get("ok", false))
	var text := str(result.get("text", ""))
	assert(text.find("room_a 2") >= 0)
	assert(text.find("room_b 2") >= 0)
	assert(text.find("  room_b") >= 0)
	assert(text.find("  room_a") >= 0)
	print("✓ Indoor VIS builder connected visibility passed")


func _test_vis_round_trip() -> void:
	var document := _document_with_connected_rooms()
	var built := KotorIndoorVisBuilder.build_from_document(document)
	var parsed := VISParser.parse_bytes(built.get("bytes", PackedByteArray()))
	assert(VISParser.room_count(parsed) == 2)
	var rooms: Dictionary = parsed.get("rooms", {})
	var room_a_children: Array = rooms.get("room_a", [])
	var room_b_children: Array = rooms.get("room_b", [])
	assert(room_a_children.has("room_a"))
	assert(room_a_children.has("room_b"))
	assert(room_b_children.has("room_a"))
	assert(room_b_children.has("room_b"))
	print("✓ Indoor VIS builder round trip passed")


func _test_duplicate_component_visibility_union() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
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
				"position": [10.0, 0.0, 0.0],
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
	})
	var result := KotorIndoorVisBuilder.build_from_document(document)
	assert(result.get("ok", false))
	var text := str(result.get("text", ""))
	assert(text.find("room_a 2") >= 0, "Duplicate room_a placements should union hook neighbors")
	assert(text.find("  room_b") >= 0)
	print("✓ Indoor VIS builder duplicate component union passed")


func _test_manifest_includes_vis() -> void:
	var document := _document_with_embedded_rooms(["room_a"])
	document.set_kit_library(null)
	var manifest := KotorIndoorBuildManifest.build(document)
	assert(manifest.get("ok", false))
	var vis: Dictionary = manifest.get("vis", {})
	assert(vis.get("ok", false))
	var report := KotorIndoorBuildManifest.format_report(manifest)
	assert(report.find("VIS preview") >= 0)
	print("✓ Indoor VIS builder manifest integration passed")


func _document_with_embedded_rooms(component_ids: Array) -> KotorIndoorDocument:
	var embedded: Array = []
	for component_id in component_ids:
		embedded.append({
			"id": component_id,
			"name": component_id,
			"bwm": "",
			"hooks": [],
		})
	var rooms: Array = []
	for component_id in component_ids:
		rooms.append({
			"position": [0.0, 0.0, 0.0],
			"rotation": 0.0,
			"flip_x": false,
			"flip_y": false,
			"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
			"component": component_id,
		})
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": embedded,
		"rooms": rooms,
	})
	return document


func _document_with_connected_rooms() -> KotorIndoorDocument:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
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
	})
	return document
