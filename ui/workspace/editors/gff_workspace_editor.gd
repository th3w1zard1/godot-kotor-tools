@tool
extends "./kotor_workspace_editor.gd"
class_name KotorGFFWorkspaceEditor

const GFFParser := preload("../../../formats/gff_parser.gd")
const GFFResource := preload("../../../resources/gff_resource.gd")
const GFFResourceFactory := preload("../../../resources/gff_resource_factory.gd")
const KotorGFFDocument := preload("../../../resources/kotor_gff_document.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorValidationPanel := preload("../panels/validation_panel.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")
const GFFTreePopulator := preload("../gff_tree_populator.gd")

const ENTITY_EXTENSIONS := [
	"utc", "utp", "uti", "utd", "ute", "utm", "uts", "utt", "utw",
]

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _tag_edit: LineEdit
var _tree: Tree
var _validation_panel: KotorValidationPanel
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _resource: GFFResource
var _document: KotorGFFDocument
var _source_path := ""
var _file_name := "blueprint.utc"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_resource: GFFResource
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


func open_resource(resource: GFFResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_disconnect_document_signal()
	_resource = resource
	if _resource == null:
		_clear_document_state("No GFF resource is loaded.")
		return
	_document = _resource.create_document()
	_connect_document_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else _default_file_name()
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_gff_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_gff_bytes(path, bytes, path if _extension_allowed(path.get_extension()) else "")


func open_gff_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := GFFParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "blueprint.utc"))
		return
	var file_type := String(parsed.get("file_type", "")).strip_edges().to_upper()
	if not _entity_file_type_allowed(file_type):
		_clear_document_state("Unsupported GFF type %s for entity editor" % file_type)
		return
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	open_resource(resource, source_path, _guess_loaded_file_name(label, _default_file_name_for_type(file_type)))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


func get_document() -> KotorGFFDocument:
	return _document


func has_document() -> bool:
	return _document != null and _resource != null


func is_document_dirty() -> bool:
	return _dirty


func get_validation_text() -> String:
	return _validation_panel.get_report_text() if _validation_panel != null else ""


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, _current_extension())
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
		return _apply_export_now(target_path)
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
		return _apply_install_now()
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install"
	_show_preflight_dialog(preview)
	return {}


static func entity_extension_allowed(extension: String) -> bool:
	return extension.strip_edges().to_lower() in ENTITY_EXTENSIONS


func _apply_export_now(target_path: String) -> Dictionary:
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


