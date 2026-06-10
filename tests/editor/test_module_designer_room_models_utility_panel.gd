@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const LYTWriter := preload("../../formats/lyt_writer.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_room_models_utility_panel_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_room_model_entry_helper()
	var panel_ok := await _test_room_models_tree_detail_and_open()
	_cleanup()
	if not panel_ok:
		push_error("Room models utility panel tests failed")
		quit(1)
	print("✓ Module designer room models utility panel tests passed")
	quit()


func _test_room_model_entry_helper() -> void:
	var layout := {
		"rooms": [
			{"model": "room_b", "position": Vector3(2.0, 0.0, 1.0)},
			{"model": "room_a", "position": Vector3(1.0, 0.0, 2.0)},
			{"model": "room_a", "position": Vector3(3.0, 0.0, 3.0)},
		],
	}
	var records := KotorModuleContext.get_room_model_entries(layout, null)
	assert(records.size() == 2)
	assert(records[0].get("model") == "room_a")
	assert(records[1].get("model") == "room_b")
	var presence := KotorModuleContext.format_room_model_presence(records[0])
	assert(presence.find("MDL missing") >= 0)
	print("✓ Room model entry helper passed")


func _test_room_models_tree_detail_and_open() -> bool:
	var override_dir := _install_root.path_join("override")
	_write_bytes(override_dir.path_join("tar_m02aa.git"), _build_minimal_git_bytes())
	_write_bytes(override_dir.path_join("tar_m02aa.lyt"), _build_layout_bytes())
	_write_bytes(override_dir.path_join("room_a.mdl"), PackedByteArray([0x00, 0x01, 0x02]))

	var editor := _build_editor()
	var opened: Array[Dictionary] = []
	editor.bundle_resource_open_requested.connect(func(entry: Dictionary) -> void:
		opened.append(entry)
	)
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	await process_frame

	assert(editor._room_models_tree.visible)
	var root := editor._room_models_tree.get_root()
	assert(root.get_child_count() == 1)
	var room_item := root.get_first_child()
	assert(str(room_item.get_text(0)).begins_with("room_a"))
	assert(str(room_item.get_text(0)).find("MDL ✓") >= 0)

	editor._room_models_tree.set_selected(room_item, 0)
	editor._on_room_models_tree_item_selected()
	await process_frame
	assert(editor._detail_label.text.find("Room Model: room_a") >= 0)
	assert(editor._detail_label.text.find("MDL ✓") >= 0)

	editor._on_room_models_tree_item_activated()
	await process_frame
	assert(opened.size() == 1)
	assert(str(opened[0].get("extension", "")) == "mdl")
	print("✓ Room models tree detail and open signal passed")
	return true


func _build_editor() -> KotorModuleDesignerWorkspaceEditor:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	editor._skip_preflight_for_testing = true
	editor.setup(editor_state, controller)
	root.add_child(editor)
	return editor


func _build_git_resource() -> GITResource:
	var parsed := {
		"file_type": "GIT ",
		"root": {
			"Creature List": [],
			"Door List": [],
			"Encounter List": [],
			"Placeable List": [],
			"SoundList": [],
			"StoreList": [],
			"TriggerList": [],
			"WaypointList": [],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	}
	return GFFResourceFactory.create_from_parser_result(parsed) as GITResource


func _build_layout_bytes() -> PackedByteArray:
	return LYTWriter.write_bytes({
		"rooms": [{"model": "room_a", "position": Vector3(4.0, 5.0, 6.0)}],
		"tracks": [],
		"obstacles": [],
		"doorhooks": [],
	})


func _build_minimal_git_bytes() -> PackedByteArray:
	const GFFParser := preload("../../formats/gff_parser.gd")
	const GFFWriter := preload("../../formats/gff_writer.gd")
	var parsed := {
		"file_type": "GIT ",
		"root": {
			"Creature List": [],
			"Door List": [],
			"Encounter List": [],
			"Placeable List": [],
			"SoundList": [],
			"StoreList": [],
			"TriggerList": [],
			"WaypointList": [],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	}
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(parsed))


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _cleanup() -> void:
	var override_dir := _install_root.path_join("override")
	for file_name in ["tar_m02aa.git", "tar_m02aa.lyt", "room_a.mdl"]:
		var path := override_dir.path_join(file_name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(override_dir):
		DirAccess.remove_absolute(override_dir)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
