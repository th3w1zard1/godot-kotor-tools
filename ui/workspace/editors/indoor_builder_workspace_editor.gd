@tool
extends "./kotor_workspace_editor.gd"
class_name KotorIndoorBuilderWorkspaceEditor

const KotorIndoorDocument := preload("../../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("../../../resources/indoor/kotor_indoor_map_io.gd")
const KotorIndoorKitLibrary := preload("../../../resources/indoor/kotor_indoor_kit_library.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const IndoorBuilderMapView := preload("../panels/indoor_builder_map_view.gd")

const INDOOR_EXTENSIONS := ["indoor"]

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _detail_label: Label
var _room_tree: Tree
var _map_view: IndoorBuilderMapView
var _kits_path_edit: LineEdit
var _kit_option: OptionButton
var _component_list: ItemList
var _kit_status_label: Label

var _document: KotorIndoorDocument
var _kit_library: KotorIndoorKitLibrary
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
	_kit_library = KotorIndoorKitLibrary.new()
	_kit_library.configure(_editor_state.indoor_kits_path)
	_kit_library.refresh()
	_build_ui()
	_refresh_kit_ui()
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

	var kits_label := Label.new()
	kits_label.text = "Kit library"
	left_panel.add_child(kits_label)

	var kits_path_row := HBoxContainer.new()
	left_panel.add_child(kits_path_row)

	_kits_path_edit = LineEdit.new()
	_kits_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kits_path_edit.placeholder_text = "Path to Holocron kits folder"
	if _editor_state != null:
		_kits_path_edit.text = _editor_state.indoor_kits_path
	_kits_path_edit.text_submitted.connect(_on_kits_path_submitted)
	kits_path_row.add_child(_kits_path_edit)

	var browse_kits_btn := Button.new()
	browse_kits_btn.text = "Browse"
	browse_kits_btn.pressed.connect(_browse_kits_path)
	kits_path_row.add_child(browse_kits_btn)

	var refresh_kits_btn := Button.new()
	refresh_kits_btn.text = "Refresh"
	refresh_kits_btn.pressed.connect(_refresh_kit_library)
	left_panel.add_child(refresh_kits_btn)

	_kit_option = OptionButton.new()
	_kit_option.item_selected.connect(_on_kit_selected)
	left_panel.add_child(_kit_option)

	_component_list = ItemList.new()
	_component_list.custom_minimum_size = Vector2(0, 120)
	_component_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(_component_list)

	var add_room_btn := Button.new()
	add_room_btn.text = "Add room from kit"
	add_room_btn.pressed.connect(_add_room_from_selected_kit)
	left_panel.add_child(add_room_btn)

	var rebuild_hooks_btn := Button.new()
	rebuild_hooks_btn.text = "Rebuild hook connections"
	rebuild_hooks_btn.pressed.connect(_rebuild_hook_connections)
	left_panel.add_child(rebuild_hooks_btn)

	_kit_status_label = Label.new()
	_kit_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(_kit_status_label)

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
	if _document != null:
		_document.set_kit_library(_kit_library)
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
		var lines: PackedStringArray = PackedStringArray([
			"Room #%d" % int(record.get("index", 0)),
			"Label: %s" % str(record.get("label", "")),
			"Position: %.2f, %.2f, %.2f" % [
				float(record.get("x", 0.0)),
				float(record.get("y", 0.0)),
				float(record.get("z", 0.0)),
			],
			"Rotation: %.2f" % float(record.get("rotation", 0.0)),
		])
		if _document != null:
			for hook_line in _document.get_room_hook_summaries(int(record.get("index", 0))):
				lines.append(hook_line)
		_detail_label.text = "\n".join(lines)
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


func _on_kits_path_submitted(new_path: String) -> void:
	_apply_kits_path(new_path)


func _browse_kits_path() -> void:
	if not Engine.is_editor_hint():
		return
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Select Indoor Kits Folder"
	if _editor_state != null and _editor_state.has_valid_indoor_kits_path():
		dialog.current_dir = _editor_state.indoor_kits_path
	dialog.dir_selected.connect(func(path: String) -> void:
		_apply_kits_path(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _apply_kits_path(new_path: String) -> void:
	if _editor_state != null:
		_editor_state.set_indoor_kits_path(new_path)
	if _kits_path_edit != null:
		_kits_path_edit.text = new_path
	_refresh_kit_library()


func _refresh_kit_library() -> void:
	if _kit_library == null:
		_kit_library = KotorIndoorKitLibrary.new()
	var kits_path := ""
	if _kits_path_edit != null:
		kits_path = _kits_path_edit.text.strip_edges()
	elif _editor_state != null:
		kits_path = _editor_state.indoor_kits_path
	_kit_library.configure(kits_path)
	_kit_library.refresh()
	if _document != null:
		_document.set_kit_library(_kit_library)
	_refresh_kit_ui()


func _refresh_kit_ui() -> void:
	if _kit_option == null or _component_list == null:
		return
	_kit_option.clear()
	_component_list.clear()
	var kit_count := _kit_library.get_kit_count() if _kit_library != null else 0
	if kit_count == 0:
		_kit_option.add_item("(no kits loaded)")
		if _kit_status_label != null:
			var errors := (
				_kit_library.get_last_errors() if _kit_library != null else []
			) as Array
			if errors.is_empty():
				_kit_status_label.text = "Configure a kits folder and click Refresh."
			else:
				_kit_status_label.text = "\n".join(errors)
		return
	for kit_id in _kit_library.get_kit_ids():
		var kit_name := _kit_library.get_kit_name(kit_id)
		_kit_option.add_item("%s (%s)" % [kit_name, kit_id], -1)
		_kit_option.set_item_metadata(_kit_option.item_count - 1, kit_id)
	_populate_component_list_for_kit(_get_selected_kit_id())
	if _kit_status_label != null:
		_kit_status_label.text = "Loaded %d kit(s)." % kit_count


func _on_kit_selected(_index: int) -> void:
	_populate_component_list_for_kit(_get_selected_kit_id())


func _get_selected_kit_id() -> String:
	if _kit_option == null or _kit_library == null or _kit_library.get_kit_count() == 0:
		return ""
	var selected := _kit_option.get_selected()
	if selected < 0:
		return ""
	return str(_kit_option.get_item_metadata(selected))


func _populate_component_list_for_kit(kit_id: String) -> void:
	if _component_list == null:
		return
	_component_list.clear()
	if kit_id.is_empty() or _kit_library == null:
		return
	for summary in _kit_library.get_component_summaries(kit_id):
		var component_id := str(summary.get("id", ""))
		var component_name := str(summary.get("name", component_id))
		_component_list.add_item("%s (%s)" % [component_name, component_id])
		_component_list.set_item_metadata(
			_component_list.item_count - 1,
			{"kit_id": kit_id, "component_id": component_id}
		)


func _add_room_from_selected_kit() -> void:
	if _document == null or _kit_library == null:
		return
	var selected_components := _component_list.get_selected_items()
	if selected_components.is_empty():
		return
	var metadata = _component_list.get_item_metadata(selected_components[0])
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var kit_id := str(metadata.get("kit_id", ""))
	var component_id := str(metadata.get("component_id", ""))
	if kit_id.is_empty() or component_id.is_empty():
		return
	var spawn := _spawn_position_for_new_room()
	_apply_add_room_with_undo(kit_id, component_id, spawn)


func _spawn_position_for_new_room() -> Vector3:
	if _document == null:
		return Vector3.ZERO
	var records := _document.get_room_records()
	if records.is_empty():
		return Vector3.ZERO
	var last_record: Dictionary = records[records.size() - 1]
	return Vector3(
		float(last_record.get("x", 0.0)) + 4.0,
		float(last_record.get("y", 0.0)),
		float(last_record.get("z", 0.0))
	)


func _apply_add_room_with_undo(kit_id: String, component_id: String, position: Vector3) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Add indoor room", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_add_room", kit_id, component_id, position)
		ur.add_undo_method(self, "_exec_remove_last_room")
		ur.commit_action()
	else:
		_exec_add_room(kit_id, component_id, position)


func _exec_add_room(kit_id: String, component_id: String, position: Vector3) -> void:
	if _document == null:
		return
	var index := _document.add_room_from_kit(kit_id, component_id, position, 0.0)
	if index < 0:
		_status_text = "Failed to add room from %s/%s" % [kit_id, component_id]
		_refresh_status()
		return
	_select_room(index)


func _exec_remove_last_room() -> void:
	if _document == null:
		return
	var count := _document.get_room_count()
	if count <= 0:
		return
	_document.remove_room(count - 1)


func _rebuild_hook_connections() -> void:
	if _document == null:
		return
	_document.rebuild_room_connections()
	_refresh_view()
	_status_text = "Rebuilt hook connections"
	_refresh_status()


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
