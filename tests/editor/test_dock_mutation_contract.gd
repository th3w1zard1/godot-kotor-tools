@tool
extends SceneTree

const KotorDock := preload("../../ui/kotor_dock.gd")
const KotorEditorShell := preload("../../editor/shell/kotor_editor_shell.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://dock_mutation_contract")
	DirAccess.make_dir_recursive_absolute(_install_root)
	call_deferred("_assert_dock_mutation_contract")


func _assert_dock_mutation_contract() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()

	var controller := KotorWorkspaceController.new(state)
	var dock := KotorDock.new()
	dock.setup(state, controller.mutation_service)
	assert(dock._mutation_service == controller.mutation_service)

	var install_result: Dictionary = dock._mutation_service.apply_install_to_override(
		state.gamefs,
		"dock_route_test.nss",
		"void main() {}\n"
	)
	assert(install_result.get("applied", false))
	assert(controller.list_transactions().size() >= 1)

	var shell := KotorEditorShell.new()
	shell.setup(state, controller.mutation_service)
	shell._ready()
	assert(shell._dock != null)
	assert(shell._dock._mutation_service == controller.mutation_service)

	_cleanup()
	quit()


func _cleanup() -> void:
	var override_file := _install_root.path_join("override").path_join("dock_route_test.nss")
	if FileAccess.file_exists(override_file):
		DirAccess.remove_absolute(override_file)
	for directory in [_install_root.path_join("override"), _install_root]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
