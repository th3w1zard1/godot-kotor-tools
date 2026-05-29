@tool
extends "./kotor_workspace_editor.gd"
class_name KotorIndoorBuilderWorkspaceEditor

const KotorIndoorDocument := preload("../../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("../../../resources/indoor/kotor_indoor_map_io.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const IndoorBuilderMapView := preload("../panels/indoor_builder_map_view.gd")

const INDOOR_EXTENSIONS := ["indoor"]

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _detail_label: Label
var _room_tree: Tree
var _map_view: IndoorBuilderMapView

var _document: KotorIndoorDocument
var _source_path := ""
var _file_name := "layout.indoor"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_bytes: PackedByteArray
var _pending_source_path := ""
var _pending_file_name := ""


func _on_workspace_setup() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_build_ui()
	if not _pending_bytes.is_empty():
		var pending_bytes := _pending_bytes
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_bytes = PackedByteArray()
		_pending_source_path = ""
		_pending_file_name = ""
		open_indoor_bytes(pending_file_name, pending_bytes, pending_source_path)


func open_indoor_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_clear_document_state("Failed to open %s" % path.get_file())
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_indoor_bytes(path, bytes, path if indoor_extension_allowed(path.get_extension()) else "")


func open_indoor_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	if not is_node_ready():
		_pending_bytes = data
		_pending_source_path = source_path
		_pending_file_name = label
		return
	var document := KotorIndoorDocument.new()
	if not document.load_from_bytes(data):
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "layout.indoor"))
		return
	_set_document(document, source_path, _guess_loaded_file_name(label, "layout.indoor"))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


static func indoor_extension_allowed(extension: String) -> bool:
	return extension.strip_edges().to_lower() in INDOOR_EXTENSIONS


func has_document() -> bool:
	return _document != null


