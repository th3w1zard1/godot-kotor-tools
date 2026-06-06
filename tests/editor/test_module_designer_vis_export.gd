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
	_install_root = ProjectSettings.globalize_path("user://module_designer_vis_export_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_visibility_export_fails()
	_test_visibility_export_button_wired()
	_test_visibility_export_roundtrip()
	_cleanup()
	print("✓ Module designer VIS export tests passed")
	quit()


func _test_no_visibility_export_fails() -> void:
	var editor := _build_editor()
	var result := editor.export_visibility_preview_to_path(_install_root.path_join("visibility_export"))
	assert(not result.get("ok", true))
	print("✓ VIS export without loaded visibility failed as expected")


func _test_visibility_export_button_wired() -> void:
	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(_find_toolbar_button(editor, "Export VIS Preview…") != null)
	print("✓ VIS export toolbar wiring passed")


func _test_visibility_export_roundtrip() -> void:
	var vis_text := "room_a 2\n  room_a\n  room_b\nroom_b 1\n  room_b\n"
	var vis_path := _install_root.path_join("override").path_join("tar_m02aa.vis")
	var seed_file := FileAccess.open(vis_path, FileAccess.WRITE)
	seed_file.store_string(vis_text)
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	var export_base := _install_root.path_join("exported_visibility")
	var result := editor.export_visibility_preview_to_path(export_base)
	assert(result.get("ok", false))
	var target_path := str(result.get("path", ""))
	assert(target_path.ends_with(".vis"))
	assert(FileAccess.file_exists(target_path))

	var file := FileAccess.open(target_path, FileAccess.READ)
	var exported := VISParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(VISParser.room_count(exported) == 2)
	var rooms: Dictionary = exported.get("rooms", {})
	var room_a_children: Array = rooms.get("room_a", [])
	assert(room_a_children.has("room_b"))
	print("✓ VIS export roundtrip passed")


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
	for path in [
		_install_root.path_join("override").path_join("tar_m02aa.vis"),
		_install_root.path_join("exported_visibility.vis"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
