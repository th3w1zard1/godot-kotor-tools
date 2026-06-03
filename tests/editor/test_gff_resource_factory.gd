@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const BICResource := preload("../../resources/typed/bic_resource.gd")
const FACResource := preload("../../resources/typed/fac_resource.gd")
const IFOResource := preload("../../resources/typed/ifo_resource.gd")
const JRLResource := preload("../../resources/typed/jrl_resource.gd")
const PTHResource := preload("../../resources/typed/pth_resource.gd")
const UTIResource := preload("../../resources/typed/uti_resource.gd")
const UTDResource := preload("../../resources/typed/utd_resource.gd")
const UTEResource := preload("../../resources/typed/ute_resource.gd")
const UTMResource := preload("../../resources/typed/utm_resource.gd")
const UTSResource := preload("../../resources/typed/uts_resource.gd")
const UTTResource := preload("../../resources/typed/utt_resource.gd")
const UTWResource := preload("../../resources/typed/utw_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_jrl_factory_mapping()
	_test_bic_factory_mapping()
	_test_pth_factory_mapping()
	_test_fac_factory_mapping()
	_test_ifo_factory_mapping()
	_test_uti_factory_mapping()
	_test_utd_factory_mapping()
	_test_ute_factory_mapping()
	_test_utm_factory_mapping()
	_test_uts_factory_mapping()
	_test_utt_factory_mapping()
	_test_utw_factory_mapping()
	print("✓ GFF resource factory tests passed")
	quit()


func _test_bic_factory_mapping() -> void:
	var parsed := {
		"file_type": "BIC",
		"root": {
			"TemplateResRef": "p_player",
			"Tag": "pc_test",
			"FirstName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Revan"},
			},
			"LastName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Unknown"},
			},
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is BICResource)
	assert(resource.get_player_name() == "Revan Unknown")
	assert(resource.get_first_name_text() == "Revan")
	assert(resource.get_last_name_text() == "Unknown")
	var document = resource.create_document()
	assert(document.get_display_name() == "Revan Unknown")
	assert(document.get_summary_lines().size() >= 5)


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


func _test_ifo_factory_mapping() -> void:
	var parsed := {
		"file_type": "IFO",
		"root": {
			"Mod_Name": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Endar Spire"},
			},
			"Mod_Tag": "endar_spire",
			"Mod_ResRef": "end_m01aa",
			"Mod_Area_list": [
				{"Area_Name": "end_m01aa"},
				{"Area_Name": "end_m01ab"},
			],
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is IFOResource)
	assert(resource.get_module_name() == "Endar Spire")
	assert(resource.get_module_tag() == "endar_spire")
	assert(resource.get_module_resref() == "end_m01aa")
	assert(resource.get_starting_area_count() == 2)
	var document = resource.create_document()
	assert(document.get_display_name() == "Endar Spire")
	assert(document.get_summary_lines().size() >= 5)


func _test_uti_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTI",
		"root": {
			"TemplateResRef": "g_w_lghtsbr01",
			"Tag": "test_item",
			"LocalizedName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Prototype Saber"},
			},
			"BaseItem": 38,
			"StackSize": 1,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTIResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Prototype Saber")
	assert(document.get_summary_lines().size() >= 5)


func _test_utd_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTD",
		"root": {
			"TemplateResRef": "m12aa_door01",
			"Tag": "main_door",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Main Security Door"},
			},
			"Conversation": "door_talk",
			"Static": 1,
			"Plot": 0,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTDResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Main Security Door")
	assert(document.get_summary_lines().size() >= 6)


func _test_ute_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTE",
		"root": {
			"TemplateResRef": "m12aa_enc01",
			"Tag": "test_encounter",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Encounter"},
			},
			"CreatureList": [
				{"ResRef": "n_test_01"},
				{"ResRef": "n_test_02"},
			],
			"Respawns": 1,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTEResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Test Encounter")
	assert(document.get_summary_lines().size() >= 6)


func _test_utm_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTM",
		"root": {
			"ResRef": "m12aa_store01",
			"Tag": "test_store",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Merchant"},
			},
			"ItemList": [
				{"InventoryRes": "g_w_blstrrfl001"},
			],
			"MarkUp": 100,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTMResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Test Merchant")
	assert(document.get_summary_lines().size() >= 6)


func _test_uts_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTS",
		"root": {
			"TemplateResRef": "m12aa_sound01",
			"Tag": "test_sound",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Ambient Sound"},
			},
			"Sounds": [
				{"Sound": "as_test_01"},
			],
			"Active": 1,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTSResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Test Ambient Sound")
	assert(document.get_summary_lines().size() >= 6)


func _test_utt_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTT",
		"root": {
			"TemplateResRef": "m12aa_trg01",
			"Tag": "test_trigger",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Trigger"},
			},
			"TrapList": [
				{"TrapType": 1},
			],
			"AutoRemoveKey": 0,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTTResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Test Trigger")
	assert(document.get_summary_lines().size() >= 6)


func _test_utw_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTW",
		"root": {
			"TemplateResRef": "m12aa_wp01",
			"Tag": "test_waypoint",
			"LocalizedName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Waypoint"},
			},
			"LinkedTo": "exit_door",
			"HasMapNote": 1,
			"MapNote": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Secret passage"},
			},
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTWResource)
	var document = resource.create_document()
	assert(document.get_display_name() == "Test Waypoint")
	assert(document.get_summary_lines().size() >= 6)
