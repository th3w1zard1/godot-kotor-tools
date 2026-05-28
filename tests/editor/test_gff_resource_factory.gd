@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const FACResource := preload("../../resources/typed/fac_resource.gd")
const JRLResource := preload("../../resources/typed/jrl_resource.gd")
const PTHResource := preload("../../resources/typed/pth_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_jrl_factory_mapping()
	_test_pth_factory_mapping()
	_test_fac_factory_mapping()
	print("✓ GFF resource factory tests passed")
	quit()


func _test_jrl_factory_mapping() -> void:
	var parsed := {
		"file_type": "JRL",
		"root": {
			"Tag": "quest_journal",
			"Name": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Main Journal"},
			},
			"EntriesList": [
				{"ID": 10},
				{"ID": 20},
			],
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is JRLResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Main Journal")
	assert(document.get_summary_lines().size() >= 4)


func _test_pth_factory_mapping() -> void:
	var parsed := {
		"file_type": "PTH",
		"root": {
			"Tag": "module_paths",
			"Path_Points": [
				{"ID": 1},
				{"ID": 2},
			],
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is PTHResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "module_paths")
	assert(document.get_summary_lines().size() >= 3)


func _test_fac_factory_mapping() -> void:
	var parsed := {
		"file_type": "FAC",
		"root": {
			"Label": "Sith Academy",
			"Tag": "academy_faction",
			"Appearances": [
				{"Race": 1},
			],
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is FACResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Sith Academy")
	assert(document.get_summary_lines().size() >= 4)
