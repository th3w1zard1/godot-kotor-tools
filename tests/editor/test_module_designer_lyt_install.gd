@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const LYTParser := preload("../../formats/lyt_parser.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_lyt_install_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_layout_install_fails()
	_test_layout_file_name()
	_test_layout_install_roundtrip()
	_cleanup()
	print("✓ Module designer LYT install tests passed")
	quit()


func _test_no_layout_install_fails() -> void:
	var editor := _build_editor()
	var result := editor.install_layout_to_override()
	assert(not result.get("ok", true))
	print("✓ LYT install without loaded layout failed as expected")


func _test_layout_file_name() -> void:
	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(editor.layout_file_name() == "tar_m02aa.lyt")
	print("✓ LYT file name helper passed")


func _test_layout_install_roundtrip() -> void:
	var lyt_text := "beginlayout\nroomcount 1\nroommodel room001 0.0 0.0 0.0\ndonelayout\n"
	var lyt_path := _install_root.path_join("override").path_join("tar_m02aa.lyt")
	var seed_file := FileAccess.open(lyt_path, FileAccess.WRITE)
	seed_file.store_string(lyt_text)
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(not editor.serialize_loaded_layout_bytes().is_empty())

	DirAccess.remove_absolute(lyt_path)
	assert(not FileAccess.file_exists(lyt_path))

	var result := editor.install_layout_to_override()
	assert(result.get("ok", false))
	assert(result.get("applied", false))
	assert(FileAccess.file_exists(lyt_path))

	var file := FileAccess.open(lyt_path, FileAccess.READ)
	var installed := LYTParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(installed.get("rooms", []).size() == 1)
	print("✓ LYT install roundtrip passed")


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


func _cleanup() -> void:
	var lyt_path := _install_root.path_join("override").path_join("tar_m02aa.lyt")
	if FileAccess.file_exists(lyt_path):
		DirAccess.remove_absolute(lyt_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
