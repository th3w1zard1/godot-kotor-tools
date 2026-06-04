@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const AREResource := preload("../../resources/typed/are_resource.gd")
const KotorIndoorBuildManifest := preload("../../resources/indoor/kotor_indoor_build_manifest.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorAreBuilder := preload("../../resources/indoor/kotor_indoor_are_builder.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_rooms_error()
	_test_are_fields()
	_test_are_lighting_and_skybox()
	_test_are_round_trip()
	_test_manifest_includes_are()
	print("✓ Indoor ARE builder tests passed")
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
	var result := KotorIndoorAreBuilder.build_from_document(document)
	assert(not result.get("ok", true))
	print("✓ Indoor ARE builder no rooms error passed")


func _test_are_fields() -> void:
	var document := _document_with_embedded_room()
	var result := KotorIndoorAreBuilder.build_from_document(document)
	assert(result.get("ok", false))
	assert(str(result.get("tag", "")) == "test01")
	assert(int(result.get("interior", 0)) == 1)
	print("✓ Indoor ARE builder field mapping passed")


func _test_are_lighting_and_skybox() -> void:
	var document := _document_with_embedded_room()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.25, 0.5, 0.75],
		"skybox": "sky_test",
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
	var built := KotorIndoorAreBuilder.build_from_document(document)
	var parsed := GFFParser.parse_bytes(built.get("bytes", PackedByteArray()))
	var root: Dictionary = parsed.get("root", {})
	var ambient: Vector3 = root.get("DynAmbientColor", Vector3.ZERO)
	assert(is_equal_approx(ambient.x, 0.25))
	assert(is_equal_approx(ambient.y, 0.5))
	assert(is_equal_approx(ambient.z, 0.75))
	assert(str(root.get("SkyBox", "")) == "sky_test")
	assert(int(root.get("Interior", 0)) == 1)
	print("✓ Indoor ARE builder lighting and skybox passed")


func _test_are_round_trip() -> void:
	var document := _document_with_embedded_room()
	var built := KotorIndoorAreBuilder.build_from_document(document)
	var parsed := GFFParser.parse_bytes(built.get("bytes", PackedByteArray()))
	assert(not parsed.is_empty())
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is AREResource)
	assert(resource.get_tag() == "test01")
	assert(resource.get_area_name() == "test01")
	print("✓ Indoor ARE builder round trip passed")


func _test_manifest_includes_are() -> void:
	var document := _document_with_embedded_room()
	var manifest := KotorIndoorBuildManifest.build(document)
	assert(manifest.get("ok", false))
	var are: Dictionary = manifest.get("are", {})
	assert(are.get("ok", false))
	var report := KotorIndoorBuildManifest.format_report(manifest)
	assert(report.find("ARE preview") >= 0)
	print("✓ Indoor ARE builder manifest integration passed")


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
