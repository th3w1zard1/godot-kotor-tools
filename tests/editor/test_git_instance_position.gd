@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const KotorGITDocument := preload("../../resources/documents/kotor_git_document.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_set_instance_position()
	_test_set_instance_position_invalid()
	print("✓ GIT instance position tests passed")
	quit()


func _test_set_instance_position() -> void:
	var document := _build_git_document()
	var before := document.find_instance_record("Creatures", 0)
	assert(is_equal_approx(float(before.get("x", 0.0)), 10.0))
	assert(is_equal_approx(float(before.get("y", 0.0)), -4.0))

	assert(document.set_instance_position("Creatures", 0, 12.5, -1.25))
	var after := document.find_instance_record("Creatures", 0)
	assert(is_equal_approx(float(after.get("x", 0.0)), 12.5))
	assert(is_equal_approx(float(after.get("y", 0.0)), -1.25))

	var path_x: Array = ["Creature List", 0, "XPosition"]
	var path_y: Array = ["Creature List", 0, "YPosition"]
	assert(is_equal_approx(float(document.get_field_at_path(path_x)), 12.5))
	assert(is_equal_approx(float(document.get_field_at_path(path_y)), -1.25))


func _test_set_instance_position_invalid() -> void:
	var document := _build_git_document()
	assert(not document.set_instance_position("Creatures", 99, 0.0, 0.0))
	assert(not document.set_instance_position("Unknown", 0, 0.0, 0.0))


func _build_git_document() -> KotorGITDocument:
	var parsed := {
		"file_type": "GIT",
		"root": {
			"Creature List": [
				{
					"TemplateResRef": "n_malak",
					"Tag": "malak",
					"XPosition": 10.0,
					"YPosition": -4.0,
					"ZPosition": 0.0,
					"Bearing": 1.57,
				},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{
					"name": "Creature List",
					"type": GFFParser.FIELD_LIST,
					"struct_type": 4,
					"fields": [
						{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
						{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
						{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
						{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
						{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
						{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
					],
				},
			],
		},
	}
	var resource := GFFResourceFactory.create_from_parser_result(parsed) as GITResource
	return resource.create_document() as KotorGITDocument
