@tool
extends Control

const KotorDock := preload("../../ui/kotor_dock.gd")
const KotorEditorState := preload("../core/kotor_editor_state.gd")

var _editor_state: RefCounted
var _mutation_service: RefCounted
var _dock: Control


func _init(editor_state: RefCounted = null) -> void:
	_editor_state = editor_state
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(editor_state: RefCounted, mutation_service: RefCounted = null) -> void:
	_editor_state = editor_state
	_mutation_service = mutation_service
	if is_node_ready():
		_ensure_dock()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ensure_dock()


func _ensure_dock() -> void:
	if _dock != null:
		return
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_dock = KotorDock.new()
	_dock.setup(_editor_state, _mutation_service)
	_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dock)


func get_dock() -> Control:
	return _dock


func open_gamefs_entry(entry: Dictionary) -> void:
	if _dock != null and _dock.has_method("open_gamefs_entry"):
		_dock.call("open_gamefs_entry", entry)
