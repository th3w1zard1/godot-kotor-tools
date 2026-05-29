@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const KotorGITDocument := preload("../../resources/documents/kotor_git_document.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const ModuleDesignerMapView := preload(
	"../../ui/workspace/panels/module_designer_map_view.gd"
)


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_set_instance_bearing()
	_test_set_instance_bearing_invalid()
	_test_bearing_from_world_point()
	print("✓ GIT instance bearing tests passed")
	quit()


func _test_set_instance_bearing() -> void:
	var document := _build_git_document()
	var before := document.find_instance_record("Creatures", 0)
	assert(is_equal_approx(float(before.get("bearing", 0.0)), 1.57))

	assert(document.set_instance_bearing("Creatures", 0, 0.25))
	var after := document.find_instance_record("Creatures", 0)
	assert(is_equal_approx(float(after.get("bearing", 0.0)), 0.25))

	var path: Array = ["Creature List", 0, "Bearing"]
	assert(is_equal_approx(float(document.get_field_at_path(path)), 0.25))


func _test_set_instance_bearing_invalid() -> void:
	var document := _build_git_document()
	assert(not document.set_instance_bearing("Creatures", 99, 0.0))
	assert(not document.set_instance_bearing("Unknown", 0, 0.0))


func _test_bearing_from_world_point() -> void:
	var origin := Vector2(0.0, 0.0)
	assert(
		is_equal_approx(
			ModuleDesignerMapView._bearing_from_world_point(origin, Vector2(1.0, 0.0)),
			0.0
		)
	)
	assert(
		is_equal_approx(
			ModuleDesignerMapView._bearing_from_world_point(origin, Vector2(0.0, 1.0)),
			PI * 0.5
		)
	)
	assert(
		is_equal_approx(
			ModuleDesignerMapView._bearing_from_world_point(origin, origin),
			0.0
		)
	)


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
