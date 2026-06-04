@tool
extends "./kotor_workspace_editor.gd"
class_name KotorWAVWorkspaceEditor

const WavMetadata := preload("../../../formats/wav_metadata.gd")
const KotorMediaToolBridge := preload("../../../resources/scripts/kotor_media_tool_bridge.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _meta_label: RichTextLabel
var _sound_type_option: OptionButton
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _bytes: PackedByteArray = PackedByteArray()
var _source_path := ""
var _file_name := "sound.wav"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_bytes: PackedByteArray
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
	if not _pending_bytes.is_empty():
		var pending_bytes := _pending_bytes
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_bytes = PackedByteArray()
		_pending_source_path = ""
		_pending_file_name = ""
		open_wav_bytes(pending_bytes, pending_source_path, pending_file_name)


func open_wav_bytes(data: PackedByteArray, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_bytes = data
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_bytes = data
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "sound.wav"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_wav_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_wav_bytes(bytes, path, path.get_file())


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _bytes.is_empty():
		return {}
	var target_path := _ensure_extension(path, "wav")
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, _bytes)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_export(target_path, preview)
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_show_preflight_dialog(preview)
	return {}


func install_document_to_override() -> Dictionary:
	if _bytes.is_empty():
		return {}
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_bytes
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
		return _apply_install(preview)
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
	open_btn.text = "Open WAV..."
	open_btn.pressed.connect(_open_wav)
	_toolbar.add_child(open_btn)

	var convert_btn := Button.new()
	convert_btn.text = "Convert (PyKotor)..."
	convert_btn.pressed.connect(_convert_wav)
	_toolbar.add_child(convert_btn)

	var save_btn := Button.new()
	save_btn.text = "Save WAV"
	save_btn.pressed.connect(_save_wav)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_wav_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_wav_to_override)
	_toolbar.add_child(install_btn)

	_sound_type_option = OptionButton.new()
	_sound_type_option.add_item("SFX", 0)
	_sound_type_option.add_item("VO", 1)
	_toolbar.add_child(_sound_type_option)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_meta_label = RichTextLabel.new()
	_meta_label.fit_content = true
	_meta_label.scroll_active = false
	add_child(_meta_label)

	_refresh_status()


func _refresh_view() -> void:
	_refresh_metadata()
	_refresh_status()


func _refresh_metadata() -> void:
	if _meta_label == null:
		return
	if _bytes.is_empty():
		_meta_label.text = "[color=gray]No WAV loaded.[/color]"
		return
	var meta := WavMetadata.parse_bytes(_bytes)
	if not meta.get("ok", false):
		_meta_label.text = "[color=red]%s[/color]" % meta.get("message", "Invalid WAV")
		return
	var lines: PackedStringArray = PackedStringArray()
	for line in WavMetadata.format_summary(meta):
		var parts := line.split(": ", false, 1)
		if parts.size() == 2:
			lines.append("[b]%s:[/b] %s" % [parts[0], parts[1]])
		else:
			lines.append(line)
	_meta_label.text = "\n".join(lines)


func _convert_wav() -> void:
	if _bytes.is_empty():
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.wav ; Wave Audio"]),
		"Convert WAV",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_run_sound_convert(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _run_sound_convert(output_path: String) -> void:
	var temp_input := _write_temp_wav()
	if temp_input.is_empty():
		_status_text = "Failed to write temporary WAV for conversion."
		_refresh_status()
		return
	var target := output_path
	if target.get_extension().to_lower() != "wav":
		target = "%s.wav" % target
	var sound_type := "VO" if _sound_type_option.get_selected_id() == 1 else "SFX"
	var result: Dictionary = KotorMediaToolBridge.run_sound_convert(
		temp_input,
		target,
		true,
		sound_type,
		_editor_state.get("pykotor_cli_path") if _editor_state != null else ""
	)
	if result.get("ok", false):
		_status_text = "Converted WAV to %s (%s)" % [target.get_file(), sound_type]
	else:
		_status_text = result.get("message", "sound-convert failed")
	_refresh_status()


func _write_temp_wav() -> String:
	var dir := DirAccess.open("user://")
	if dir == null:
		return ""
	dir.make_dir_recursive("kotor_tools/tmp")
	var temp_path := "user://kotor_tools/tmp/export_source.wav"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_buffer(_bytes)
	file.close()
	return ProjectSettings.globalize_path(temp_path)


func _open_wav() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.wav ; Wave Audio"]),
		"Open WAV"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_wav_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _save_wav() -> void:
	if _bytes.is_empty():
		return
	if _source_path.is_empty():
		_save_wav_as()
		return
	save_document_to_path(_source_path)


func _save_wav_as() -> void:
	if _bytes.is_empty():
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.wav ; Wave Audio"]),
		"Save WAV As",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _install_wav_to_override() -> void:
	install_document_to_override()


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancelled.connect(_on_preflight_cancelled)
	_preflight_dialog.show_preview(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "export" and not _preflight_pending_path.is_empty():
		_apply_export(_preflight_pending_path, _preflight_pending_preview)
	elif _preflight_pending_kind == "install":
		_apply_install(_preflight_pending_preview)
	_clear_preflight_state()
	_refresh_status()


func _on_preflight_cancelled() -> void:
	_clear_preflight_state()
	_status_text = "Save/install cancelled."
	_refresh_status()


func _apply_export(target_path: String, _preview: Dictionary) -> Dictionary:
	var previous_key := _document_key
	var result: Dictionary = _mutation_service.apply_export_to_path(target_path, _bytes, true)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_source_path = target_path
		_file_name = target_path.get_file()
		_dirty = false
		_register_controller_document()
		_remove_previous_controller_document(previous_key)
	_update_controller_dirty_state()
	return result


func _apply_install(_preview: Dictionary) -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_bytes,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_dirty = false
		_refresh_gamefs()
	_update_controller_dirty_state()
	return result


func _clear_preflight_state() -> void:
	_preflight_pending_path = ""
	_preflight_pending_preview = {}
	_preflight_pending_kind = ""


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"wav",
		null,
		_bytes,
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
	return _ensure_extension(_file_name, "wav")


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
	if _bytes.is_empty():
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