func get_document() -> KotorIndoorDocument:
	return _document


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No indoor map is loaded."}
	var target_path := _ensure_extension(path, "indoor")
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		_status_text = "Failed to write %s" % target_path.get_file()
		_refresh_status()
		return {"ok": false, "message": _status_text}
	file.store_buffer(_document.serialize_to_bytes())
	file.close()
	var previous_key := _document_key
	_source_path = target_path
	_file_name = target_path.get_file()
	_dirty = false
	_register_controller_document()
	_remove_previous_controller_document(previous_key)
	_update_controller_dirty_state()
	_status_text = "Saved %s" % _file_name
	_refresh_status()
	return {"ok": true, "applied": true, "message": _status_text}


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open"
	open_btn.pressed.connect(_open_indoor_dialog)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_indoor)
	_toolbar.add_child(save_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toolbar.add_child(_path_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(260, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left_panel)

	_room_tree = Tree.new()
	_room_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_room_tree.item_selected.connect(_on_room_tree_selected)
	left_panel.add_child(_room_tree)

	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(_detail_label)

	_map_view = IndoorBuilderMapView.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.room_selected.connect(_on_map_room_selected)
	_map_view.room_drag_finished.connect(_on_map_room_drag_finished)
	_map_view.room_rotate_finished.connect(_on_map_room_rotate_finished)
	split.add_child(_map_view)


func _set_document(document: KotorIndoorDocument, source_path: String, file_name: String) -> void:
	_disconnect_document_signal()
	_document = document
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "layout.indoor"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_connect_document_signal()
	_refresh_view()


func _refresh_view() -> void:
	if _document == null:
		return
	_refresh_path_label()
	_refresh_summary()
	_refresh_room_tree()
	_refresh_map()
	_refresh_status()


func _refresh_path_label() -> void:
	if _path_label == null:
		return
	var path_text := _source_path if not _source_path.is_empty() else _current_file_name()
	_path_label.text = "%s%s" % [path_text, " *" if _dirty else ""]


func _refresh_summary() -> void:
	if _summary_label == null or _document == null:
		return
	_summary_label.text = "\n".join(_document.get_summary_lines())


func _refresh_room_tree() -> void:
	if _room_tree == null or _document == null:
		return
	_room_tree.clear()
	var root := _room_tree.create_item()
	root.set_text(0, "Rooms")
	for record in _document.get_room_records():
		var item := _room_tree.create_item(root)
		item.set_text(0, "%d: %s" % [int(record.get("index", 0)), str(record.get("label", "Room"))])
		item.set_metadata(0, record)


func _refresh_map() -> void:
	if _map_view == null or _document == null:
		return
	_map_view.set_rooms(_document.get_room_records(), _document.get_layout_bounds())


func _refresh_status() -> void:
	_emit_status_text(_status_text)
	_emit_dirty_state(_dirty)


func _on_room_tree_selected() -> void:
	var selected := _room_tree.get_selected()
	if selected == null:
		return
	var record = selected.get_metadata(0)
	if typeof(record) != TYPE_DICTIONARY:
		return
	_select_room(int(record.get("index", -1)))


func _on_map_room_selected(index: int) -> void:
	_select_room(index)


func _on_map_room_drag_finished(
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
) -> void:
	_apply_room_position_with_undo(index, old_x, old_y, new_x, new_y)


func _on_map_room_rotate_finished(index: int, old_rotation: float, new_rotation: float) -> void:
	_apply_room_rotation_with_undo(index, old_rotation, new_rotation)


func _select_room(index: int) -> void:
	var record := _document.find_room_record(index) if _document != null else {}
	if record.is_empty():
		return
	if _detail_label != null:
		_detail_label.text = (
			"Room #%d\nLabel: %s\nPosition: %.2f, %.2f, %.2f\nRotation: %.2f"
			% [
				int(record.get("index", 0)),
				str(record.get("label", "")),
				float(record.get("x", 0.0)),
				float(record.get("y", 0.0)),
				float(record.get("z", 0.0)),
				float(record.get("rotation", 0.0)),
			]
		)
	if _map_view != null:
		_map_view.set_selection(index)
	_select_tree_record(record)


func _select_tree_record(record: Dictionary) -> void:
	if _room_tree == null:
		return
	var root := _room_tree.get_root()
	if root == null:
		return
	for item in root.get_children():
		var metadata = item.get_metadata(0)
		if typeof(metadata) != TYPE_DICTIONARY:
			continue
		if int(metadata.get("index", -1)) == int(record.get("index", -1)):
			item.select(0)
			return


func _clear_document_state(message: String) -> void:
	_disconnect_document_signal()
	_document = null
	_source_path = ""
	_file_name = "layout.indoor"
	_dirty = false
	_status_text = message
	if _room_tree != null:
		_room_tree.clear()
	if _map_view != null:
		_map_view.set_rooms([], Rect2())
	if _detail_label != null:
		_detail_label.text = ""
	_refresh_path_label()
	_refresh_summary()
	_refresh_status()


func _connect_document_signal() -> void:
	if _document != null and not _document.changed.is_connected(_on_document_changed):
		_document.changed.connect(_on_document_changed)


func _disconnect_document_signal() -> void:
	if _document != null and _document.changed.is_connected(_on_document_changed):
		_document.changed.disconnect(_on_document_changed)


func _on_document_changed() -> void:
	_dirty = true
	_update_controller_dirty_state()
	_refresh_path_label()
	_refresh_summary()
	_refresh_room_tree()
	_refresh_map()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"indoor",
		null,
		_document,
		_source_path,
		_current_file_name(),
		{}
	)
	_document_key = str(entry.get("key", ""))


func _update_controller_dirty_state() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_dirty"):
		return
	controller.call("update_document_dirty", _document_key, _dirty)


func _remove_previous_controller_document(previous_key: String) -> void:
	var controller := get_controller()
	if controller == null or previous_key.is_empty() or previous_key == _document_key or not controller.has_method("remove_document"):
		return
	controller.call("remove_document", previous_key)


func _get_undo_redo() -> EditorUndoRedoManager:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_undo_redo()
	return null


func _apply_room_position_with_undo(
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Move indoor room", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_room_position", index, new_x, new_y)
		ur.add_undo_method(self, "_exec_room_position", index, old_x, old_y)
		ur.commit_action()
	else:
		_exec_room_position(index, new_x, new_y)


func _exec_room_position(index: int, x: float, y: float) -> void:
	if _document == null:
		return
	if not _document.set_room_position(index, x, y):
		return
	_select_room(index)


func _apply_room_rotation_with_undo(index: int, old_rotation: float, new_rotation: float) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Rotate indoor room", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_room_rotation", index, new_rotation)
		ur.add_undo_method(self, "_exec_room_rotation", index, old_rotation)
		ur.commit_action()
	else:
		_exec_room_rotation(index, new_rotation)


func _exec_room_rotation(index: int, rotation: float) -> void:
	if _document == null:
		return
	if not _document.set_room_rotation(index, rotation):
		return
	_select_room(index)


func _open_indoor_dialog() -> void:
	if not Engine.is_editor_hint():
		return
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Open Indoor Map"
	dialog.add_filter("*.indoor", "Indoor Map")
	dialog.file_selected.connect(func(path: String) -> void:
		open_indoor_file(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_indoor() -> void:
	if _document == null:
		return
	if not _source_path.is_empty():
		save_document_to_path(_source_path)
		return
	if not Engine.is_editor_hint():
		return
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Save Indoor Map"
	dialog.current_file = _current_file_name()
	dialog.add_filter("*.indoor", "Indoor Map")
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _current_file_name() -> String:
	return _file_name if not _file_name.is_empty() else "layout.indoor"


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	if label.is_empty():
		return fallback
	if label.is_absolute_path():
		return label.get_file()
	return label.get_file() if label.contains(".") else fallback


func _ensure_extension(path: String, extension: String) -> String:
	var normalized := path.strip_edges()
	if normalized.get_extension().to_lower() == extension:
		return normalized
	return "%s.%s" % [normalized, extension]
