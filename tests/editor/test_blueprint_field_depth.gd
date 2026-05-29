@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const KotorGFFDocument := preload("../../resources/kotor_gff_document.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorEnumRegistry := preload("../../editor/workspace/kotor_enum_registry.gd")
const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")
const GFFTreePopulator := preload("../../ui/workspace/gff_tree_populator.gd")

const TRAP_DEFAULT := {"TrapType": 0}


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_script_resref_detection()
	_test_script_resref_aliases()
	_test_traplist_editable_registration()
	_test_traplist_insert_default()
	_test_traps_2da_enum()
	_test_utt_summary_depth()
	_test_utc_summary_depth()
	_test_utd_summary_scripts()
	_test_are_summary_scripts()
	print("✓ Blueprint field depth tests passed")
	quit()


func _test_script_resref_detection() -> void:
	assert(TypedFieldHelpers.is_resref_field("OnClick"))
	assert(TypedFieldHelpers.is_resref_field("ScriptHeartbeat"))
	assert(TypedFieldHelpers.get_resref_type_hint("OnClick") == "nss")
	assert(TypedFieldHelpers.get_resref_type_hint("ScriptHeartbeat") == "nss")
	print("✓ Script hook ResRef detection passed")


func _test_script_resref_aliases() -> void:
	var doc := KotorGFFDocument.new()
	doc.setup("UTT", {
		"ScriptOnEnter": "enter_trap",
		"ScriptHeartbeat": "hb_trap",
	})
	assert(doc.get_script_resref("OnEnter") == "enter_trap")
	assert(doc.get_script_resref("OnHeartbeat") == "hb_trap")
	print("✓ Script hook alias resolution passed")


func _test_traplist_editable_registration() -> void:
	assert(GFFTreePopulator.EDITABLE_STRUCT_ARRAY_FIELDS.has("TrapList"))
	print("✓ TrapList editable registration passed")


func _test_traplist_insert_default() -> void:
	var parsed := {
		"file_type": "UTT",
		"root": {
			"Tag": "trap_trigger",
			"TrapList": [],
		},
	}
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	var document = resource.create_document()
	assert(document.insert_struct_at_array("TrapList", 0, TRAP_DEFAULT.duplicate()))
	var traps := document.get_field("TrapList") as Array
	assert(traps.size() == 1)
	assert(int((traps[0] as Dictionary).get("TrapType", -1)) == 0)

	var editor := KotorGFFWorkspaceEditor.new()
	var default_struct := editor._create_default_struct("TrapList")
	assert(int(default_struct.get("TrapType", -1)) == 0)
	print("✓ TrapList insert/default struct passed")


func _test_traps_2da_enum() -> void:
	var install_path := ProjectSettings.globalize_path("user://blueprint_traps_enum_install")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var traps_path := override_dir.path_join("traps.2da")
	var traps_file := FileAccess.open(traps_path, FileAccess.WRITE)
	assert(traps_file != null)
	traps_file.store_string("2DA V2.0\n\nlabel\n0 \"Minor Blast\"\n1 \"Gas Trap\"\n")
	traps_file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.clear_cache()
	assert(registry.get_enum_source("TrapType") == "2da")
	assert(registry.get_enum_values("TrapType")[1] == "Gas Trap")
	assert(TypedFieldHelpers.get_enum_display_name("TrapType", 1, registry) == "Gas Trap")

	DirAccess.remove_absolute(traps_path)
	print("✓ TrapType traps.2da enum passed")


func _test_utt_summary_depth() -> void:
	var parsed := {
		"file_type": "UTT",
		"root": {
			"Tag": "gas_trap",
			"LocName": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Gas Trigger"},
			},
			"TrapType": 1,
			"TrapDetectDC": 15,
			"OnClick": "k_trap_click",
			"TrapList": [{"TrapType": 2}],
		},
	}
	var document = GFFResourceFactory.create_from_parser_result(parsed).create_document()
	var summary := "\n".join(document.get_summary_lines())
	assert(summary.contains("OnClick: k_trap_click"))
	assert(summary.contains("TrapType"))
	assert(summary.contains("TrapDetectDC: 15"))
	assert(summary.contains("Traps: 1"))
	print("✓ UTT summary depth passed")


func _test_utc_summary_depth() -> void:
	var parsed := {
		"file_type": "UTC",
		"root": {
			"Tag": "test_npc",
			"Appearance_Type": 3,
			"ScriptHeartbeat": "npc_hb",
		},
	}
	var document = GFFResourceFactory.create_from_parser_result(parsed).create_document()
	var summary := "\n".join(document.get_summary_lines())
	assert(summary.contains("ScriptHeartbeat: npc_hb"))
	assert(summary.contains("Appearance:"))
	assert(summary.contains("3 (Droid Female)"))
	print("✓ UTC summary depth passed")


func _test_utd_summary_scripts() -> void:
	var parsed := {
		"file_type": "UTD",
		"root": {
			"Tag": "test_door",
			"OnOpen": "door_open",
			"TrapFlag": 1,
		},
	}
	var document = GFFResourceFactory.create_from_parser_result(parsed).create_document()
	var summary := "\n".join(document.get_summary_lines())
	assert(summary.contains("OnOpen: door_open"))
	assert(summary.contains("TrapFlag: 1"))
	print("✓ UTD summary depth passed")


func _test_are_summary_scripts() -> void:
	var parsed := {
		"file_type": "ARE",
		"root": {
			"Tag": "test_area",
			"Name": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Area"},
			},
			"OnEnter": "area_enter",
			"OnUserDefined": "area_ud",
		},
	}
	var document = GFFResourceFactory.create_from_parser_result(parsed).create_document()
	var summary := "\n".join(document.get_summary_lines())
	assert(summary.contains("OnEnter: area_enter"))
	assert(summary.contains("OnUserDefined: area_ud"))
	print("✓ ARE summary depth passed")
