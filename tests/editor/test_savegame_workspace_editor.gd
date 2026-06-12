@tool
extends SceneTree

const ERFWriter := preload("../../formats/erf_writer.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const KotorSavegameWorkspaceEditor := preload("../../ui/workspace/editors/savegame_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_open_save_and_summary()
	_test_member_payload_access()
	_test_member_open_routes_gff_inspect()
	print("✓ Savegame workspace editor tests passed")
	quit()


func _test_open_save_and_summary() -> void:
	var editor := _build_editor()
	var sav_bytes := _build_test_sav_bytes()
	editor.open_save_bytes("slot1.sav", sav_bytes, "")
	var resource := editor.get_resource()
	assert(resource != null)
	assert(resource.is_valid())
	assert(resource.build_summary_text().contains("Test Save"))
	assert(resource.build_summary_text().contains("tar_m02aa"))
	assert(int(resource.inspection.get("entry_count", 0)) == 1)
	print("✓ Savegame workspace open + summary passed")


func _test_member_payload_access() -> void:
	var editor := _build_editor()
	editor.open_save_bytes("slot1.sav", _build_test_sav_bytes(), "")
	assert(editor.get_entry_payload(0).size() > 0)
	print("✓ Savegame workspace member payload passed")


func _test_member_open_routes_gff_inspect() -> void:
	var gff_editor := KotorGFFWorkspaceEditor.new()
	var editor_state := KotorEditorState.new()
	gff_editor.setup(editor_state, KotorWorkspaceController.new(editor_state))
	root.add_child(gff_editor)
	gff_editor._ready()
	var payload := _build_gff_bytes(_build_savenfo_parsed())
	assert(gff_editor.open_inspect_gff_bytes("savenfo.res", payload, ""))
	assert(gff_editor.has_document())
	print("✓ Savegame GFF inspect open passed")


func _build_editor() -> KotorSavegameWorkspaceEditor:
	var editor_state := KotorEditorState.new()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorSavegameWorkspaceEditor.new()
	editor.setup(editor_state, controller)
	root.add_child(editor)
	editor._ready()
	return editor


func _build_test_sav_bytes() -> PackedByteArray:
	return ERFWriter.build("SAV ", [
		{"resref": "savenfo", "extension": "res", "bytes": _build_gff_bytes(_build_savenfo_parsed())},
	])


func _build_gff_bytes(parsed: Dictionary) -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(parsed))


func _build_savenfo_parsed() -> Dictionary:
	return {
		"file_type": "GFF ",
		"root": {
			"SAVEGAMENAME": "Test Save",
			"LASTMODULE": "tar_m02aa",
			"AREANAME": "Apartment",
			"TIMEPLAYED": 120,
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "SAVEGAMENAME", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "LASTMODULE", "type": GFFParser.FIELD_CRESREF},
				{"name": "AREANAME", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "TIMEPLAYED", "type": GFFParser.FIELD_DWORD},
			],
		},
	}
