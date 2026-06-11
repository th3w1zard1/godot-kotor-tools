@tool
extends "./kotor_workspace_editor.gd"
class_name KotorScriptWorkspaceEditor

const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorScriptDocument := preload("../../../resources/documents/kotor_script_document.gd")
const KotorValidationPanel := preload("../panels/validation_panel.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

const SCRIPT_EXTENSIONS := {
	"nss": true,
	"ncs": true,
}

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _text_edit: TextEdit
var _validation_panel: KotorValidationPanel
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _document: KotorScriptDocument
var _status_text := ""
var _dirty := false
var _document_key := ""
var _loading := false

var _pending_label := ""
var _pending_bytes := PackedByteArray()
var _pending_extension := ""
var _pending_source_path := ""

# Preflight state for deferred apply
var _preflight_pending_path := ""
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_kind := ""  # "export" or "install"
var _skip_preflight_for_testing := false
var _install_btn: Button


func _on_workspace_setup() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_mutation_service = _resolve_mutation_service()
	_build_ui()
	if not _pending_bytes.is_empty() or not _pending_label.is_empty():
		var label := _pending_label
		var bytes := _pending_bytes
		var extension := _pending_extension
		var source_path := _pending_source_path
		_pending_label = ""
		_pending_bytes = PackedByteArray()
		_pending_extension = ""
		_pending_source_path = ""
		open_script_bytes(label, bytes, extension, source_path)


func open_script_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_script_bytes(path, bytes, path.get_extension().to_lower(), path if SCRIPT_EXTENSIONS.has(path.get_extension().to_lower()) else "")


func open_script_bytes(label: String, bytes: PackedByteArray, extension_hint: String = "", source_path: String = "") -> void:
	if not is_node_ready():
		_pending_label = label
		_pending_bytes = bytes
		_pending_extension = extension_hint
		_pending_source_path = source_path
		return
	_disconnect_document_signal()
	_document = KotorScriptDocument.new().setup(label, bytes, get_editor_state(), extension_hint, source_path)
	_connect_document_signal()
	_dirty = false
	_status_text = "Loaded %s" % _document.get_file_name()
	_register_controller_document()
	_refresh_view()


func get_document() -> KotorScriptDocument:
	return _document


func is_document_dirty() -> bool:
	return _dirty


func get_validation_text() -> String:
	return _validation_panel.get_report_text() if _validation_panel != null else ""


func save_document_to_path(path: String) -> Dictionary:
	if _document == null or _document.get_extension() != "nss":
		return {}
	var target_path := _ensure_extension(path, "nss")
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, _document.get_text())
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_view()
		return preview
	
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_view()
		return preview
	
	if _skip_preflight_for_testing:
		var previous_key := _document_key
		var result: Dictionary = _mutation_service.apply_export_to_path(target_path, _document.get_text(), true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			var bytes := _document.get_text().to_ascii_buffer()
			_loading = true
			_document = KotorScriptDocument.new().setup(target_path, bytes, get_editor_state(), "nss", target_path)
			_loading = false
			_connect_document_signal()
			_dirty = false
			_register_controller_document()
			_remove_previous_controller_document(previous_key)
		_update_controller_dirty_state()
		_refresh_view()
		return result
	
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_show_preflight_dialog(preview)
	return {}


func install_document_to_override() -> Dictionary:
	if _document == null:
		return {}
	var file_name := _install_override_file_name()
	var payload: Variant = _install_override_payload()
	if file_name.is_empty() or payload == null:
		_status_text = "No compiled NCS bytes are loaded."
		_refresh_view()
		return {"ok": false, "message": _status_text}
	if _document.get_extension() == "nss":
		var issues := _document.validate()
		if not issues.is_empty():
			_status_text = "Resolve script validation issues before installing to override."
			_refresh_view()
			return {"ok": false, "message": _status_text, "issues": issues}
	
	var preview: Dictionary = _mutation_service.preview_install_to_override(_resolve_gamefs(), file_name, payload)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_view()
		return preview
	
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_view()
		return preview
	
	if _skip_preflight_for_testing:
		var result: Dictionary = _mutation_service.apply_install_to_override(_resolve_gamefs(), file_name, payload, true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_dirty = false
			_refresh_gamefs()
		_update_controller_dirty_state()
		_refresh_view()
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
	_refresh_view()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _apply_export_mutation() -> void:
	if _preflight_pending_preview.is_empty():
		return
	var previous_key := _document_key
	var result: Dictionary = _mutation_service.apply_export_to_path(
		_preflight_pending_path,
		_document.get_text(),
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		var bytes := _document.get_text().to_ascii_buffer()
		_loading = true
		_document = KotorScriptDocument.new().setup(_preflight_pending_path, bytes, get_editor_state(), "nss", _preflight_pending_path)
		_loading = false
		_connect_document_signal()
		_dirty = false
		_register_controller_document()
		_remove_previous_controller_document(previous_key)
	_update_controller_dirty_state()
	_refresh_view()


func _apply_install_mutation() -> void:
	if _preflight_pending_preview.is_empty() or _document == null:
		return
	var file_name := _install_override_file_name()
	var payload: Variant = _install_override_payload()
	if file_name.is_empty() or payload == null:
		return
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		file_name,
		payload,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_dirty = false
		_refresh_gamefs()
	_update_controller_dirty_state()
	_refresh_view()


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open NSS/NCS..."
	open_btn.pressed.connect(_open_script)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_script)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_script_as)
	_toolbar.add_child(save_as_btn)

	_install_btn = Button.new()
	_install_btn.text = "Install to Override"
	_install_btn.pressed.connect(_install_script_to_override)
	_toolbar.add_child(_install_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_refresh_validation)
	_toolbar.add_child(validate_btn)

	var counterpart_btn := Button.new()
	counterpart_btn.text = "Open Counterpart"
	counterpart_btn.pressed.connect(_open_script_counterpart)
	_toolbar.add_child(counterpart_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_text_edit = TextEdit.new()
	_text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_edit.text_changed.connect(_on_text_changed)
	add_child(_text_edit)

	_validation_panel = KotorValidationPanel.new()
	add_child(_validation_panel)
	_refresh_view()


func _refresh_view() -> void:
	if _document == null:
		_refresh_status()
		_refresh_install_button()
		_refresh_validation()
		return
	_refresh_status()
	_refresh_install_button()
	_summary_label.text = _document.build_summary_text()
	_loading = true
	_text_edit.text = _document.get_text()
	_text_edit.editable = _document.is_editable()
	_loading = false
	_refresh_validation()


func _refresh_status() -> void:
	if _path_label == null:
		return
	if _document == null:
		_path_label.text = _status_text
		return
	_path_label.text = "%s%s" % [_document.get_file_name(), " *" if _dirty else ""]
	if not _status_text.is_empty():
		_path_label.text += " - %s" % _status_text


func _refresh_validation() -> void:
	if _validation_panel == null:
		return
	if _document == null:
		_validation_panel.clear_report()
		return
	var issues := _document.validate()
	if issues.is_empty():
		_validation_panel.set_success("Script validation passed.", [
			"Counterpart: %s" % _document.counterpart_label(),
		])
		if _document.get_extension() == "ncs":
			_validation_panel.set_success("Compiled NWScript binary loaded.", [
				"Matching source: %s" % _document.counterpart_label(),
				"Use Install NCS to Override to write bytecode to the game install.",
			])
			return
	else:
		_validation_panel.set_issues("Script validation issues:", issues)


func _on_text_changed() -> void:
	if _loading or _document == null or not _document.is_editable():
		return
	_document.set_text(_text_edit.text)


func _on_document_changed() -> void:
	if _document == null:
		return
	_dirty = true
	_status_text = "Edited"
	_emit_dirty_state(_dirty)
	_update_controller_dirty_state()
	_refresh_view()


func _open_script() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.nss,*.ncs ; KotOR Scripts"]),
		"Open KotOR Script"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_script_file(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_script() -> void:
	if _document == null or _document.get_extension() != "nss":
		return
	if _document.get_source_path().is_empty():
		_save_script_as()
		return
	save_document_to_path(_document.get_source_path())


func _save_script_as() -> void:
	if _document == null or _document.get_extension() != "nss":
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.nss ; KotOR Script Source"]),
		"Save KotOR Script",
		_document.get_source_path().get_base_dir() if not _document.get_source_path().is_empty() else "",
		_document.get_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_script_to_override() -> void:
	install_document_to_override()


func _open_script_counterpart() -> void:
	if _document == null:
		return
	var counterpart := _document.find_counterpart()
	if counterpart.is_empty():
		_status_text = "No matching %s resource was found." % ("nss" if _document.get_extension() == "ncs" else "ncs")
		_refresh_status()
		return
	if counterpart.has("entry"):
		var entry: Dictionary = counterpart.get("entry", {})
		var gamefs := _resolve_gamefs()
		if gamefs == null:
			return
		var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(entry)
		var label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		open_script_bytes(label, bytes, str(entry.get("extension", "")), "")
		return
	open_script_file(str(counterpart.get("path", "")))


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


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document") or _document == null:
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"script",
		null,
		_document,
		_document.get_source_path(),
		_document.get_file_name(),
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


func _ensure_extension(path: String, extension: String) -> String:
	if path.get_extension().to_lower() == extension.to_lower():
		return path
	return "%s.%s" % [path, extension]


static func ncs_override_file_name(file_name: String) -> String:
	return "%s.ncs" % file_name.get_basename()


func _install_override_file_name() -> String:
	if _document == null:
		return ""
	if _document.get_extension() == "ncs":
		return ncs_override_file_name(_document.get_file_name())
	return _document.get_file_name()


func _install_override_payload() -> Variant:
	if _document == null:
		return null
	if _document.get_extension() == "ncs":
		var bytes := _document.get_bytes()
		if bytes.is_empty():
			return null
		return bytes
	return _document.get_text()


func _refresh_install_button() -> void:
	if _install_btn == null:
		return
	if _document == null:
		_install_btn.disabled = true
		_install_btn.text = "Install to Override"
		return
	var can_install_nss := _document.get_extension() == "nss"
	var can_install_ncs := _document.get_extension() == "ncs" and not _document.get_bytes().is_empty()
	_install_btn.disabled = not (can_install_nss or can_install_ncs)
	_install_btn.text = "Install NCS to Override" if _document.get_extension() == "ncs" else "Install to Override"


func _mutation_message(result: Dictionary) -> String:
	if result.has("result") and typeof(result.get("result", {})) == TYPE_DICTIONARY:
		return String((result.get("result", {}) as Dictionary).get("message", result.get("message", "")))
	return String(result.get("message", ""))
