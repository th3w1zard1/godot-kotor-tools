@tool
extends "./kotor_workspace_editor.gd"
class_name KotorLIPWorkspaceEditor

const LIPParser := preload("../../../formats/lip_parser.gd")
const LIPResource := preload("../../../resources/lip_resource.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _duration_spin: SpinBox
var _tree: Tree
var _summary_label: Label
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _resource: LIPResource
var _source_path := ""
var _file_name := "animation.lip"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_resource: LIPResource
var _pending_source_path := ""
var _pending_file_name := ""

var _preflight_pending_path := ""
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_kind := ""
var _skip_preflight_for_testing := false


func _on_workspace_setup() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_mutation_service = _resolve_mutation_service()
	_build_ui()
	if _pending_resource != null:
		var pending_resource := _pending_resource
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_resource = null
		_pending_source_path = ""
		_pending_file_name = ""
		open_resource(pending_resource, pending_source_path, pending_file_name)


func open_resource(resource: LIPResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_disconnect_resource_signal()
	_resource = resource
	if _resource == null:
		_clear_document_state("No LIP resource is loaded.")
		return
	_connect_resource_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "animation.lip"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_lip_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_lip_bytes(path, bytes, path if path.get_extension().to_lower() == "lip" else "")


func open_lip_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := LIPParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "animation.lip"))
		return
	var resource := LIPResource.new()
	resource.apply_parser_result(parsed)
	open_resource(resource, source_path, _guess_loaded_file_name(label, "animation.lip"))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, "lip")
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, _resource)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var previous_key := _document_key
		var result: Dictionary = _mutation_service.apply_export_to_path(target_path, _resource, true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_source_path = target_path
			_file_name = target_path.get_file()
			_dirty = false
			_register_controller_document()
			_remove_previous_controller_document(previous_key)
		_update_controller_dirty_state()
		_refresh_status()
		return result
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_show_preflight_dialog(preview)
	return {}


func install_document_to_override() -> Dictionary:
	if _resource == null:
		return {}
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_resource
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var result: Dictionary = _mutation_service.apply_install_to_override(
			_resolve_gamefs(),
			_current_file_name(),
			_resource,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_dirty = false
			_refresh_gamefs()
		_update_controller_dirty_state()
		_refresh_status()
		return result
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install"
	_show_preflight_dialog(preview)
	return {}


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open LIP..."
	open_btn.pressed.connect(_open_lip)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save LIP"
	save_btn.pressed.connect(_save_lip)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_lip_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_lip_to_override)
	_toolbar.add_child(install_btn)

	var add_btn := Button.new()
	add_btn.text = "Add Keyframe"
	add_btn.pressed.connect(_add_keyframe)
	_toolbar.add_child(add_btn)

	var remove_btn := Button.new()
	remove_btn.text = "Remove Selected"
	remove_btn.pressed.connect(_remove_selected_keyframe)
	_toolbar.add_child(remove_btn)

	var duration_label := Label.new()
	duration_label.text = "Duration (s):"
	_toolbar.add_child(duration_label)

	_duration_spin = SpinBox.new()
	_duration_spin.min_value = 0.0
	_duration_spin.max_value = 9999.0
	_duration_spin.step = 0.001
	_duration_spin.custom_minimum_size.x = 90.0
	_duration_spin.value_changed.connect(_on_duration_changed)
	_toolbar.add_child(_duration_spin)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_tree = Tree.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.item_edited.connect(_on_tree_item_edited)
	_tree.item_selected.connect(_on_tree_item_selected)
	add_child(_tree)

	_refresh_status()


func _refresh_view() -> void:
	if _duration_spin != null and _resource != null:
		_duration_spin.set_value_no_signal(_resource.length)
	_refresh_tree()
	_refresh_status()


func _refresh_tree() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _resource == null:
		return
	_tree.columns = 3
	_tree.set_column_title(0, "#")
	_tree.set_column_title(1, "Time (s)")
	_tree.set_column_title(2, "Shape")
	_tree.column_titles_visible = true
	var root_item := _tree.create_item()
	for index in _resource.get_keyframe_count():
		var entry := _resource.get_keyframe(index)
		var item := _tree.create_item(root_item)
		item.set_text(0, str(index + 1))
		item.set_metadata(0, index)
		item.set_text(1, "%.3f" % float(entry.get("time", 0.0)))
		item.set_text(2, LIPParser.shape_name(int(entry.get("shape", 0))))
		item.set_editable(1, true)
		item.set_editable(2, true)
	if _summary_label != null:
		_summary_label.text = (
			"%d keyframe(s), duration %.3f s. Shapes: 0–15 or names (NEUTRAL, EE, AH, …)."
			% [_resource.get_keyframe_count(), _resource.length]
		)


func _on_duration_changed(value: float) -> void:
	if _resource == null:
		return
	if _resource.set_length(value):
		_dirty = true
		_update_controller_dirty_state()
	_refresh_status()


func _add_keyframe() -> void:
	if _resource == null:
		return
	var next_time := 0.0
	if _resource.get_keyframe_count() > 0:
		var last := _resource.get_keyframe(_resource.get_keyframe_count() - 1)
		next_time = float(last.get("time", 0.0)) + 0.1
	_resource.add_keyframe(next_time, 0)
	_dirty = true
	_update_controller_dirty_state()
	_refresh_view()


func _remove_selected_keyframe() -> void:
	if _resource == null or _tree == null:
		return
	var item := _tree.get_selected()
	if item == null:
		_status_text = "Select a keyframe to remove."
		_refresh_status()
		return
	var index := int(item.get_metadata(0))
	if _resource.remove_keyframe_at(index):
		_dirty = true
		_update_controller_dirty_state()
	_refresh_view()


func _on_tree_item_selected() -> void:
	pass


func _on_tree_item_edited() -> void:
	if _resource == null:
		return
	var item := _tree.get_edited()
	if item == null:
		return
	var keyframe_index := int(item.get_metadata(0))
	var entry := _resource.get_keyframe(keyframe_index)
	if entry.is_empty():
		_refresh_tree()
		return
	var edited_column := _tree.get_edited_column()
	var time := float(entry.get("time", 0.0))
	var shape := int(entry.get("shape", 0))
	if edited_column == 1:
		var text := item.get_text(1).strip_edges()
		if not text.is_valid_float():
			_status_text = "Time must be a number."
			_refresh_tree()
			_refresh_status()
			return
		time = maxf(0.0, float(text))
	elif edited_column == 2:
		var shape_text := item.get_text(2).strip_edges()
		var parsed_shape := LIPParser.parse_shape_token(shape_text)
		if parsed_shape < 0:
			_status_text = "Shape must be 0–15 or a viseme name (e.g. EE, AH)."
			_refresh_tree()
			_refresh_status()
			return
		shape = parsed_shape
	else:
		return
	if _resource.set_keyframe(keyframe_index, time, shape):
		_dirty = true
		_update_controller_dirty_state()
	_refresh_tree()
	_refresh_status()


func _on_resource_changed() -> void:
	_dirty = true
	_update_controller_dirty_state()
	_refresh_status()


func _connect_resource_signal() -> void:
	if _resource != null and not _resource.changed.is_connected(_on_resource_changed):
		_resource.changed.connect(_on_resource_changed)


func _disconnect_resource_signal() -> void:
	if _resource != null and _resource.changed.is_connected(_on_resource_changed):
		_resource.changed.disconnect(_on_resource_changed)


func _open_lip() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.lip ; KotOR Lip Sync"]),
		"Open LIP"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_lip_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _save_lip() -> void:
	if _resource == null:
		return
	if _source_path.is_empty():
		_save_lip_as()
		return
	save_document_to_path(_source_path)


func _save_lip_as() -> void:
	if _resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.lip ; KotOR Lip Sync"]),
		"Save LIP As",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _install_lip_to_override() -> void:
	install_document_to_override()


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancelled.connect(_on_preflight_cancelled)
	_preflight_dialog.show_preview(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "export" and not _preflight_pending_path.is_empty():
		var previous_key := _document_key
		var result: Dictionary = _mutation_service.apply_export_to_path(
			_preflight_pending_path,
			_resource,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_source_path = _preflight_pending_path
			_file_name = _preflight_pending_path.get_file()
			_dirty = false
			_register_controller_document()
			_remove_previous_controller_document(previous_key)
	elif _preflight_pending_kind == "install":
		var result: Dictionary = _mutation_service.apply_install_to_override(
			_resolve_gamefs(),
			_current_file_name(),
			_resource,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_dirty = false
			_refresh_gamefs()
	_update_controller_dirty_state()
	_clear_preflight_state()
	_refresh_status()


func _on_preflight_cancelled() -> void:
	_clear_preflight_state()
	_status_text = "Save/install cancelled."
	_refresh_status()


func _clear_preflight_state() -> void:
	_preflight_pending_path = ""
	_preflight_pending_preview = {}
	_preflight_pending_kind = ""


func _clear_document_state(message: String) -> void:
	_disconnect_resource_signal()
	_resource = null
	_source_path = ""
	_file_name = "animation.lip"
	_dirty = false
	_status_text = message
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _summary_label != null:
		_summary_label.text = ""
	if _duration_spin != null:
		_duration_spin.set_value_no_signal(0.0)
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"lip",
		_resource,
		null,
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
	if controller == null or previous_key.is_empty() or previous_key == _document_key:
		return
	if controller.has_method("remove_document"):
		controller.call("remove_document", previous_key)


func _resolve_mutation_service() -> RefCounted:
	var controller := get_controller()
	if controller != null:
		var service = controller.get("mutation_service")
		if service != null:
			return service
	return KotorMutationService.new()


func _resolve_gamefs() -> RefCounted:
	var editor_state := get_editor_state()
	if editor_state == null:
		return null
	return editor_state.get("gamefs") as RefCounted


func _refresh_gamefs() -> void:
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.has_method("refresh_gamefs"):
		editor_state.call("refresh_gamefs")


func _current_file_name() -> String:
	return _ensure_extension(_file_name, "lip")


func _ensure_extension(path: String, extension: String) -> String:
	if path.get_extension().to_lower() == extension.to_lower():
		return path
	return "%s.%s" % [path, extension]


func _make_dialog(
		file_mode: EditorFileDialog.FileMode,
		filters: PackedStringArray,
		title: String,
		start_dir: String = "",
		current_file: String = ""
) -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = file_mode
	dialog.title = title
	dialog.filters = filters
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = editor_state.call("resolve_dialog_start_dir", start_dir)
	elif not start_dir.is_empty():
		dialog.current_dir = start_dir
	if not current_file.is_empty():
		dialog.current_file = current_file
	return dialog


func _refresh_status() -> void:
	if _path_label == null:
		return
	if _resource == null:
		_path_label.text = _status_text
		_emit_status_text(_status_text)
		return
	var line := "%s%s" % [_current_file_name(), " *" if _dirty else ""]
	if not _status_text.is_empty():
		line += " — %s" % _status_text
	_path_label.text = line
	_emit_dirty_state(_dirty)
	_emit_status_text(_status_text)


func _mutation_message(result: Dictionary) -> String:
	if result.get("applied", false):
		return str(result.get("message", "Changes applied."))
	return str(result.get("message", "Mutation failed."))


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var candidate := label.get_file()
	if candidate.is_empty():
		return fallback
	if candidate.get_extension().to_lower() == "lip":
		return candidate
	return fallback
