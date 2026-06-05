@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const BwmParserTest := preload("test_bwm_parser.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_walkmesh_install_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_walkmesh_install_fails()
	_test_walkmesh_file_name()
	_test_walkmesh_install_roundtrip()
	_cleanup()
	print("✓ Module designer walkmesh install tests passed")
	quit()


func _test_no_walkmesh_install_fails() -> void:
	var editor := _build_editor()
	var result := editor.install_walkmesh_to_override()
	assert(not result.get("ok", true))
	print("✓ Walkmesh install without loaded mesh failed as expected")


func _test_walkmesh_file_name() -> void:
	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(editor.walkmesh_file_name() == "tar_m02aa.wok")
	print("✓ Walkmesh file name helper passed")


func _test_walkmesh_install_roundtrip() -> void:
	var wok_bytes: PackedByteArray = BwmParserTest._build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var wok_path := _install_root.path_join("override").path_join("tar_m02aa.wok")
	var seed_file := FileAccess.open(wok_path, FileAccess.WRITE)
	seed_file.store_buffer(wok_bytes)
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(not editor.serialize_loaded_walkmesh_bytes().is_empty())

	DirAccess.remove_absolute(wok_path)
	assert(not FileAccess.file_exists(wok_path))

	var result := editor.install_walkmesh_to_override()
	assert(result.get("ok", false))
	assert(result.get("applied", false))
	assert(FileAccess.file_exists(wok_path))

	var file := FileAccess.open(wok_path, FileAccess.READ)
	var installed := BWMParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(int(installed.get("face_count", 0)) == 1)
	assert(int(installed.get("vertex_count", 0)) == 3)
	print("✓ Walkmesh install roundtrip passed")


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
	var wok_path := _install_root.path_join("override").path_join("tar_m02aa.wok")
	if FileAccess.file_exists(wok_path):
		DirAccess.remove_absolute(wok_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
