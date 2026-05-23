@tool
extends RefCounted
class_name KotorWorkspaceController

const KotorEditorState := preload("../core/kotor_editor_state.gd")

var editor_state: RefCounted


func _init(state: RefCounted = null) -> void:
	editor_state = state if state != null else KotorEditorState.new()


func setup(state: RefCounted) -> void:
	editor_state = state if state != null else editor_state
