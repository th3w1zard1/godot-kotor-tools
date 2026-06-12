@tool
extends "./kotor_workspace_editor.gd"
class_name KotorLTRWorkspaceEditor

const LTRParser := preload("../../../formats/ltr_parser.gd")
const LTRResource := preload("../../../resources/ltr_resource.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _tree: Tree
var _triple_row_option: OptionButton
var _triple_col_option: OptionButton
var _triple_row_index := 0
var _triple_col_index := 0
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _resource: LTRResource
var _source_path := ""
var _file_name := "names.ltr"
var _dirty := false
var _status_text := ""
var _document_key := ""

var _pending_resource: LTRResource
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


func open_resource(resource: LTRResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_disconnect_resource_signal()
	_resource = resource
	if _resource == null:
		_clear_document_state("No LTR resource is loaded.")
		return
	_connect_resource_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "names.ltr"
	_dirty = false
	_status_text = ""
	_register_controller_document()
	_refresh_view()


func open_ltr_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_ltr_bytes(path, bytes, path if path.get_extension().to_lower() == "ltr" else "")


func open_ltr_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := LTRParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "names.ltr"))
		return
	var resource := LTRResource.new()
	resource.apply_parser_result(parsed)
	open_resource(resource, source_path, _guess_loaded_file_name(label, "names.ltr"))
	_status_text = "Loaded %s" % _current_file_name()
	_refresh_status()


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, "ltr")
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
	open_btn.text = "Open LTR..."
	open_btn.pressed.connect(_open_ltr)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save LTR"
	save_btn.pressed.connect(_save_ltr)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_ltr_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_ltr_to_override)
	_toolbar.add_child(install_btn)

	var triple_row_label := Label.new()
	triple_row_label.text = "Triple row"
	_toolbar.add_child(triple_row_label)
	_triple_row_option = OptionButton.new()
	_triple_row_option.item_selected.connect(_on_triple_context_changed)
	_toolbar.add_child(_triple_row_option)

	var triple_col_label := Label.new()
	triple_col_label.text = "col"
	_toolbar.add_child(triple_col_label)
	_triple_col_option = OptionButton.new()
	_triple_col_option.item_selected.connect(_on_triple_context_changed)
	_toolbar.add_child(_triple_col_option)

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
	_refresh_triple_selectors()
	_refresh_tree()
	_refresh_status()


func _refresh_triple_selectors() -> void:
	if _triple_row_option == null or _triple_col_option == null or _resource == null:
		return
	_triple_row_option.clear()
	_triple_col_option.clear()
	for letter_index in _resource.letter_count:
		var label := LTRParser.letter_label(_resource.letter_count, letter_index)
		_triple_row_option.add_item(label, letter_index)
		_triple_col_option.add_item(label, letter_index)
	_triple_row_index = clampi(_triple_row_index, 0, maxi(_resource.letter_count - 1, 0))
	_triple_col_index = clampi(_triple_col_index, 0, maxi(_resource.letter_count - 1, 0))
	_triple_row_option.select(_triple_row_index)
	_triple_col_option.select(_triple_col_index)


func _on_triple_context_changed(_index: int) -> void:
	if _triple_row_option != null:
		_triple_row_index = _triple_row_option.get_selected_id()
	if _triple_col_option != null:
		_triple_col_index = _triple_col_option.get_selected_id()
	_refresh_tree()
	_refresh_status()


func _refresh_tree() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _resource == null:
		return
	_tree.columns = 2
	_tree.set_column_title(0, "Letter / Position")
	_tree.set_column_title(1, "Probability")
	_tree.column_titles_visible = true
	var root_item := _tree.create_item()
	root_item.set_text(0, "Single-letter probabilities")
	_append_probability_block(root_item, "single", -1, -1)

	var doubles_root := _tree.create_item()
	doubles_root.set_text(0, "Double-letter probabilities")
	doubles_root.set_selectable(0, false)
	for context_index in _resource.letter_count:
		var context_item := _tree.create_item(doubles_root)
		var context_label := LTRParser.letter_label(_resource.letter_count, context_index)
		context_item.set_text(0, "After '%s'" % context_label)
		context_item.set_selectable(0, false)
		_append_probability_block(context_item, "double", context_index, -1)

	var triples_root := _tree.create_item()
	triples_root.set_text(0, "Triple-letter probabilities")
	triples_root.set_selectable(0, false)
	var triple_context := _tree.create_item(triples_root)
	var row_label := LTRParser.letter_label(_resource.letter_count, _triple_row_index)
	var col_label := LTRParser.letter_label(_resource.letter_count, _triple_col_index)
	triple_context.set_text(0, "After '%s' + '%s'" % [row_label, col_label])
	triple_context.set_selectable(0, false)
	_append_probability_block(triple_context, "triple", _triple_row_index, _triple_col_index)

	if _summary_label != null:
		_summary_label.text = "%s Edit doubles in tree; pick triple row/col in toolbar." % _resource.summary_text()


