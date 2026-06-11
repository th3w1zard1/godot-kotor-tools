@tool
extends "./kotor_workspace_editor.gd"
class_name KotorMDLWorkspaceEditor

const MdlBatchExporter := preload("../../../formats/mdl_batch_exporter.gd")
const MdlModelMetadataHelper := preload("../../../editor/tools/mdl_model_metadata_helper.gd")
const MdlPreviewViewport := preload("../panels/mdl_preview_viewport.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _meta_label: RichTextLabel
var _preview_viewport: MdlPreviewViewport
var _export_mdx_btn: Button
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _mdl_bytes: PackedByteArray = PackedByteArray()
var _mdx_bytes: PackedByteArray = PackedByteArray()
var _source_path := ""
var _file_name := "model.mdl"
var _status_text := ""
var _document_key := ""

var _pending_mdl_bytes: PackedByteArray
var _pending_mdx_bytes: PackedByteArray
var _pending_source_path := ""
var _pending_file_name := ""

var _preflight_pending_path := ""
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_kind := ""
var _preflight_pending_mdx := false
var _skip_preflight_for_testing := false


func _on_workspace_setup() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_mutation_service = _resolve_mutation_service()
	_build_ui()
	if not _pending_mdl_bytes.is_empty():
		var pending_mdl := _pending_mdl_bytes
		var pending_mdx := _pending_mdx_bytes
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_mdl_bytes = PackedByteArray()
		_pending_mdx_bytes = PackedByteArray()
		_pending_source_path = ""
		_pending_file_name = ""
		open_mdl_bytes(pending_mdl, pending_source_path, pending_file_name, pending_mdx)


func open_mdl_bytes(
		mdl_bytes: PackedByteArray,
		source_path: String = "",
		file_name: String = "",
		mdx_bytes: PackedByteArray = PackedByteArray()
) -> void:
	if not is_node_ready():
		_pending_mdl_bytes = mdl_bytes
		_pending_mdx_bytes = mdx_bytes
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_mdl_bytes = mdl_bytes
	_mdx_bytes = mdx_bytes
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "model.mdl"
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_mdl_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var mdx_path := "%s.mdx" % path.get_basename()
	var mdx := PackedByteArray()
	if FileAccess.file_exists(mdx_path):
		mdx = FileAccess.get_file_as_bytes(mdx_path)
	open_mdl_bytes(bytes, path, path.get_file(), mdx)


func is_document_dirty() -> bool:
	return false


func save_document_to_path(path: String) -> Dictionary:
	if _mdl_bytes.is_empty():
		return {}
	var target_path := _ensure_extension(path, "mdl")
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, _mdl_bytes)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_export(target_path, preview, false)
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_preflight_pending_mdx = false
	_show_preflight_dialog(preview)
	return {}


func install_document_to_override() -> Dictionary:
	if _mdl_bytes.is_empty():
		return {}
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_mdl_bytes
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
	_preflight_pending_mdx = false
	_show_preflight_dialog(preview)
	return {}


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open MDL..."
	open_btn.pressed.connect(_open_mdl)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Export MDL..."
	save_btn.pressed.connect(_export_mdl)
	_toolbar.add_child(save_btn)

	_export_mdx_btn = Button.new()
	_export_mdx_btn.text = "Export MDX..."
	_export_mdx_btn.pressed.connect(_export_mdx)
	_export_mdx_btn.visible = false
	_toolbar.add_child(_export_mdx_btn)

	var install_btn := Button.new()
	install_btn.text = "Install MDL to Override"
	install_btn.pressed.connect(_install_mdl_to_override)
	_toolbar.add_child(install_btn)

	var batch_copy_btn := Button.new()
	batch_copy_btn.text = "Batch Copy MDL Folder..."
	batch_copy_btn.pressed.connect(_batch_copy_mdl_folder)
	_toolbar.add_child(batch_copy_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_meta_label = RichTextLabel.new()
	_meta_label.fit_content = true
	_meta_label.scroll_active = false
	add_child(_meta_label)

	_preview_viewport = MdlPreviewViewport.new()
	_preview_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_preview_viewport)

	_refresh_status()


func _refresh_view() -> void:
	_refresh_metadata()
	_refresh_preview()
	_refresh_status()


func _refresh_preview() -> void:
	if _preview_viewport == null:
		return
	if _mdl_bytes.is_empty():
		_preview_viewport.clear_preview()
		return
	var metadata := MdlModelMetadataHelper.summarize_bytes(_mdl_bytes, _mdx_bytes)
	if not metadata.get("ok", false):
		_preview_viewport.clear_preview()
		return
	_preview_viewport.set_mdl_bytes(_mdl_bytes, _mdx_bytes)


