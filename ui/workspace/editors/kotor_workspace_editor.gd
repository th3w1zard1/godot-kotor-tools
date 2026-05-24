@tool
extends VBoxContainer
class_name KotorWorkspaceEditor

signal dirty_state_changed(is_dirty: bool)
signal status_text_changed(text: String)

var _editor_state: RefCounted
var _controller: RefCounted


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(editor_state: RefCounted, controller: RefCounted = null) -> void:
	_editor_state = editor_state
	_controller = controller
	if is_node_ready():
		_on_workspace_setup()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_on_workspace_setup()


func get_editor_state() -> RefCounted:
	return _editor_state


func get_controller() -> RefCounted:
	return _controller


func is_dirty() -> bool:
	return false


func get_status_text() -> String:
	return ""


func open_document(_document: Variant, _resource: Variant = null) -> void:
	pass


func _on_workspace_setup() -> void:
	pass


func _emit_dirty_state(is_dirty_value: bool) -> void:
	dirty_state_changed.emit(is_dirty_value)


func _emit_status_text(text: String) -> void:
	status_text_changed.emit(text)
