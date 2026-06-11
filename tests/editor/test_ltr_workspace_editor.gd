@tool
extends SceneTree

const LTRParser := preload("../../formats/ltr_parser.gd")
const LTRWriter := preload("../../formats/ltr_writer.gd")
const LTRResource := preload("../../resources/ltr_resource.gd")
const KotorLTRWorkspaceEditor := preload("../../ui/workspace/editors/ltr_workspace_editor.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://ltr_workspace_editor_test")
	DirAccess.make_dir_recursive_absolute(_install_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()

	var controller := KotorWorkspaceController.new(state)
	var editor := KotorLTRWorkspaceEditor.new()
	editor.setup(state, controller.mutation_service)
	editor._skip_preflight_for_testing = true
	root.add_child(editor)
	editor._ready()

	var resource := LTRResource.new()
	resource.set_single_probability("middle", 5, 0.42)
	var bytes := LTRWriter.serialize(resource)
	editor.open_ltr_bytes("humanf.ltr", bytes, "")

	assert(not editor.is_document_dirty())

	var loaded_resource: LTRResource = editor._resource
	resource = loaded_resource
	assert(is_equal_approx(resource.get_single_probability("middle", 5), 0.42))

	resource.set_single_probability("start", 1, 0.11)
	editor._dirty = true
	assert(editor.install_document_to_override().get("applied", false))

	var override_path: String = str(state.gamefs.ensure_override_path()).path_join("humanf.ltr")
	assert(FileAccess.file_exists(override_path))
	var installed := FileAccess.open(override_path, FileAccess.READ)
	assert(installed != null)
	var installed_parsed := LTRParser.parse_bytes(installed.get_buffer(installed.get_length()))
	installed.close()
	assert(is_equal_approx(float(installed_parsed.get("singles", {}).get("start", [])[1]), 0.11))

	_cleanup()
	print("✓ LTR workspace editor tests passed")
	quit()


func _cleanup() -> void:
	var override_path := _install_root.path_join("override").path_join("humanf.ltr")
	if FileAccess.file_exists(override_path):
		DirAccess.remove_absolute(override_path)
	for directory in [_install_root.path_join("override"), _install_root]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
