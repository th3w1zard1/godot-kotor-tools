@tool
extends SceneTree

const KotorDock := preload("../../ui/kotor_dock.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")

var _noop_done := false
var _apply_done := false


func _initialize() -> void:
	call_deferred("_assert_dock_preflight_routing")


func _assert_dock_preflight_routing() -> void:
	var state := KotorEditorState.new()
	var controller := KotorWorkspaceController.new(state)
	var dock := KotorDock.new()
	dock.setup(state, controller.mutation_service)

	_noop_done = false
	dock._run_mutation_preflight(
		{"ok": true, "action": "noop", "message": "Already up to date"},
		Callable(self, "_fail_if_apply_called"),
		Callable(self, "_on_noop_complete")
	)
	assert(_noop_done)

	dock._skip_preflight_for_testing = true
	_apply_done = false
	dock._run_mutation_preflight(
		{"ok": true, "action": "create"},
		Callable(self, "_apply_with_proceed"),
		Callable(self, "_on_apply_complete")
	)
	assert(_apply_done)

	quit()


func _fail_if_apply_called(_proceed: bool) -> Dictionary:
	assert(false, "apply_fn must not run for noop previews")
	return {}


func _on_noop_complete(result: Dictionary) -> void:
	assert(not result.get("applied", true))
	_noop_done = true


func _apply_with_proceed(proceed: bool) -> Dictionary:
	assert(proceed)
	return {"ok": true, "applied": true}


func _on_apply_complete(result: Dictionary) -> void:
	assert(result.get("applied", false))
	_apply_done = true
