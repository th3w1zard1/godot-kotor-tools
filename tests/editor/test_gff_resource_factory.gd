@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const AREResource := preload("../../resources/typed/are_resource.gd")
const BICResource := preload("../../resources/typed/bic_resource.gd")
const FACResource := preload("../../resources/typed/fac_resource.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const IFOResource := preload("../../resources/typed/ifo_resource.gd")
const JRLResource := preload("../../resources/typed/jrl_resource.gd")
const PTHResource := preload("../../resources/typed/pth_resource.gd")
const UTCResource := preload("../../resources/typed/utc_resource.gd")
const UTPResource := preload("../../resources/typed/utp_resource.gd")
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
	_test_are_factory_mapping()
	_test_bic_factory_mapping()
	_test_pth_factory_mapping()
	_test_fac_factory_mapping()
	_test_git_factory_mapping()
	_test_ifo_factory_mapping()
	_test_utc_factory_mapping()
	_test_utp_factory_mapping()
	_test_uti_factory_mapping()
	_test_utd_factory_mapping()
	_test_ute_factory_mapping()
	_test_utm_factory_mapping()
	_test_uts_factory_mapping()
	_test_utt_factory_mapping()
	_test_utw_factory_mapping()
	print("✓ GFF resource factory tests passed")
	quit()


func _test_are_factory_mapping() -> void:
	var parsed := {
		"file_type": "ARE",
		"root": {
			"Name": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Taris Upper City"},
			},
			"Tag": "tar_m02ab",
			"OnEnter": "k_ptar_enter",
			"OnExit": "k_ptar_exit",
			"OnHeartbeat": "k_ptar_hb",
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is AREResource)
	assert(resource.get_area_name() == "Taris Upper City")
	assert(resource.get_tag() == "tar_m02ab")
	assert(resource.get_on_enter_script() == "k_ptar_enter")
	assert(resource.get_on_exit_script() == "k_ptar_exit")
	assert(resource.get_on_heartbeat_script() == "k_ptar_hb")
	var document = resource.create_document()
	assert(document.get_display_name() == "Taris Upper City")
	assert(document.get_summary_lines().size() >= 6)


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
	assert(resource.get_name_text() == "Main Journal")
	assert(resource.get_tag() == "quest_journal")
	assert(resource.get_entry_count() == 2)
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
	assert(resource.get_tag() == "module_paths")
	assert(resource.get_point_field_name() == "Path_Points")
	assert(resource.get_point_count() == 2)
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


func _test_git_factory_mapping() -> void:
	var parsed := {
		"file_type": "GIT",
		"root": {
			"Creature List": [
				{"TemplateResRef": "n_test", "XPosition": 1.5, "YPosition": -3.0},
			],
			"Door List": [],
			"Encounter List": [],
			"Placeable List": [],
			"SoundList": [],
			"StoreList": [],
			"TriggerList": [],
			"WaypointList": [],
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is GITResource)
	var git_resource := resource as GITResource
	assert(git_resource.get_total_instance_count() == 1)
	assert(git_resource.get_instance_records().size() == 1)
	var counts := git_resource.get_category_counts()
	assert(int(counts.get("Creatures", 0)) == 1)
	assert(int(counts.get("Doors", 0)) == 0)
	var bounds: Rect2 = git_resource.get_layout_bounds(1.0)
	assert(bounds.size.x > 0.0)
	assert(bounds.size.y > 0.0)
	var document = resource.create_document()
	assert(document.get_summary_lines().size() >= 2)


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
			"OnModLoad": "k_end_load",
			"Mod_OnHeartbeat": "k_end_hb",
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
	assert(resource.get_on_load_script() == "k_end_load")
	assert(resource.get_on_heartbeat_script() == "k_end_hb")
	var document = resource.create_document()
	assert(document.get_display_name() == "Endar Spire")
	assert(document.get_summary_lines().size() >= 5)


func _test_utc_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTC",
		"root": {
			"TemplateResRef": "n_commoner01",
			"Tag": "test_utc",
			"FirstName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Davin"},
			},
			"LastName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Vek"},
			},
			"Conversation": "n_commoner_conv",
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTCResource)
	assert(resource.get_name_text() == "Davin Vek")
	assert(resource.get_template_resref() == "n_commoner01")
	assert(resource.get_tag() == "test_utc")
	assert(resource.get_conversation_resref() == "n_commoner_conv")
	var document = resource.create_document()
	assert(document.get_display_name() == "Davin Vek")
	assert(document.get_summary_lines().size() >= 5)


func _test_utp_factory_mapping() -> void:
	var parsed := {
		"file_type": "UTP",
		"root": {
			"TemplateResRef": "m12aa_plc01",
			"Tag": "test_placeable",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Security Crate"},
			},
			"Conversation": "plc_security_conv",
			"HasInventory": 1,
			"Useable": 1,
		},
	}

	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	assert(resource is UTPResource)
	assert(resource.get_name_text() == "Security Crate")
	assert(resource.get_template_resref() == "m12aa_plc01")
	assert(resource.get_tag() == "test_placeable")
	assert(resource.get_conversation_resref() == "plc_security_conv")
	assert(resource.has_inventory() == true)
	assert(resource.is_useable() == true)
	var document = resource.create_document()
	assert(document.get_display_name() == "Security Crate")
	assert(document.get_summary_lines().size() >= 6)


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
	assert(resource.get_name_text() == "Prototype Saber")
	assert(resource.get_base_item_id() == 38)
	assert(resource.get_stack_size() == 1)
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
	assert(resource.get_name_text() == "Main Security Door")
	assert(resource.get_conversation_resref() == "door_talk")
	assert(resource.is_static() == true)
	assert(resource.is_plot() == false)
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
	assert(resource.get_name_text() == "Test Encounter")
	assert(resource.get_creature_count() == 2)
	assert(resource.is_respawning() == true)
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
	assert(resource.get_name_text() == "Test Merchant")
	assert(resource.get_inventory_count() == 1)
	assert(resource.get_markup_percent() == 100)
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
	assert(resource.get_name_text() == "Test Ambient Sound")
	assert(resource.get_active_count() == 1)
	assert(resource.is_active() == true)
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
	assert(resource.get_name_text() == "Test Trigger")
	assert(resource.get_trap_count() == 1)
	assert(resource.is_auto_remove_key_enabled() == false)
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
	assert(resource.get_name_text() == "Test Waypoint")
	assert(resource.get_linked_to() == "exit_door")
	assert(resource.has_map_note() == true)
	assert(resource.get_map_note_text() == "Secret passage")
	var document = resource.create_document()
	assert(document.get_display_name() == "Test Waypoint")
	assert(document.get_summary_lines().size() >= 6)
