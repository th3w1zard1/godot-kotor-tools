@tool
extends "./kotor_workspace_editor.gd"
class_name KotorTwoDaWorkspaceEditor

const TwoDaParser := preload("../../../formats/twoda_parser.gd")
const TwoDaResource := preload("../../../resources/twoda_resource.gd")
const KotorTwoDaDocument := preload("../../../resources/documents/kotor_twoda_document.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorValidationPanel := preload("../panels/validation_panel.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _tree: Tree
var _summary_label: Label
var _validation_panel: KotorValidationPanel
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _resource: TwoDaResource
var _document: KotorTwoDaDocument
var _source_path := ""
var _file_name := "table.2da"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_resource: TwoDaResource
var _pending_source_path := ""
var _pending_file_name := ""

# Preflight state for deferred apply
var _preflight_pending_path := ""
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_kind := ""  # "export" or "install"
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


func open_resource(resource: TwoDaResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_disconnect_document_signal()
	_resource = resource
	if _resource == null:
		_clear_document_state("No 2DA resource is loaded.")
		return
	_document = KotorTwoDaDocument.new().setup(_resource)
	_connect_document_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "table.2da"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_2da_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_2da_bytes(path, bytes, path if path.get_extension().to_lower() == "2da" else "")


func open_2da_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := TwoDaParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "table.2da"))
		return
	var resource := TwoDaResource.new()
	resource.apply_parser_result(parsed)
	open_resource(resource, source_path, _guess_loaded_file_name(label, "table.2da"))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


func get_document() -> KotorTwoDaDocument:
	return _document


func is_document_dirty() -> bool:
	return _dirty


func get_validation_text() -> String:
	return _validation_panel.get_report_text() if _validation_panel != null else ""


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, "2da")
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
	var issues := _document.validate() if _document != null else []
	if not issues.is_empty():
		var blocked := {
			"ok": false,
			"message": "Resolve 2DA validation issues before installing to override.",
			"issues": issues,
		}
		_status_text = String(blocked.get("message", ""))
		_refresh_validation()
		_refresh_status()
		return blocked
	
	var preview: Dictionary = _mutation_service.preview_install_to_override(_resolve_gamefs(), _current_file_name(), _resource)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_validation()
		_refresh_status()
		return preview
	
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	
	if _skip_preflight_for_testing:
		var result: Dictionary = _mutation_service.apply_install_to_override(_resolve_gamefs(), _current_file_name(), _resource, true)
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


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancel.connect(_on_preflight_cancel)
		add_child(_preflight_dialog)
	_preflight_dialog.show_preflight(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "export":
		_apply_export_mutation()
	elif _preflight_pending_kind == "install":
		_apply_install_mutation()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _on_preflight_cancel() -> void:
	_status_text = "Operation cancelled."
	_refresh_status()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _apply_export_mutation() -> void:
	if _preflight_pending_preview.is_empty():
		return
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
	_update_controller_dirty_state()
	_refresh_status()


func _apply_install_mutation() -> void:
	if _preflight_pending_preview.is_empty():
		return
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


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open 2DA..."
	open_btn.pressed.connect(_open_2da)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save 2DA"
	save_btn.pressed.connect(_save_2da)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_2da_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_2da_to_override)
	_toolbar.add_child(install_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_refresh_validation)
	_toolbar.add_child(validate_btn)

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
	_tree.item_edited.connect(_on_tree_item_edited)
	add_child(_tree)

	_validation_panel = KotorValidationPanel.new()
	add_child(_validation_panel)
	_refresh_status()
	_refresh_validation()


func _refresh_view() -> void:
	_refresh_tree()
	_refresh_validation()
	_refresh_status()


func _refresh_tree() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _resource == null:
		return
	_tree.columns = _resource.columns.size() + 1
	_tree.set_column_title(0, "#")
	for column_index in range(_resource.columns.size()):
		_tree.set_column_title(column_index + 1, _resource.columns[column_index])
	_tree.column_titles_visible = true
	var root_item := _tree.create_item()
	for row_index in range(_resource.rows.size()):
		var item := _tree.create_item(root_item)
		item.set_text(0, str(row_index))
		item.set_metadata(0, row_index)
		for column_index in range(_resource.columns.size()):
			var column_name := _resource.columns[column_index]
			var value = _resource.rows[row_index].get(column_name, null)
			item.set_text(column_index + 1, str(value) if value != null else "")
			item.set_editable(column_index + 1, true)
	if _document != null:
		_summary_label.text = _document.build_summary_text()


