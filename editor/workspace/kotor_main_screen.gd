@tool
extends Control

const KotorWorkspaceController := preload("kotor_workspace_controller.gd")
const KotorWorkspaceShell := preload("../../ui/workspace/kotor_workspace_shell.gd")

var _controller: RefCounted
var _workspace_shell: Control


func _init(controller: RefCounted = null) -> void:
	_controller = controller
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(controller: RefCounted) -> void:
	_controller = controller
	if is_node_ready():
		_ensure_workspace_shell()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ensure_workspace_shell()


func _ensure_workspace_shell() -> void:
	if _workspace_shell != null:
		return
	if _controller == null:
		_controller = KotorWorkspaceController.new()
	_workspace_shell = KotorWorkspaceShell.new()
	_workspace_shell.setup(_controller)
	_workspace_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_workspace_shell)