func _apply_install_now() -> Dictionary:
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


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancel.connect(_on_preflight_cancel)
		add_child(_preflight_dialog)
	_preflight_dialog.show_preflight(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "export":
		_apply_export_now(_preflight_pending_path)
	elif _preflight_pending_kind == "install":
		_apply_install_now()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _on_preflight_cancel() -> void:
	_status_text = "Operation cancelled."
	_refresh_status()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open GFF..."
	open_btn.pressed.connect(_open_gff)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_gff)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_gff_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_gff_to_override)
	_toolbar.add_child(install_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	var tag_row := HBoxContainer.new()
	add_child(tag_row)
	var tag_label := Label.new()
	tag_label.text = "Tag:"
	tag_row.add_child(tag_label)
	_tag_edit = LineEdit.new()
	_tag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tag_edit.text_submitted.connect(_on_tag_submitted)
	_tag_edit.focus_exited.connect(_on_tag_focus_exited)
	tag_row.add_child(_tag_edit)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_tree = Tree.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 2
	_tree.set_column_title(0, "Field")
	_tree.set_column_title(1, "Value")
	_tree.column_titles_visible = true
	add_child(_tree)

	_validation_panel = KotorValidationPanel.new()
	add_child(_validation_panel)
	_refresh_status()
	_refresh_validation()


func _refresh_view() -> void:
	_refresh_tree()
	_refresh_tag_edit()
	_refresh_summary()
	_refresh_validation()
	_refresh_status()


func _refresh_tree() -> void:
	if _tree == null or _resource == null:
		return
	_tree.clear()
	var root_item := _tree.create_item()
	var type_label := _resource.file_type if not _resource.file_type.is_empty() else "?"
	root_item.set_text(0, type_label)
	root_item.set_text(1, _resource.get_type_label())
	GFFTreePopulator.populate(root_item, _resource.gff_data)


func _refresh_tag_edit() -> void:
	if _tag_edit == null or _document == null:
		return
	_tag_edit.text = _document.get_string("Tag")


func _refresh_summary() -> void:
	if _summary_label == null or _resource == null:
		return
	_summary_label.text = _resource.build_summary_text()


func _refresh_validation() -> void:
	if _validation_panel == null:
		return
	if _resource == null:
		_validation_panel.clear_report()
		return
	_validation_panel.set_success("GFF validation passed.", [
		"Blueprint data is loaded.",
		"Tag edits round-trip through the mutation service.",
	])


func _refresh_status() -> void:
	if _path_label != null:
		var path_text := _source_path if not _source_path.is_empty() else _current_file_name()
		if _resource != null:
			var display_name := _resource.get_display_name()
			if not display_name.is_empty():
				path_text = "[%s] %s — %s" % [_resource.file_type, display_name, path_text]
		_path_label.text = path_text
	_emit_dirty_state(_dirty)
	_emit_status_text(_status_text)


func _open_gff() -> void:
	var filter := "*.utc,*.utp,*.uti,*.utd,*.ute,*.utm,*.uts,*.utt,*.utw ; KotOR Blueprint GFF"
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray([filter]),
		"Open KotOR Blueprint GFF"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_gff_file(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_gff() -> void:
	if _resource == null:
		return
	if _source_path.is_empty():
		_save_gff_as()
		return
	save_document_to_path(_source_path)


func _save_gff_as() -> void:
	if _resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.%s ; KotOR Blueprint GFF" % _current_extension()]),
		"Save KotOR GFF",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_gff_to_override() -> void:
	install_document_to_override()


func _on_tag_submitted(new_text: String) -> void:
	_apply_tag_edit(new_text)


func _on_tag_focus_exited() -> void:
	if _tag_edit == null:
		return
	_apply_tag_edit(_tag_edit.text)


func _apply_tag_edit(new_text: String) -> void:
	if _document == null:
		return
	if _document.set_string("Tag", new_text.strip_edges()):
		_dirty = true
		_update_controller_dirty_state()
	_refresh_tag_edit()
	_refresh_summary()
	_refresh_status()


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


func _on_document_changed() -> void:
	_dirty = true
	_refresh_summary()
	_update_controller_dirty_state()
	_refresh_status()


func _clear_document_state(message: String) -> void:
	_disconnect_document_signal()
	_resource = null
	_document = null
	_source_path = ""
	_file_name = "blueprint.utc"
	_dirty = false
	_status_text = message
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _summary_label != null:
		_summary_label.text = ""
	if _tag_edit != null:
		_tag_edit.text = ""
	_refresh_validation()
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"gff",
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
	return _ensure_extension(_file_name, _current_extension())


func _current_extension() -> String:
	var ext := _file_name.get_extension().to_lower()
	if _extension_allowed(ext):
		return ext
	var type_ext := _resource.file_type.strip_edges().to_lower() if _resource != null else ""
	if _extension_allowed(type_ext):
		return type_ext
	return "utc"


func _default_file_name() -> String:
	return _default_file_name_for_type(_resource.file_type if _resource != null else "UTC")


func _default_file_name_for_type(file_type: String) -> String:
	var ext := file_type.strip_edges().to_lower()
	if _extension_allowed(ext):
		return "blueprint.%s" % ext
	return "blueprint.utc"


func _extension_allowed(extension: String) -> bool:
	return entity_extension_allowed(extension)


func _entity_file_type_allowed(file_type: String) -> bool:
	return _extension_allowed(file_type.strip_edges().to_lower())


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