func _append_probability_block(
	parent_item: TreeItem,
	kind: String,
	context_index: int,
	column_index: int
) -> void:
	for position in ["start", "middle", "end"]:
		var section := _tree.create_item(parent_item)
		section.set_text(0, position.capitalize())
		section.set_selectable(0, false)
		for letter_index in _resource.letter_count:
			var item := _tree.create_item(section)
			var label := LTRParser.letter_label(_resource.letter_count, letter_index)
			item.set_text(0, label)
			var metadata := {
				"kind": kind,
				"position": position,
				"letter_index": letter_index,
			}
			if kind == "double":
				metadata["context_index"] = context_index
			elif kind == "triple":
				metadata["row_index"] = context_index
				metadata["column_index"] = column_index
			item.set_metadata(0, metadata)
			var probability := _probability_for_metadata(metadata)
			item.set_text(1, "%.6f" % probability)
			item.set_editable(1, true)


func _probability_for_metadata(metadata: Dictionary) -> float:
	var kind := str(metadata.get("kind", ""))
	var position := str(metadata.get("position", ""))
	var letter_index := int(metadata.get("letter_index", -1))
	match kind:
		"single":
			return _resource.get_single_probability(position, letter_index)
		"double":
			return _resource.get_double_probability(
				int(metadata.get("context_index", -1)),
				position,
				letter_index
			)
		"triple":
			return _resource.get_triple_probability(
				int(metadata.get("row_index", -1)),
				int(metadata.get("column_index", -1)),
				position,
				letter_index
			)
	return 0.0


func _on_tree_item_edited() -> void:
	if _resource == null:
		return
	var item := _tree.get_edited()
	if item == null or _tree.get_edited_column() != 1:
		return
	var metadata: Dictionary = item.get_metadata(0)
	var kind := str(metadata.get("kind", ""))
	if kind != "single" and kind != "double" and kind != "triple":
		return
	var text := item.get_text(1).strip_edges()
	if not text.is_valid_float():
		_status_text = "Probability must be a number."
		_refresh_tree()
		_refresh_status()
		return
	var changed := false
	match kind:
		"single":
			changed = _resource.set_single_probability(
				str(metadata.get("position", "")),
				int(metadata.get("letter_index", -1)),
				float(text)
			)
		"double":
			changed = _resource.set_double_probability(
				int(metadata.get("context_index", -1)),
				str(metadata.get("position", "")),
				int(metadata.get("letter_index", -1)),
				float(text)
			)
		"triple":
			changed = _resource.set_triple_probability(
				int(metadata.get("row_index", -1)),
				int(metadata.get("column_index", -1)),
				str(metadata.get("position", "")),
				int(metadata.get("letter_index", -1)),
				float(text)
			)
	if changed:
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


func _open_ltr() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.ltr ; KotOR Letter Table"]),
		"Open LTR"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_ltr_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _save_ltr() -> void:
	if _resource == null:
		return
	if _source_path.is_empty():
		_save_ltr_as()
		return
	save_document_to_path(_source_path)


func _save_ltr_as() -> void:
	if _resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.ltr ; KotOR Letter Table"]),
		"Save LTR As",
		_source_path.get_base_dir() if not _source_path.is_empty() else "",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _install_ltr_to_override() -> void:
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
	_clear_preflight_state()
	_update_controller_dirty_state()
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
	_file_name = "names.ltr"
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
		"ltr",
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
	return _ensure_extension(_file_name, "ltr")


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
	if candidate.get_extension().to_lower() == "ltr":
		return candidate
	return fallback
