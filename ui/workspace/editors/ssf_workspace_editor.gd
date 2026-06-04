@tool
extends "./kotor_workspace_editor.gd"
class_name KotorSSFWorkspaceEditor

const SSFParser := preload("../../../formats/ssf_parser.gd")
const SSFResource := preload("../../../resources/ssf_resource.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _tree: Tree
var _summary_label: Label
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _resource: SSFResource
var _source_path := ""
var _file_name := "soundset.ssf"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_resource: SSFResource
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


func open_resource(resource: SSFResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_disconnect_resource_signal()
	_resource = resource
	if _resource == null:
		_clear_document_state("No SSF resource is loaded.")
		return
	_connect_resource_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "soundset.ssf"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_ssf_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_ssf_bytes(path, bytes, path if path.get_extension().to_lower() == "ssf" else "")


func open_ssf_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := SSFParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "soundset.ssf"))
		return
	var resource := SSFResource.new()
	resource.apply_parser_result(parsed)
	open_resource(resource, source_path, _guess_loaded_file_name(label, "soundset.ssf"))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, "ssf")
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
	open_btn.text = "Open SSF..."
	open_btn.pressed.connect(_open_ssf)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save SSF"
	save_btn.pressed.connect(_save_ssf)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_ssf_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_ssf_to_override)
	_toolbar.add_child(install_btn)

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

	_refresh_status()


func _refresh_view() -> void:
	_refresh_tree()
	_refresh_status()


func _refresh_tree() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _resource == null:
		return
	_tree.columns = 2
	_tree.set_column_title(0, "Slot")
	_tree.set_column_title(1, "StrRef")
	_tree.column_titles_visible = true
	var root_item := _tree.create_item()
	var assigned := 0
	for slot_index in SSFParser.SLOT_COUNT:
		var item := _tree.create_item(root_item)
		item.set_text(0, SSFParser.slot_label(slot_index))
		item.set_metadata(0, slot_index)
		var strref := _resource.get_strref(slot_index)
		item.set_text(1, "" if strref < 0 else str(strref))
		item.set_editable(1, true)
		if strref >= 0:
			assigned += 1
	if _summary_label != null:
		_summary_label.text = "%d / %d slots assigned StrRefs." % [assigned, SSFParser.SLOT_COUNT]


func _on_tree_item_edited() -> void:
	if _resource == null:
		return
	var item := _tree.get_edited()
	if item == null or _tree.get_edited_column() != 1:
		return
	var slot_index := int(item.get_metadata(0))
	var text := item.get_text(1).strip_edges()
	var new_value := -1
	if not text.is_empty():
		if not text.is_valid_int():
			_status_text = "StrRef must be an integer or empty for none."
			_refresh_tree()
			_refresh_status()
			return
		new_value = int(text)
	if _resource.set_strref(slot_index, new_value):
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


func _open_ssf() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.ssf ; KotOR Sound Set"]),
		"Open SSF"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_ssf_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _save_ssf() -> void:
	if _resource == null:
		return
	if _source_path.is_empty():
		_save_ssf_as()
		return
	save_document_to_path(_source_path)


func _save_ssf_as() -> void:
	if _resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.ssf ; KotOR Sound Set"]),
		"Save SSF As",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _install_ssf_to_override() -> void:
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
	_file_name = "soundset.ssf"
	_dirty = false
	_status_text = message
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _summary_label != null:
		_summary_label.text = ""
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"ssf",
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
	return _ensure_extension(_file_name, "ssf")


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
	if candidate.get_extension().to_lower() == "ssf":
		return candidate
	return fallback