func _refresh_metadata() -> void:
	if _meta_label == null:
		return
	if _export_mdx_btn != null:
		_export_mdx_btn.visible = not _mdx_bytes.is_empty()
	if _mdl_bytes.is_empty():
		_meta_label.text = "[color=gray]No MDL loaded.[/color]"
		return
	var metadata := MdlModelMetadataHelper.summarize_bytes(_mdl_bytes, _mdx_bytes)
	if not metadata.get("ok", false):
		_meta_label.text = "[color=red]%s[/color]" % metadata.get("message", "Invalid MDL")
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]Model:[/b] %s" % metadata.get("model_name", ""))
	lines.append("[b]Vertices:[/b] %d" % int(metadata.get("vertex_count", 0)))
	lines.append("[b]Faces:[/b] %d" % int(metadata.get("face_count", 0)))
	var bounds: AABB = metadata.get("bounds", AABB())
	lines.append("[b]Bounds size:[/b] %s" % bounds.size)
	lines.append("[b]MDL size:[/b] %d bytes" % _mdl_bytes.size())
	if not _mdx_bytes.is_empty():
		lines.append("[b]MDX size:[/b] %d bytes" % _mdx_bytes.size())
	else:
		lines.append("[b]MDX:[/b] not loaded")
	_meta_label.text = "\n".join(lines)


func _open_mdl() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.mdl ; KotOR Model"]),
		"Open MDL"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_mdl_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _export_mdl() -> void:
	if _mdl_bytes.is_empty():
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.mdl ; KotOR Model"]),
		"Export MDL",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _export_mdx() -> void:
	if _mdx_bytes.is_empty():
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.mdx ; KotOR Model Extension"]),
		"Export MDX",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name().get_basename() + ".mdx"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_export_mdx_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _export_mdx_to_path(path: String) -> void:
	var target_path := _ensure_extension(path, "mdx")
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, _mdx_bytes)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "MDX export failed")
		_refresh_status()
		return
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "MDX file is already up to date")
		_refresh_status()
		return
	if _skip_preflight_for_testing:
		_apply_export(target_path, preview, false)
		return
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_preflight_pending_mdx = true
	_show_preflight_dialog(preview)


func _install_mdl_to_override() -> void:
	install_document_to_override()


func _batch_copy_mdl_folder() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Select MDL source folder"
	if _editor_state != null and _editor_state.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = _editor_state.call("resolve_dialog_start_dir", "")
	dialog.dir_selected.connect(func(source_dir: String) -> void:
		_prompt_batch_copy_output_dir(source_dir)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _prompt_batch_copy_output_dir(source_dir: String) -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Select MDL output folder"
	if _editor_state != null and _editor_state.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = _editor_state.call("resolve_dialog_start_dir", source_dir)
	dialog.dir_selected.connect(func(output_dir: String) -> void:
		_run_batch_copy_mdl_folder(source_dir, output_dir)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _run_batch_copy_mdl_folder(source_dir: String, output_dir: String) -> void:
	var result := MdlBatchExporter.batch_directory(source_dir, output_dir)
	_status_text = MdlBatchExporter.format_report(result)
	_refresh_status()


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancelled.connect(_on_preflight_cancelled)
	_preflight_dialog.show_preview(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "export" and not _preflight_pending_path.is_empty():
		_apply_export(_preflight_pending_path, _preflight_pending_preview, _preflight_pending_mdx)
	elif _preflight_pending_kind == "install":
		_apply_install(_preflight_pending_preview)
	_clear_preflight_state()
	_refresh_status()


func _on_preflight_cancelled() -> void:
	_clear_preflight_state()
	_status_text = "Export/install cancelled."
	_refresh_status()


func _apply_export(target_path: String, _preview: Dictionary, is_mdx: bool) -> Dictionary:
	var payload := _mdx_bytes if is_mdx else _mdl_bytes
	var result: Dictionary = _mutation_service.apply_export_to_path(target_path, payload, true)
	_status_text = _mutation_message(result)
	if result.get("applied", false) and not is_mdx:
		_source_path = target_path
		_file_name = target_path.get_file()
		_register_controller_document()
	return result


func _apply_install(_preview: Dictionary) -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_mdl_bytes,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_refresh_gamefs()
	return result


func _clear_preflight_state() -> void:
	_preflight_pending_path = ""
	_preflight_pending_preview = {}
	_preflight_pending_kind = ""
	_preflight_pending_mdx = false


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"mdl",
		null,
		_mdl_bytes,
		_source_path,
		_current_file_name(),
		{}
	)
	_document_key = str(entry.get("key", ""))


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


func _refresh_status() -> void:
	if _path_label != null:
		_path_label.text = _current_file_name() if not _mdl_bytes.is_empty() else ""
	_emit_status_text(_status_text)


func _current_file_name() -> String:
	return _file_name if not _file_name.is_empty() else "model.mdl"


func _mutation_message(result: Dictionary) -> String:
	return str(result.get("message", result.get("summary", "Done")))


func _ensure_extension(path: String, extension: String) -> String:
	if path.get_extension().to_lower() == extension:
		return path
	return "%s.%s" % [path.get_basename(), extension]


func _make_dialog(
		file_mode: EditorFileDialog.FileMode,
		filters: PackedStringArray,
		title: String,
		current_dir: String = "",
		current_file: String = ""
) -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = file_mode
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = title
	dialog.filters = filters
	if not current_dir.is_empty():
		dialog.current_dir = current_dir
	if not current_file.is_empty():
		dialog.current_file = current_file
	return dialog
