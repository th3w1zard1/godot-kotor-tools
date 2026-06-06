@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const PTHResource := preload("../../resources/typed/pth_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_pth_install_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_no_pth_install_fails()
	_test_pth_button_and_file_name()
	_test_pth_load_summary_and_install_roundtrip()
	_cleanup()
	print("✓ Module designer PTH install tests passed")
	quit()


func _test_no_pth_install_fails() -> void:
	var editor := _build_editor()
	var result := editor.install_pth_to_override()
	assert(not result.get("ok", true))
	print("✓ PTH install without loaded path graph failed as expected")


func _test_pth_button_and_file_name() -> void:
	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(editor.pth_file_name() == "tar_m02aa.pth")
	assert(_find_toolbar_button(editor, "Install PTH to Override") != null)
	print("✓ PTH file name helper and toolbar wiring passed")


func _test_pth_load_summary_and_install_roundtrip() -> void:
	var pth_path := _install_root.path_join("override").path_join("tar_m02aa.pth")
	var seed_file := FileAccess.open(pth_path, FileAccess.WRITE)
	seed_file.store_buffer(_build_pth_bytes())
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	assert(editor._path_resource != null)
	assert(editor._path_resource.get_point_count() == 2)
	assert(editor._summary_label.text.find("PTH: 2 point(s) via Path_Points") >= 0)

	DirAccess.remove_absolute(pth_path)
	assert(not FileAccess.file_exists(pth_path))

	var result := editor.install_pth_to_override()
	assert(result.get("ok", false))
	assert(result.get("applied", false))
	assert(FileAccess.file_exists(pth_path))

	var file := FileAccess.open(pth_path, FileAccess.READ)
	var parsed := GFFParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	var resource := GFFResourceFactory.create_from_parser_result(parsed) as PTHResource
	assert(resource != null)
	assert(resource.get_point_count() == 2)
	print("✓ PTH load, summary, and install roundtrip passed")


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


func _build_pth_bytes() -> PackedByteArray:
	var parsed := {
		"file_type": "PTH",
		"root": {
			"Tag": "module_paths",
			"Path_Points": [
				{"ID": 1},
				{"ID": 2},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
				{
					"name": "Path_Points",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{"name": "ID", "type": GFFParser.FIELD_INT},
							],
						},
					],
				},
			],
		},
	}
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	return GFFWriter.serialize(resource)


func _find_toolbar_button(editor: KotorModuleDesignerWorkspaceEditor, label: String) -> Button:
	for child in editor._toolbar.get_children():
		if child is Button and child.text == label:
			return child
	return null


func _cleanup() -> void:
	var pth_path := _install_root.path_join("override").path_join("tar_m02aa.pth")
	if FileAccess.file_exists(pth_path):
		DirAccess.remove_absolute(pth_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