func _on_tree_item_edited() -> void:
	if _resource == null or _document == null:
		return
	var item := _tree.get_edited()
	if item == null:
		return
	var column := _tree.get_edited_column()
	if column <= 0 or column - 1 >= _resource.columns.size():
		return
	var row_index := int(item.get_metadata(0))
	var column_name := _resource.columns[column - 1]
	var new_value := item.get_text(column)
	var normalized_new: Variant = null if new_value.is_empty() else new_value
	var old_value: Variant = _resource.rows[row_index].get(column_name, null)
	if old_value == normalized_new:
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Edit 2DA cell", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_cell_edit", row_index, column_name, normalized_new)
		ur.add_undo_method(self, "_exec_cell_edit", row_index, column_name, old_value)
		ur.commit_action()
	else:
		_exec_cell_edit(row_index, column_name, normalized_new)


func _exec_cell_edit(row: int, col: String, value: Variant) -> void:
	if _document == null:
		return
	_document.set_cell(row, col, value)
	_refresh_tree()
	if _summary_label != null:
		_summary_label.text = _document.build_summary_text()


func _refresh_validation() -> void:
	if _validation_panel == null:
		return
	if _document == null:
		_validation_panel.clear_report()
		return
	var issues := _document.validate()
	if issues.is_empty():
		_validation_panel.set_success("2DA validation passed.", [
			"Table columns are defined.",
			"Rows only reference known columns.",
		])
	else:
		_validation_panel.set_issues("2DA validation issues:", issues)


func _refresh_status() -> void:
	if _path_label == null:
		return
	if _resource == null:
		_path_label.text = _status_text
		return
	_path_label.text = "%s%s  [%d rows]" % [
		_current_file_name(),
		" *" if _dirty else "",
		_resource.row_count(),
	]
	if not _status_text.is_empty():
		_path_label.text += " - %s" % _status_text


func _on_document_changed() -> void:
	_dirty = true
	_status_text = "Edited"
	_emit_dirty_state(_dirty)
	_update_controller_dirty_state()
	_refresh_validation()
	_refresh_status()


func _open_2da() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.2da ; KotOR 2DA Table"]),
		"Open KotOR 2DA"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_2da_file(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_2da() -> void:
	if _resource == null:
		return
	if _source_path.is_empty():
		_save_2da_as()
		return
	save_document_to_path(_source_path)


func _save_2da_as() -> void:
	if _resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.2da ; KotOR 2DA Table"]),
		"Save KotOR 2DA",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_2da_to_override() -> void:
	install_document_to_override()


func _connect_document_signal() -> void:
	if _document == null:
		return
	var changed := Callable(self, "_on_document_changed")
	if not _document.changed.is_connected(changed):
		_document.changed.connect(changed)


func _disconnect_document_signal() -> void:
	if _document == null:
		return
	var changed := Callable(self, "_on_document_changed")
	if _document.changed.is_connected(changed):
		_document.changed.disconnect(changed)


func _clear_document_state(message: String) -> void:
	_disconnect_document_signal()
	_resource = null
	_document = null
	_source_path = ""
	_file_name = "table.2da"
	_dirty = false
	_status_text = message
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _summary_label != null:
		_summary_label.text = ""
	_refresh_validation()
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"twoda",
		_resource,
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
	return _ensure_extension(_file_name, "2da")


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
		var initial_dir: String = String(editor_state.call("resolve_dialog_start_dir", start_dir))
		if not initial_dir.is_empty():
			dialog.current_dir = initial_dir
	if not current_file.is_empty():
		dialog.current_file = current_file
	return dialog


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var file_name := label.strip_edges()
	if file_name.is_empty():
		return fallback
	var separator := file_name.find("  [")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	separator = file_name.find(" - ")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	separator = file_name.find(" [")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	file_name = file_name.get_file()
	return file_name if not file_name.is_empty() else fallback


func _mutation_message(result: Dictionary) -> String:
	if result.has("result") and typeof(result.get("result", {})) == TYPE_DICTIONARY:
		return String((result.get("result", {}) as Dictionary).get("message", result.get("message", "")))
	return String(result.get("message", ""))


func _get_undo_redo() -> EditorUndoRedoManager:
	if not Engine.is_editor_hint():
		return null
	return EditorInterface.get_editor_undo_redo()

