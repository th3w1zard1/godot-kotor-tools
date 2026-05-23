@tool
extends Control

const KotorEditorShell := preload("../../editor/shell/kotor_editor_shell.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")

var _controller: RefCounted
var _shell: Control


func _init(controller: RefCounted = null) -> void:
	_controller = controller
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(controller: RefCounted) -> void:
	_controller = controller
	if is_node_ready():
		_ensure_shell()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ensure_shell()


func _ensure_shell() -> void:
	if _shell != null:
		return
	_shell = KotorEditorShell.new()
	_shell.setup(_resolve_editor_state())
	_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shell)


func _resolve_editor_state() -> RefCounted:
	if _controller != null:
		var controller_state = _controller.get("editor_state")
		if controller_state != null:
			return controller_state
	var fallback := KotorEditorState.new()
	fallback.load_settings()
	return fallback
