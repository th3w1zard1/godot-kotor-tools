@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const VISParser := preload("../../formats/vis_parser.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_vis_install_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_visibility_install_fails()
	_test_visibility_button_and_file_name()
	_test_visibility_load_summary_and_install_roundtrip()
	_cleanup()
	print("✓ Module designer VIS install tests passed")
	quit()


func _test_no_visibility_install_fails() -> void:
	var editor := _build_editor()
	var result := editor.install_visibility_to_override()
	assert(not result.get("ok", true))
	print("✓ VIS install without loaded visibility failed as expected")


func _test_visibility_button_and_file_name() -> void:
	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(editor.visibility_file_name() == "tar_m02aa.vis")
	assert(_find_toolbar_button(editor, "Install VIS to Override") != null)
	print("✓ VIS file name helper and toolbar wiring passed")


func _test_visibility_load_summary_and_install_roundtrip() -> void:
	var vis_text := "room_a 2\n  room_a\n  room_b\nroom_b 1\n  room_b\n"
	var vis_path := _install_root.path_join("override").path_join("tar_m02aa.vis")
	var seed_file := FileAccess.open(vis_path, FileAccess.WRITE)
	seed_file.store_string(vis_text)
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(not editor.serialize_loaded_visibility_bytes().is_empty())
	assert(VISParser.room_count(editor._parsed_visibility) == 2)
	assert(editor._summary_label.text.find("VIS: 2 room visibility group") >= 0)

	DirAccess.remove_absolute(vis_path)
	assert(not FileAccess.file_exists(vis_path))

	var result := editor.install_visibility_to_override()
	assert(result.get("ok", false))
	assert(result.get("applied", false))
	assert(FileAccess.file_exists(vis_path))

	var file := FileAccess.open(vis_path, FileAccess.READ)
	var installed := VISParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(VISParser.room_count(installed) == 2)
	print("✓ VIS load, summary, and install roundtrip passed")


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
		"root": {},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	}
	return GFFResourceFactory.create_from_parser_result(parsed) as GITResource


func _find_toolbar_button(editor: KotorModuleDesignerWorkspaceEditor, label: String) -> Button:
	for child in editor._toolbar.get_children():
		if child is Button and child.text == label:
			return child
	return null


func _cleanup() -> void:
	var vis_path := _install_root.path_join("override").path_join("tar_m02aa.vis")
	if FileAccess.file_exists(vis_path):
		DirAccess.remove_absolute(vis_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
