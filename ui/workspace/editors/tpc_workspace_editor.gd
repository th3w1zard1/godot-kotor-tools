@tool
extends "./kotor_workspace_editor.gd"
class_name KotorTPCWorkspaceEditor

const TPCReader := preload("../../../formats/tpc_reader.gd")
const TPCWriter := preload("../../../formats/tpc_writer.gd")
const TpcBatchExporter := preload("../../../formats/tpc_batch_exporter.gd")
const KotorMediaToolBridge := preload("../../../resources/scripts/kotor_media_tool_bridge.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _preview: TextureRect
var _meta_label: RichTextLabel
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _bytes: PackedByteArray = PackedByteArray()
var _metadata: Dictionary = {}
var _source_path := ""
var _file_name := "texture.tpc"
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
		open_tpc_bytes(pending_bytes, pending_source_path, pending_file_name)


func open_tpc_bytes(data: PackedByteArray, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_bytes = data
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_bytes = data
	_metadata = TPCReader.read_metadata(data)
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "texture.tpc"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_tpc_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_tpc_bytes(bytes, path, path.get_file())


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _bytes.is_empty():
		return {}
	var target_path := _ensure_extension(path, "tpc")
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
	open_btn.text = "Open TPC..."
	open_btn.pressed.connect(_open_tpc)
	_toolbar.add_child(open_btn)

	var import_image_btn := Button.new()
	import_image_btn.text = "Import TGA/PNG..."
	import_image_btn.pressed.connect(_import_image_as_tpc)
	_toolbar.add_child(import_image_btn)

	var export_tga_btn := Button.new()
	export_tga_btn.text = "Export TGA..."
	export_tga_btn.pressed.connect(_export_tga)
	_toolbar.add_child(export_tga_btn)

	var batch_export_btn := Button.new()
	batch_export_btn.text = "Batch Export TGA..."
	batch_export_btn.pressed.connect(_batch_export_tga)
	_toolbar.add_child(batch_export_btn)

	var save_btn := Button.new()
	save_btn.text = "Save TPC"
	save_btn.pressed.connect(_save_tpc)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_tpc_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_tpc_to_override)
	_toolbar.add_child(install_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.custom_minimum_size = Vector2(256, 256)
	add_child(_preview)

	_meta_label = RichTextLabel.new()
	_meta_label.fit_content = true
	_meta_label.scroll_active = false
	add_child(_meta_label)

	_refresh_status()


func _refresh_view() -> void:
	_refresh_preview()
	_refresh_metadata()
	_refresh_status()


func _refresh_preview() -> void:
	if _preview == null:
		return
	if _bytes.is_empty() or not _metadata.get("ok", false):
		_preview.texture = null
		return
	var image := TPCReader.read_image(_bytes)
	if image == null:
		_preview.texture = null
		_status_text = "TPC preview unavailable for this encoding."
		return
	_preview.texture = ImageTexture.create_from_image(image)


func _refresh_metadata() -> void:
	if _meta_label == null:
		return
	if not _metadata.get("ok", false):
		_meta_label.text = "[color=red]Invalid or unsupported TPC.[/color]"
		return
	var lines: PackedStringArray = PackedStringArray([
		"[b]Dimensions:[/b] %dx%d" % [_metadata.get("width", 0), _metadata.get("height", 0)],
		"[b]Encoding:[/b] %s" % _metadata.get("encoding_name", "?"),
		"[b]Mipmap levels:[/b] %d" % _metadata.get("mipmap_count", 0),
		"[b]Cube map:[/b] %s" % ("yes" if _metadata.get("is_cube_map", false) else "no"),
		"[b]TXI length:[/b] %d bytes" % _metadata.get("txi_length", 0),
	])
	_meta_label.text = "\n".join(lines)


func _import_image_as_tpc() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.tga ; Targa Image", "*.png ; PNG Image"]),
		"Import Image as TPC"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_image_as_rgba_tpc(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _load_image_as_rgba_tpc(path: String) -> void:
	var image := Image.new()
	var extension := path.get_extension().to_lower()
	var load_error := ERR_FILE_UNRECOGNIZED
	match extension:
		"png":
			load_error = image.load_png(path)
		"tga":
			load_error = image.load(path)
		_:
			load_error = image.load(path)
	if load_error != OK:
		_status_text = "Failed to load image: %s" % path.get_file()
		_refresh_status()
		return

	var alpha_test := float(_metadata.get("alpha_test", 0.0)) if _metadata.get("ok", false) else 0.0
	var bytes := TPCWriter.serialize_rgba(image, alpha_test)
	if bytes.is_empty():
		_status_text = "Failed to encode RGBA TPC from %s" % path.get_file()
		_refresh_status()
		return

	_bytes = bytes
	_metadata = TPCReader.read_metadata(_bytes)
	if not _file_name.is_empty():
		_file_name = _file_name.get_basename() + ".tpc"
	else:
		_file_name = path.get_file().get_basename() + ".tpc"
	_dirty = true
	_status_text = "Imported %s as RGBA TPC" % path.get_file()
	_register_controller_document()
	_refresh_view()


func _batch_export_tga() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Batch Export TGA from TPC folder"
	if _editor_state != null and _editor_state.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = _editor_state.call("resolve_dialog_start_dir", "")
	dialog.dir_selected.connect(func(dir_path: String) -> void:
		_run_batch_export(dir_path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _run_batch_export(dir_path: String) -> void:
	var cli_path: String = ""
	if _editor_state != null:
		cli_path = str(_editor_state.get("pykotor_cli_path"))
	var result := TpcBatchExporter.batch_directory(dir_path, {"pykotor_cli_path": cli_path})
	_status_text = str(result.get("summary", "Batch TGA export finished."))
	var failed: Array = result.get("failed", [])
	if not failed.is_empty():
		var first: Dictionary = failed[0]
		_status_text += " First error: %s (%s)" % [
			first.get("message", "?"),
			str(first.get("tpc_path", "")).get_file(),
		]
	_refresh_status()


func _export_tga() -> void:
	if _bytes.is_empty():
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.tga ; Targa Image"]),
		"Export TGA",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name().get_basename() + ".tga"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_run_texture_export(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _run_texture_export(output_path: String) -> void:
	var temp_input := _write_temp_tpc()
	if temp_input.is_empty():
		_status_text = "Failed to write temporary TPC for export."
		_refresh_status()
		return
	var target := output_path
	if target.get_extension().to_lower() != "tga":
		target = "%s.tga" % target
	var result: Dictionary = KotorMediaToolBridge.run_texture_convert(
		temp_input,
		target,
		_editor_state.get("pykotor_cli_path") if _editor_state != null else ""
	)
	if result.get("ok", false):
		_status_text = "Exported TGA to %s" % target.get_file()
	else:
		_status_text = result.get("message", "texture-convert failed")
	_refresh_status()


func _write_temp_tpc() -> String:
	var dir := DirAccess.open("user://")
	if dir == null:
		return ""
	dir.make_dir_recursive("kotor_tools/tmp")
	var temp_path := "user://kotor_tools/tmp/export_source.tpc"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_buffer(_bytes)
	file.close()
	return ProjectSettings.globalize_path(temp_path)


func _open_tpc() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.tpc ; KotOR Texture"]),
		"Open TPC"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_tpc_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _save_tpc() -> void:
	if _bytes.is_empty():
		return
	if _source_path.is_empty():
		_save_tpc_as()
		return
	save_document_to_path(_source_path)


func _save_tpc_as() -> void:
	if _bytes.is_empty():
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.tpc ; KotOR Texture"]),
		"Save TPC As",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _install_tpc_to_override() -> void:
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
		"tpc",
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
	return _ensure_extension(_file_name, "tpc")


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
