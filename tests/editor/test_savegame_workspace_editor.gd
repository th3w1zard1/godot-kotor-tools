@tool
extends SceneTree

const ERFWriter := preload("../../formats/erf_writer.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorErfDocument := preload("../../resources/documents/kotor_erf_document.gd")
const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const KotorSavegameWorkspaceEditor := preload("../../ui/workspace/editors/savegame_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://savegame_workspace_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


var _install_root := ""


func _run_tests() -> void:
	_test_open_save_and_summary()
	_test_member_payload_access()
	_test_member_open_routes_gff_inspect()
	await _test_extract_member_to_override()
	await _test_extract_all_members_to_override()
	await _test_extract_all_skips_invalid_members()
	await _test_replace_member_and_save_round_trip()
	_cleanup()
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


func _test_extract_member_to_override() -> void:
	var editor := _build_editor()
	editor.open_save_bytes("slot1.sav", _build_test_sav_bytes(), "")
	await process_frame

	var target_path := _install_root.path_join("override").path_join("savenfo.txt")
	if FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(target_path)

	var result := editor.install_member_to_override(0)
	assert(result.get("ok", false), "Extract failed: %s" % str(result))
	assert(result.get("applied", false), "Extract not applied: %s" % str(result))
	assert(FileAccess.file_exists(target_path))
	var file := FileAccess.open(target_path, FileAccess.READ)
	var parsed := GFFParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(not parsed.is_empty())
	print("✓ Savegame extract member to override passed")


func _test_extract_all_members_to_override() -> void:
	var editor := _build_editor()
	editor.open_save_bytes("slot1.sav", _build_multi_member_sav_bytes(), "")
	await process_frame

	var savenfo_path := _install_root.path_join("override").path_join("savenfo.txt")
	var partytable_path := _install_root.path_join("override").path_join("partytable.txt")
	for path in [savenfo_path, partytable_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	var result := editor.extract_all_members_to_override()
	assert(result.get("ok", false), "Extract all failed: %s" % str(result))
	assert(int(result.get("applied", 0)) == 2, str(result))
	assert(FileAccess.file_exists(savenfo_path))
	assert(FileAccess.file_exists(partytable_path))
	print("✓ Savegame extract all members to override passed")


func _test_extract_all_skips_invalid_members() -> void:
	var editor := _build_editor()
	editor.open_save_bytes("slot1.sav", _build_sav_bytes_with_invalid_member(), "")
	await process_frame

	var savenfo_path := _install_root.path_join("override").path_join("savenfo.txt")
	if FileAccess.file_exists(savenfo_path):
		DirAccess.remove_absolute(savenfo_path)

	var result := editor.extract_all_members_to_override()
	assert(result.get("ok", false), str(result))
	assert(int(result.get("applied", 0)) == 1)
	assert(int(result.get("skipped", 0)) == 1)
	assert(int(result.get("failed", 0)) == 0)
	assert(FileAccess.file_exists(savenfo_path))
	print("✓ Savegame extract all skips invalid members passed")


func _test_replace_member_and_save_round_trip() -> void:
	var editor := _build_editor()
	editor.open_save_bytes("slot1.sav", _build_test_sav_bytes(), "")
	await process_frame

	var replacement := _build_gff_bytes({
		"file_type": "GFF ",
		"root": {"ModuleName": "Edited Save"},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [{"name": "ModuleName", "type": GFFParser.FIELD_CEXOSTRING}],
		},
	})
	var replace_result := editor.replace_member_at(0, replacement)
	assert(replace_result.get("ok", false), str(replace_result))
	assert(editor.is_document_dirty())

	var out_path := _install_root.path_join("edited_slot.sav")
	var save_result := editor.save_savegame_to_path(out_path)
	assert(save_result.get("ok", false), str(save_result))
	assert(FileAccess.file_exists(out_path))
	assert(not editor.is_document_dirty())

	var round_trip := KotorSavegameWorkspaceEditor.new()
	round_trip.setup(_build_editor_state(), _build_controller())
	root.add_child(round_trip)
	round_trip._ready()
	round_trip.open_save_file(out_path)
	var reopened: KotorErfDocument = round_trip.get_document()
	assert(reopened != null)
	assert(reopened.get_entry_count() == 1)
	print("✓ Savegame replace member + save round-trip passed")


func _build_editor_state() -> KotorEditorState:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	return editor_state


func _build_controller() -> KotorWorkspaceController:
	return KotorWorkspaceController.new(_build_editor_state())


func _build_multi_member_sav_bytes() -> PackedByteArray:
	return ERFWriter.build("SAV ", [
		{"resref": "savenfo", "extension": "res", "bytes": _build_gff_bytes(_build_savenfo_parsed())},
		{"resref": "partytable", "extension": "res", "bytes": _build_gff_bytes(_build_partytable_parsed())},
	])


func _build_sav_bytes_with_invalid_member() -> PackedByteArray:
	return ERFWriter.build("SAV ", [
		{"resref": "savenfo", "extension": "res", "bytes": _build_gff_bytes(_build_savenfo_parsed())},
		{"resref": "", "extension": "res", "bytes": _build_gff_bytes(_build_partytable_parsed())},
	])


func _build_partytable_parsed() -> Dictionary:
	return {
		"file_type": "GFF ",
		"root": {
			"PT_MEMBER_COUNT": 1,
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "PT_MEMBER_COUNT", "type": GFFParser.FIELD_DWORD},
			],
		},
	}


func _build_editor() -> KotorSavegameWorkspaceEditor:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorSavegameWorkspaceEditor.new()
	editor.setup(editor_state, controller)
	editor._skip_preflight_for_testing = true
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


func _cleanup() -> void:
	var override_dir := _install_root.path_join("override")
	for file_name in ["savenfo.txt", "partytable.txt"]:
		var target_path := override_dir.path_join(file_name)
		if FileAccess.file_exists(target_path):
			DirAccess.remove_absolute(target_path)
	if DirAccess.dir_exists_absolute(override_dir):
		DirAccess.remove_absolute(override_dir)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
