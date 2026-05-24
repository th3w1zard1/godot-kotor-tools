@tool
extends SceneTree

const KotorDock := preload("../../ui/kotor_dock.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")

var _delegated := false
var _captured: Dictionary = {}


func _initialize() -> void:
	call_deferred("_assert_dock_workspace_routing")


func _assert_dock_workspace_routing() -> void:
	var dock := KotorDock.new()
	var state := KotorEditorState.new()
	dock.setup(state)

	_delegated = false
	_captured = {}
	dock.set_workspace_entry_opener(Callable(self, "_capture_workspace_entry"))

	dock.open_gamefs_entry({
		"resref": "player",
		"extension": "utc",
		"source": "override",
	})
	assert(_delegated)
	assert(str(_captured.get("resref", "")) == "player")

	_delegated = false
	dock.set_workspace_entry_opener(Callable())
	dock.open_gamefs_entry({
		"resref": "player",
		"extension": "utc",
		"source": "override",
	})
	assert(not _delegated)

	assert(dock._should_delegate_to_workspace_editor("utc"))
	assert(not dock._should_delegate_to_workspace_editor("jrl"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("are"))

	quit()


func _capture_workspace_entry(entry: Dictionary) -> void:
	_delegated = true
	_captured = entry
