@tool
extends "./kotor_workspace_editor.gd"
class_name KotorTLKWorkspaceEditor

const TLKParser := preload("../../../formats/tlk_parser.gd")
const TLKResource := preload("../../../resources/tlk_resource.gd")
const KotorTLKDocument := preload("../../../resources/documents/kotor_tlk_document.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorValidationPanel := preload("../panels/validation_panel.gd")

const GAME_TLK_NAME := KotorEditorState.GAME_TLK_NAME

var _toolbar: HBoxContainer
var _path_label: Label
var _search_field: LineEdit
var _tree: Tree
var _text_edit: TextEdit
var _entry_status_label: Label
var _validation_panel: KotorValidationPanel

var _mutation_service: RefCounted
var _resource: TLKResource
var _document: KotorTLKDocument
var _source_path := ""
var _file_name := GAME_TLK_NAME
var _dirty := false
var _status_text := ""
var _selected_strref := -1
var _document_key := ""

var _pending_resource: TLKResource
var _pending_source_path := ""
var _pending_file_name := ""


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


func open_resource(resource: TLKResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_disconnect_document_signal()
	_resource = resource
	if _resource == null:
		_clear_document_state("No TLK resource is loaded.")
		return
	_document = KotorTLKDocument.new().setup(_resource)
	_connect_document_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else GAME_TLK_NAME
	_dirty = false
	_status_text = ""
	_selected_strref = -1
	_register_controller_document()
	_refresh_view()


func open_tlk_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_tlk_bytes(path, bytes, path if path.get_extension().to_lower() == "tlk" else "")


func open_tlk_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := TLKParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, GAME_TLK_NAME))
		return
	var resource := TLKResource.new()
	resource.apply_parser_result(parsed)
	open_resource(resource, source_path, _guess_loaded_file_name(label, GAME_TLK_NAME))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


func get_document() -> KotorTLKDocument:
	return _document


func is_document_dirty() -> bool:
	return _dirty


func get_validation_text() -> String:
	return _validation_panel.get_report_text() if _validation_panel != null else ""


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, "tlk")
	var previous_key := _document_key
	var result: Dictionary = _mutation_service.apply_export_to_path(target_path, _resource)
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


