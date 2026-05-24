@tool
extends SceneTree

const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorMainScreen := preload("../../editor/workspace/kotor_main_screen.gd")
const KotorWorkspaceShell := preload("../../ui/workspace/kotor_workspace_shell.gd")
const KotorDLGWorkspaceEditor := preload("../../ui/workspace/editors/dlg_workspace_editor.gd")

var _main_screen: Control
var _workspace_shell: Control


func _initialize() -> void:
	var controller := KotorWorkspaceController.new()
	_workspace_shell = KotorWorkspaceShell.new()
	_workspace_shell.setup(controller)
	root.add_child(_workspace_shell)
	_main_screen = KotorMainScreen.new()
	_main_screen.setup(controller)
	root.add_child(_main_screen)
	call_deferred("_assert_host_composition")


func _assert_host_composition() -> void:
	assert(_workspace_shell.get_child_count() == 1)
	assert(_main_screen.get_child_count() == 1)
	assert(_main_screen.get_child(0) is Control)
	assert(_workspace_shell.get_child(0) is Control)
	assert(_workspace_shell.get_dlg_workspace_editor() is KotorDLGWorkspaceEditor)
	quit()
