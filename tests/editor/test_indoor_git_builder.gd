@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const KotorIndoorBuildManifest := preload("../../resources/indoor/kotor_indoor_build_manifest.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorGitBuilder := preload("../../resources/indoor/kotor_indoor_git_builder.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_rooms_error()
	_test_git_empty_doors()
	_test_git_connected_door()
	_test_git_round_trip()
	_test_manifest_includes_git()
	print("✓ Indoor GIT builder tests passed")
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
	var result := KotorIndoorGitBuilder.build_from_document(document)
	assert(not result.get("ok", true))
	print("✓ Indoor GIT builder no rooms error passed")


func _test_git_empty_doors() -> void:
	var document := _document_with_embedded_room()
	var result := KotorIndoorGitBuilder.build_from_document(document)
	assert(result.get("ok", false))
	assert(int(result.get("door_count", -1)) == 0)
	assert(int(result.get("instance_count", -1)) == 0)
	print("✓ Indoor GIT builder empty door list passed")


func _test_git_connected_door() -> void:
	var document := _document_with_connected_rooms()
	var result := KotorIndoorGitBuilder.build_from_document(document)
	assert(result.get("ok", false))
	assert(int(result.get("door_count", 0)) == 1)
	var parsed := GFFParser.parse_bytes(result.get("bytes", PackedByteArray()))
	var doors: Array = parsed.get("root", {}).get("Door List", [])
	assert(doors.size() == 1)
	var door: Dictionary = doors[0]
	assert(is_equal_approx(float(door.get("XPosition", 0.0)), 1.0))
	print("✓ Indoor GIT builder connected door passed")


func _test_git_round_trip() -> void:
	var document := _document_with_connected_rooms()
	var built := KotorIndoorGitBuilder.build_from_document(document)
	var parsed := GFFParser.parse_bytes(built.get("bytes", PackedByteArray()))
	assert(not parsed.is_empty())
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is GITResource)
	assert(resource.get_total_instance_count() == 1)
	assert(resource.find_instance_record("Doors", 0).get("tag") == "indoor_door_0_0")
	print("✓ Indoor GIT builder round trip passed")


func _test_manifest_includes_git() -> void:
	var document := _document_with_embedded_room()
	var manifest := KotorIndoorBuildManifest.build(document)
	assert(manifest.get("ok", false))
	var git: Dictionary = manifest.get("git", {})
	assert(git.get("ok", false))
	var report := KotorIndoorBuildManifest.format_report(manifest)
	assert(report.find("GIT preview") >= 0)
	print("✓ Indoor GIT builder manifest integration passed")


func _document_with_embedded_room() -> KotorIndoorDocument:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [
			{"id": "room_a", "name": "room_a", "bwm": "", "hooks": []},
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
		],
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