func install_document_to_override() -> Dictionary:
	if _resource == null:
		return {}
	var issues := _document.validate() if _document != null else []
	if not issues.is_empty():
		var blocked := {
			"ok": false,
			"message": "Resolve TLK validation issues before installing to override.",
			"issues": issues,
		}
		_status_text = String(blocked.get("message", ""))
		_refresh_validation()
		_refresh_status()
		return blocked
	var result: Dictionary = _mutation_service.apply_install_to_override(_resolve_gamefs(), _current_file_name(), _resource)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_dirty = false
		_refresh_gamefs()
	_update_controller_dirty_state()
	_refresh_status()
	return result


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open TLK..."
	open_btn.pressed.connect(_open_tlk)
	_toolbar.add_child(open_btn)

	var load_game_btn := Button.new()
	load_game_btn.text = "Load Game TLK"
	load_game_btn.pressed.connect(_load_game_tlk)
	_toolbar.add_child(load_game_btn)

	var save_btn := Button.new()
	save_btn.text = "Save TLK"
	save_btn.pressed.connect(_save_tlk)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_tlk_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_tlk_to_override)
	_toolbar.add_child(install_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_refresh_validation)
	_toolbar.add_child(validate_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	var search_row := HBoxContainer.new()
	add_child(search_row)

	var search_label := Label.new()
	search_label.text = "Search:"
	search_row.add_child(search_label)

	_search_field = LineEdit.new()
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.placeholder_text = "Enter StrRef number or text fragment..."
	_search_field.text_submitted.connect(_refresh_results)
	search_row.add_child(_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(func() -> void:
		_refresh_results(_search_field.text)
	)
	search_row.add_child(search_btn)

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 2
	_tree.set_column_title(0, "StrRef")
	_tree.set_column_title(1, "Text")
	_tree.column_titles_visible = true
	_tree.item_selected.connect(_on_item_selected)
	split.add_child(_tree)

	var editor_panel := VBoxContainer.new()
	editor_panel.custom_minimum_size = Vector2(240, 0)
	split.add_child(editor_panel)

	var editor_label := Label.new()
	editor_label.text = "Selected TLK Text"
	editor_panel.add_child(editor_label)

	_text_edit = TextEdit.new()
	_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_panel.add_child(_text_edit)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_apply_text)
	editor_panel.add_child(apply_btn)

	_entry_status_label = Label.new()
	_entry_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_status_label.clip_text = true
	_entry_status_label.text = "Search for a StrRef or text fragment"
	editor_panel.add_child(_entry_status_label)

	_validation_panel = KotorValidationPanel.new()
	add_child(_validation_panel)
	_refresh_status()
	_refresh_validation()


func _refresh_view() -> void:
	_refresh_results(_search_field.text if _search_field != null else "")
	_refresh_validation()
	_refresh_status()


func _refresh_results(query: String) -> void:
	if _tree == null:
		return
	_tree.clear()
	if _document == null:
		return
	var root_item := _tree.create_item()
	var results := _document.search(query)
	for entry in results:
		var item := _tree.create_item(root_item)
		item.set_text(0, str(entry.get("strref", 0)))
		item.set_text(1, String(entry.get("text", "")))
		item.set_metadata(0, int(entry.get("strref", 0)))
	if query.strip_edges().is_empty() and _resource != null:
		for index in range(mini(200, _resource.entries.size())):
			var entry := _resource.entries[index]
			var item := _tree.create_item(root_item)
			item.set_text(0, str(entry.get("strref", index)))
			item.set_text(1, String(entry.get("text", "")))
			item.set_metadata(0, int(entry.get("strref", index)))


func _on_item_selected() -> void:
	if _document == null or _tree == null:
		return
	var item := _tree.get_selected()
	if item == null:
		return
	var strref := int(item.get_metadata(0))
	var entry := _document.get_entry(strref)
	if entry.is_empty():
		return
	_selected_strref = strref
	_text_edit.text = String(entry.get("text", ""))
	_entry_status_label.text = "Editing StrRef %d" % strref
	_update_controller_selection()


func _apply_text() -> void:
	if _document == null or _selected_strref < 0:
		return
	if not _document.set_entry_text(_selected_strref, _text_edit.text):
		return
	var item := _tree.get_selected()
	if item != null and int(item.get_metadata(0)) == _selected_strref:
		item.set_text(1, _text_edit.text)
	_entry_status_label.text = "Updated StrRef %d" % _selected_strref


func _refresh_validation() -> void:
	if _validation_panel == null:
		return
	if _document == null:
		_validation_panel.clear_report()
		return
	var issues := _document.validate()
	if issues.is_empty():
		_validation_panel.set_success("TLK validation passed.", [
			"StrRef ordering is contiguous.",
		])
	else:
		_validation_panel.set_issues("TLK validation issues:", issues)


func _refresh_status() -> void:
	if _path_label == null:
		return
	if _resource == null:
		_path_label.text = _status_text
		return
	_path_label.text = "%s%s  [%d strings]" % [
		_current_file_name(),
		" *" if _dirty else "",
		_resource.entries.size(),
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


func _open_tlk() -> void:
	var tlk_path := _find_dialog_tlk()
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.tlk ; KotOR TLK Talk Table"]),
		"Open KotOR TLK",
		tlk_path.get_base_dir() if not tlk_path.is_empty() else ""
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_tlk_file(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_game_tlk() -> void:
	var tlk_path := _find_dialog_tlk()
	if tlk_path.is_empty():
		_status_text = "dialog.tlk not found"
		_refresh_status()
		return
	open_tlk_file(tlk_path)


func _save_tlk() -> void:
	if _resource == null:
		return
	if _source_path.is_empty():
		_save_tlk_as()
		return
	save_document_to_path(_source_path)


func _save_tlk_as() -> void:
	if _resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.tlk ; KotOR TLK Talk Table"]),
		"Save KotOR TLK",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_tlk_to_override() -> void:
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
	_file_name = GAME_TLK_NAME
	_dirty = false
	_status_text = message
	_selected_strref = -1
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _text_edit != null:
		_text_edit.text = ""
	if _entry_status_label != null:
		_entry_status_label.text = "Search for a StrRef or text fragment"
	_refresh_validation()
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"tlk",
		_resource,
		_document,
		_source_path,
		_current_file_name(),
		{"strref": _selected_strref}
	)
	_document_key = str(entry.get("key", ""))


func _update_controller_dirty_state() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_dirty"):
		return
	controller.call("update_document_dirty", _document_key, _dirty)


func _update_controller_selection() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_selection"):
		return
	controller.call("update_document_selection", _document_key, {"strref": _selected_strref})


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


func _find_dialog_tlk() -> String:
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.has_method("find_dialog_tlk"):
		return String(editor_state.call("find_dialog_tlk"))
	return ""


func _current_file_name() -> String:
	return _ensure_extension(_file_name, "tlk")


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
