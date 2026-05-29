@tool
extends SceneTree

const KotorDock := preload("../../ui/kotor_dock.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")

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
	_captured = {}
	dock.open_gamefs_entry({
		"resref": "tar_m02aa",
		"extension": "git",
		"source": "override",
	})
	assert(_delegated)
	assert(str(_captured.get("extension", "")) == "git")

	_delegated = false
	dock.set_workspace_entry_opener(Callable())
	dock.open_gamefs_entry({
		"resref": "player",
		"extension": "utc",
		"source": "override",
	})
	assert(not _delegated)

	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("are"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("jrl"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("pth"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("fac"))
	assert(not KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("git"))
	assert(KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed("git"))

	quit()


func _capture_workspace_entry(entry: Dictionary) -> void:
	_delegated = true
	_captured = entry
