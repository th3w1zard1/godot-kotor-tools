@tool
extends "./kotor_workspace_editor.gd"
class_name KotorDLGWorkspaceEditor

const GFFParser := preload("../../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../../resources/gff_resource_factory.gd")
const DLGResource := preload("../../../resources/typed/dlg_resource.gd")
const KotorDLGDocument := preload("../../../resources/documents/kotor_dlg_document.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorModdingPipeline := preload("../../../editor/modding/kotor_modding_pipeline.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorValidationPanel := preload("../panels/validation_panel.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")
const TypedFieldHelpers := preload("../typed_field_helpers.gd")
const GFFTreePopulator := preload("../gff_tree_populator.gd")
const KotorResRefPickerDialog := preload("../dialogs/kotor_resref_picker_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _dlg_tree: Tree
var _dlg_details: VBoxContainer
var _validation_panel: KotorValidationPanel
var _preflight_dialog: KotorPreflightDialog
var _array_context_menu: PopupMenu

var _modding_pipeline: RefCounted
var _dlg_resource: DLGResource
var _dlg_document: KotorDLGDocument
var _dlg_source_path := ""
var _dlg_file_name := "dialogue.dlg"
var _dlg_dirty := false
var _dlg_status_text := ""
var _dlg_selection: Dictionary = {}
var _document_key := ""

# Context menu state
var _context_array_field := ""
var _context_array_index := -1

var _pending_resource: DLGResource
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
	if _modding_pipeline == null:
		_modding_pipeline = KotorModdingPipeline.new()
	_build_ui()
	if _pending_resource != null:
		var pending_resource := _pending_resource
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_resource = null
		_pending_source_path = ""
		_pending_file_name = ""
		open_resource(pending_resource, pending_source_path, pending_file_name)


func is_dirty() -> bool:
	return _dlg_dirty


func get_status_text() -> String:
	return _dlg_status_text


func open_document(document: Variant, resource: Variant = null) -> void:
	if document is KotorDLGDocument and resource is DLGResource:
		open_resource(resource as DLGResource, "", _dlg_file_name)


func open_resource(resource: DLGResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	if resource == null:
		_clear_document_state("No dialogue resource is loaded.")
		return
	_disconnect_document_signal()
	_dlg_resource = resource
	_dlg_document = _dlg_resource.create_document() as KotorDLGDocument
	_connect_document_signal()
	_dlg_source_path = source_path if source_path.is_absolute_path() else ""
	_dlg_file_name = file_name.get_file() if not file_name.is_empty() else "dialogue.dlg"
	_dlg_dirty = false
	_dlg_status_text = ""
	_dlg_selection = {"kind": "root"}
	_register_controller_document()
	_refresh_dlg_tree()
	_refresh_dlg_detail()
	_refresh_dlg_validation()
	_refresh_dlg_status()


func open_dlg_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_dlg_status_text = "Failed to open %s" % path.get_file()
		_refresh_dlg_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_dlg_bytes(path, bytes)


func open_dlg_bytes(label: String, data: PackedByteArray) -> void:
	var parsed: Dictionary = GFFParser.parse_bytes(data)
	if parsed.is_empty() or str(parsed.get("file_type", "")).to_upper() != "DLG":
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "dialogue.dlg"))
		return
	var resource = GFFResourceFactory.create_from_parser_result(parsed)
	if not resource is DLGResource:
		_clear_document_state("Unsupported DLG payload in %s" % _guess_loaded_file_name(label, "dialogue.dlg"))
		return
	open_resource(
		resource as DLGResource,
		label if label.is_absolute_path() else "",
		_guess_loaded_file_name(label, "dialogue.dlg")
	)
	_dlg_status_text = "Loaded %s" % _current_dlg_file_name()
	_refresh_dlg_status()


func has_document() -> bool:
	return _dlg_document != null


func get_document() -> KotorDLGDocument:
	return _dlg_document


func is_document_dirty() -> bool:
	return _dlg_dirty


func get_validation_text() -> String:
	return _validation_panel.get_report_text() if _validation_panel != null else ""


func save_document_to_path(path: String) -> Dictionary:
	if _dlg_resource == null:
		return {}
	var target_path := _ensure_extension(path, "dlg")
	var preview: Dictionary = _resolve_mutation_service().preview_export_to_path(target_path, _dlg_resource)
	if not preview.get("ok", false):
		_dlg_status_text = preview.get("message", "Export failed")
		_refresh_dlg_status()
		return preview
	
	if preview.get("action", "") == "noop":
		_dlg_dirty = false
		_dlg_status_text = preview.get("message", "File is already up to date")
		_emit_dirty_state(_dlg_dirty)
		_update_controller_dirty_state()
		_refresh_dlg_status()
		return preview
	
	if _skip_preflight_for_testing:
		var previous_key := _document_key
		var result: Dictionary = _resolve_mutation_service().apply_export_to_path(target_path, _dlg_resource, true)
		_dlg_status_text = _mutation_message(result)
		if result.get("applied", false):
			_dlg_source_path = target_path
			_dlg_file_name = target_path.get_file()
			_dlg_dirty = false
			_register_controller_document()
			_remove_previous_controller_document(previous_key)
		_emit_dirty_state(_dlg_dirty)
		_update_controller_dirty_state()
		_refresh_dlg_status()
		return result
	
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_show_preflight_dialog(preview)
	return {}


func install_document_to_override() -> Dictionary:
	if _dlg_resource == null:
		return {}
	var issues := _get_validation_issues()
	if not issues.is_empty():
		var result := {
			"ok": false,
			"status": "validation_failed",
			"message": "Resolve validation issues before installing to override.",
			"issues": issues,
		}
		_dlg_status_text = String(result.get("message", ""))
		_refresh_dlg_validation()
		_refresh_dlg_status()
		return result
	
	var preview: Dictionary = _resolve_mutation_service().preview_install_to_override(
		_resolve_gamefs(),
		_current_dlg_file_name(),
		_dlg_resource
	)
	if not preview.get("ok", false):
		_dlg_status_text = preview.get("message", "Install failed")
		_refresh_dlg_validation()
		_refresh_dlg_status()
		return preview
	
	if preview.get("action", "") == "noop":
		_dlg_dirty = false
		_dlg_status_text = preview.get("message", "File is already up to date")
		_emit_dirty_state(_dlg_dirty)
		_update_controller_dirty_state()
		_refresh_dlg_status()
		return preview
	
	if _skip_preflight_for_testing:
		var result: Dictionary = _resolve_mutation_service().apply_install_to_override(
			_resolve_gamefs(),
			_current_dlg_file_name(),
			_dlg_resource,
			true
		)
		_dlg_status_text = _mutation_message(result)
		if result.get("applied", false):
			_dlg_dirty = false
			var editor_state := get_editor_state()
			if editor_state != null and editor_state.has_method("refresh_gamefs"):
				editor_state.call("refresh_gamefs")
		_emit_dirty_state(_dlg_dirty)
		_update_controller_dirty_state()
		_refresh_dlg_status()
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
	_dlg_status_text = "Operation cancelled."
	_refresh_dlg_status()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _apply_export_mutation() -> void:
	if _preflight_pending_preview.is_empty():
		return
	var previous_key := _document_key
	var result: Dictionary = _resolve_mutation_service().apply_export_to_path(
		_preflight_pending_path,
		_dlg_resource,
		true
	)
	_dlg_status_text = _mutation_message(result)
	if result.get("applied", false):
		_dlg_source_path = _preflight_pending_path
		_dlg_file_name = _preflight_pending_path.get_file()
		_dlg_dirty = false
		_register_controller_document()
		_remove_previous_controller_document(previous_key)
	_emit_dirty_state(_dlg_dirty)
	_update_controller_dirty_state()
	_refresh_dlg_status()


func _apply_install_mutation() -> void:
	if _preflight_pending_preview.is_empty():
		return
	var result: Dictionary = _resolve_mutation_service().apply_install_to_override(
		_resolve_gamefs(),
		_current_dlg_file_name(),
		_dlg_resource,
		true
	)
	_dlg_status_text = _mutation_message(result)
	if result.get("applied", false):
		_dlg_dirty = false
		var editor_state := get_editor_state()
		if editor_state != null and editor_state.has_method("refresh_gamefs"):
			editor_state.call("refresh_gamefs")
	_emit_dirty_state(_dlg_dirty)
	_update_controller_dirty_state()
	_refresh_dlg_status()


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open DLG..."
	open_btn.pressed.connect(_open_dlg)
	_toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save DLG"
	save_btn.pressed.connect(_save_dlg)
	_toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As..."
	save_as_btn.pressed.connect(_save_dlg_as)
	_toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_dlg_to_override)
	_toolbar.add_child(install_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_refresh_dlg_validation)
	_toolbar.add_child(validate_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	_dlg_tree = Tree.new()
	_dlg_tree.custom_minimum_size = Vector2(280, 0)
	_dlg_tree.columns = 2
	_dlg_tree.hide_root = true
	_dlg_tree.set_column_title(0, "Dialogue")
	_dlg_tree.set_column_title(1, "Preview")
	_dlg_tree.column_titles_visible = true
	_dlg_tree.item_selected.connect(_on_dlg_item_selected)
	_dlg_tree.item_activated.connect(_on_dlg_item_activated)
	_dlg_tree.item_mouse_selected.connect(_on_dlg_item_mouse_selected)
	split.add_child(_dlg_tree)

	# Setup context menu for array operations
	_array_context_menu = PopupMenu.new()
	_array_context_menu.id_pressed.connect(_on_array_context_menu_selected)
	_dlg_tree.add_child(_array_context_menu)

	var detail_panel := VBoxContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_scroll)

	_dlg_details = VBoxContainer.new()
	_dlg_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_dlg_details)

	_validation_panel = KotorValidationPanel.new()
	detail_panel.add_child(_validation_panel)
	_refresh_dlg_status()
	_refresh_dlg_validation()


func _open_dlg() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.dlg ; KotOR Dialogue"]),
		"Open KotOR Dialogue"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_dlg_file(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_dlg() -> void:
	if _dlg_resource == null:
		return
	if _dlg_source_path.is_empty():
		_save_dlg_as()
		return
	save_document_to_path(_dlg_source_path)


func _save_dlg_as() -> void:
	if _dlg_resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.dlg ; KotOR Dialogue"]),
		"Save KotOR Dialogue",
		_dlg_source_path.get_base_dir() if not _dlg_source_path.is_empty() else "",
		_current_dlg_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_document_to_path(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_dlg_to_override() -> void:
	install_document_to_override()


func _refresh_dlg_tree() -> void:
	if _dlg_tree == null:
		return
	_dlg_tree.clear()
	if _dlg_document == null:
		_refresh_dlg_status()
		return

	var root_item := _dlg_tree.create_item()
	var overview_item := _dlg_tree.create_item(root_item)
	overview_item.set_text(0, "Dialogue")
	overview_item.set_text(1, _dlg_document.get_display_name())
	overview_item.set_metadata(0, {"kind": "root"})
	overview_item.collapsed = false

	var starts_item := _dlg_tree.create_item(root_item)
	starts_item.set_text(0, "Starting Nodes")
	starts_item.set_text(1, str(_dlg_document.get_start_count()))
	starts_item.collapsed = false
	for start_index in range(_dlg_document.get_start_count()):
		var item := _dlg_tree.create_item(starts_item)
		item.set_text(0, "Start %d" % start_index)
		item.set_text(1, _dlg_target_label("start", start_index, -1))
		item.set_metadata(0, {"kind": "start", "index": start_index})

	var entries_item := _dlg_tree.create_item(root_item)
	entries_item.set_text(0, "Entries")
	entries_item.set_text(1, str(_dlg_document.get_entry_count()))
	entries_item.collapsed = false
	for entry_index in range(_dlg_document.get_entry_count()):
		var node_item := _dlg_tree.create_item(entries_item)
		node_item.set_text(0, _dlg_document.build_node_title("entry", entry_index))
		node_item.set_text(1, _dlg_node_preview("entry", entry_index))
		node_item.set_metadata(0, {"kind": "entry", "index": entry_index})
		for link_index in range(_dlg_document.get_node_links("entry", entry_index).size()):
			var link_item := _dlg_tree.create_item(node_item)
			link_item.set_text(0, _dlg_target_label("entry", entry_index, link_index))
			link_item.set_text(1, _dlg_document.build_link_preview("entry", entry_index, link_index))
			link_item.set_metadata(0, {"kind": "link", "owner": "entry", "index": entry_index, "link_index": link_index})

	var replies_item := _dlg_tree.create_item(root_item)
	replies_item.set_text(0, "Replies")
	replies_item.set_text(1, str(_dlg_document.get_reply_count()))
	replies_item.collapsed = false
	for reply_index in range(_dlg_document.get_reply_count()):
		var node_item := _dlg_tree.create_item(replies_item)
		node_item.set_text(0, _dlg_document.build_node_title("reply", reply_index))
		node_item.set_text(1, _dlg_node_preview("reply", reply_index))
		node_item.set_metadata(0, {"kind": "reply", "index": reply_index})
		for link_index in range(_dlg_document.get_node_links("reply", reply_index).size()):
			var link_item := _dlg_tree.create_item(node_item)
			link_item.set_text(0, _dlg_target_label("reply", reply_index, link_index))
			link_item.set_text(1, _dlg_document.build_link_preview("reply", reply_index, link_index))
			link_item.set_metadata(0, {"kind": "link", "owner": "reply", "index": reply_index, "link_index": link_index})

	_select_first_dlg_item(root_item)
	_refresh_dlg_status()


func _on_dlg_item_selected() -> void:
	if _dlg_tree == null:
		return
	var item := _dlg_tree.get_selected()
	if item == null:
		_dlg_selection = {}
	else:
		var metadata = item.get_metadata(0)
		_dlg_selection = metadata if typeof(metadata) == TYPE_DICTIONARY else {}
	_update_controller_selection()
	_refresh_dlg_detail()


func _on_dlg_item_activated() -> void:
	if _dlg_tree == null or _dlg_document == null:
		return
	var item := _dlg_tree.get_selected()
	if item == null:
		return
	var metadata = item.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	if str(metadata.get("kind", "")) != "link":
		return
	_jump_to_link_target(
		str(metadata.get("owner", "entry")),
		int(metadata.get("index", -1)),
		int(metadata.get("link_index", -1))
	)


func _jump_to_link_target(owner_kind: String, owner_index: int, link_index: int) -> void:
	if _dlg_document == null:
		return
	var target := _dlg_document.get_link_target_metadata(owner_kind, owner_index, link_index)
	if target.is_empty():
		_dlg_status_text = "Link target is missing or out of range."
		_refresh_dlg_status()
		return
	_select_dlg_metadata(target)
	_dlg_status_text = ""
	_refresh_dlg_status()


func _on_dlg_item_mouse_selected(item: TreeItem, column: int, at_position: Vector2) -> void:
	# Right-click (button 2) shows context menu for DLG array items
	var button_index = _dlg_tree.get_button_index_at_position(at_position)
	if button_index != 2:
		return
	if item == null or not item.has_meta(GFFTreePopulator.META_IS_DLG_ARRAY_ITEM):
		return
	
	_context_array_field = item.get_meta(GFFTreePopulator.META_ARRAY_FIELD)
	_context_array_index = item.get_meta(GFFTreePopulator.META_ARRAY_INDEX)
	
	_show_array_context_menu(_context_array_field, _context_array_index, at_position)


func _show_array_context_menu(array_field: String, index: int, position: Vector2) -> void:
	if _array_context_menu == null:
		return
	_array_context_menu.clear()
	
	# Add Reply / Remove / Move Up / Move Down options
	_array_context_menu.add_item("Add Item", 0)
	_array_context_menu.add_item("Remove Item", 1)
	_array_context_menu.add_separator()
	
	# Check if we can move up (not first item)
	if index > 0:
		_array_context_menu.add_item("Move Up", 2)
	else:
		_array_context_menu.add_item("Move Up", 2)
		_array_context_menu.set_item_disabled(_array_context_menu.get_item_count() - 1, true)
	
	# Check if we can move down (not last item)
	var array_field_obj = _dlg_document.get_field(array_field)
	var can_move_down = false
	if typeof(array_field_obj) == TYPE_ARRAY:
		var arr := array_field_obj as Array
		can_move_down = index < arr.size() - 1
	
	if can_move_down:
		_array_context_menu.add_item("Move Down", 3)
	else:
		_array_context_menu.add_item("Move Down", 3)
		_array_context_menu.set_item_disabled(_array_context_menu.get_item_count() - 1, true)
	
	_array_context_menu.popup_rect(Rect2(position, Vector2.ZERO))


func _on_array_context_menu_selected(menu_id: int) -> void:
	if _context_array_field.is_empty() or _context_array_index < 0:
		return
	
	match menu_id:
		0:  # Add Item
			var new_struct = {
				"Index": -1,
				"Comment": "",
				"Active": "",
				"IsChild": 0,
			}
			_apply_array_insert(_context_array_field, _context_array_index + 1, new_struct)
		1:  # Remove Item
			_apply_array_remove(_context_array_field, _context_array_index)
		2:  # Move Up
			if _context_array_index > 0:
				_apply_array_reorder(_context_array_field, _context_array_index, _context_array_index - 1)
		3:  # Move Down
			var array_field_obj = _dlg_document.get_field(_context_array_field)
			if typeof(array_field_obj) == TYPE_ARRAY:
				var arr := array_field_obj as Array
				if _context_array_index < arr.size() - 1:
					_apply_array_reorder(_context_array_field, _context_array_index, _context_array_index + 1)
	
	_context_array_field = ""
	_context_array_index = -1


func _refresh_dlg_detail() -> void:
	if _dlg_details == null:
		return
	_clear_container(_dlg_details)
	if _dlg_document == null or _dlg_selection.is_empty():
		return

	match str(_dlg_selection.get("kind", "")):
		"root":
			_add_dlg_section_title("Dialogue Header")
			var summary := Label.new()
			summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary.text = _dlg_document.build_summary_text()
			_dlg_details.add_child(summary)
			var root := _dlg_document.get_root()
			_build_dlg_struct_editor(root, ["Tag", "Quest", "NumWords", "WordCount"])
		"entry", "reply":
			var kind := str(_dlg_selection.get("kind", "entry"))
			var index := int(_dlg_selection.get("index", -1))
			var node := _dlg_document.get_node(kind, index)
			_add_dlg_section_title("%s - %s" % [
				_dlg_document.build_node_title(kind, index),
				_dlg_node_preview(kind, index),
			])
			_build_dlg_struct_editor(node, [
				"Text", "Speaker", "Listener", "Comment", "AnimList",
				"Script", "Delay", "Quest", "PlotIndex", "Sound", "VO_ResRef",
			])
			_add_dlg_link_summary(kind, index)
		"start":
			var start_index := int(_dlg_selection.get("index", -1))
			var start := _dlg_document.get_start(start_index)
			_add_dlg_section_title("Start %d" % start_index)
			var target_label := Label.new()
			target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			target_label.text = "Target: %s" % _dlg_target_label("start", start_index, -1)
			_dlg_details.add_child(target_label)
			_build_dlg_struct_editor(start, ["Index", "Active"])
		"link":
			var owner := str(_dlg_selection.get("owner", "entry"))
			var owner_index := int(_dlg_selection.get("index", -1))
			var link_index := int(_dlg_selection.get("link_index", -1))
			var link := _dlg_document.get_link(owner, owner_index, link_index)
			_add_dlg_section_title(_dlg_target_label(owner, owner_index, link_index))
			var jump_btn := Button.new()
			jump_btn.text = "Jump to Target"
			jump_btn.pressed.connect(func() -> void:
				_jump_to_link_target(owner, owner_index, link_index)
			)
			_dlg_details.add_child(jump_btn)
			_build_dlg_struct_editor(link, ["Index", "Active", "IsChild", "LinkComment", "Comment"])


func _add_dlg_link_summary(kind: String, index: int) -> void:
	var links := _dlg_document.get_node_links(kind, index)
	if links.is_empty():
		return
	var label := Label.new()
	label.text = "Outgoing Links"
	_dlg_details.add_child(label)
	for link_index in range(links.size()):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s - %s" % [
			_dlg_target_label(kind, index, link_index),
			_dlg_document.build_link_preview(kind, index, link_index),
		]
		button.pressed.connect(func() -> void:
			_jump_to_link_target(kind, index, link_index)
		)
		_dlg_details.add_child(button)


func _build_dlg_struct_editor(struct_value: Dictionary, preferred_fields: Array[String]) -> void:
	if struct_value.is_empty():
		return
	var shown := {}
	for field_name in preferred_fields:
		if not struct_value.has(field_name):
			continue
		_add_dlg_field_editor(struct_value, field_name)
		shown[field_name] = true

	var remaining: Array[String] = []
	for key in struct_value.keys():
		var field_name := str(key)
		if shown.has(field_name):
			continue
		if not _dlg_field_is_editable(struct_value.get(field_name, null)):
			continue
		remaining.append(field_name)
	remaining.sort()
	for field_name in remaining:
		_add_dlg_field_editor(struct_value, field_name)


func _add_dlg_field_editor(struct_value: Dictionary, field_name: String) -> void:
	var value = struct_value.get(field_name, null)
	match typeof(value):
		TYPE_DICTIONARY:
			if _dlg_is_locstring(value):
				_add_dlg_locstring_editor(struct_value, field_name, value)
		TYPE_BOOL:
			_add_dlg_bool_editor(struct_value, field_name, bool(value))
		TYPE_INT:
			_add_dlg_number_editor(struct_value, field_name, int(value), true)
		TYPE_FLOAT:
			_add_dlg_number_editor(struct_value, field_name, float(value), false)
		TYPE_STRING:
			_add_dlg_string_editor(struct_value, field_name, String(value))


func _add_dlg_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_details.add_child(label)


func _add_dlg_string_editor(struct_value: Dictionary, field_name: String, value: String) -> void:
	var container := VBoxContainer.new()
	_dlg_details.add_child(container)

	var header := HBoxContainer.new()
	container.add_child(header)

	var label := Label.new()
	label.text = field_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	if TypedFieldHelpers.is_resref_field(field_name):
		var browse_btn := Button.new()
		browse_btn.text = "Browse…"
		browse_btn.pressed.connect(func() -> void:
			_open_resref_picker_for_field(struct_value, field_name, value)
		)
		header.add_child(browse_btn)

	var multiline := field_name in ["Comment", "LinkComment"] or value.contains("\n") or value.length() > 72
	if multiline:
		var edit := TextEdit.new()
		edit.custom_minimum_size = Vector2(0, 84)
		edit.text = value
		edit.focus_exited.connect(func() -> void:
			_apply_string_edit(struct_value, field_name, edit.text)
		)
		container.add_child(edit)
	else:
		var edit := LineEdit.new()
		edit.text = value
		edit.text_submitted.connect(func(new_text: String) -> void:
			_apply_string_edit(struct_value, field_name, new_text)
		)
		edit.focus_exited.connect(func() -> void:
			_apply_string_edit(struct_value, field_name, edit.text)
		)
		container.add_child(edit)


func _add_dlg_locstring_editor(struct_value: Dictionary, field_name: String, value: Dictionary) -> void:
	var container := VBoxContainer.new()
	_dlg_details.add_child(container)

	var label := Label.new()
	label.text = field_name
	container.add_child(label)

	var language_row := HBoxContainer.new()
	container.add_child(language_row)

	var language_label := Label.new()
	language_label.text = "Language ID"
	language_row.add_child(language_label)

	var language_option := OptionButton.new()
	for language_id in TypedFieldHelpers.LOCSTRING_LANGUAGE_IDS:
		language_option.add_item("Language %d" % language_id, language_id)
	language_row.add_child(language_option)

	var strref_row := HBoxContainer.new()
	container.add_child(strref_row)

	var strref_label := Label.new()
	strref_label.text = "StrRef"
	strref_row.add_child(strref_label)

	var strref_spin := SpinBox.new()
	strref_spin.min_value = -1
	strref_spin.max_value = 2147483647
	strref_spin.value = int(value.get("strref", 0xFFFFFFFF))
	strref_row.add_child(strref_spin)

	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 110)
	edit.placeholder_text = _dlg_resolved_locstring_text(value)
	container.add_child(edit)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(info)

	var refresh_locstring_ui := func() -> void:
		var current_locstring = struct_value.get(field_name, value)
		var language_id := language_option.get_selected_id()
		var strings = current_locstring.get("strings", {})
		if typeof(strings) != TYPE_DICTIONARY:
			strings = {}
		edit.text = String(strings.get(language_id, ""))
		var strref := int(current_locstring.get("strref", 0xFFFFFFFF))
		strref_spin.set_value_no_signal(float(strref))
		if strref >= 0 and strref != 0xFFFFFFFF:
			info.text = "StrRef %d -> %s" % [strref, _dlg_resolved_locstring_text(current_locstring)]
		else:
			info.text = "Language %d text edit" % language_id

	refresh_locstring_ui.call()

	language_option.item_selected.connect(func(_index: int) -> void:
		refresh_locstring_ui.call()
	)
	edit.focus_exited.connect(func() -> void:
		_apply_locstring_edit(
			struct_value,
			field_name,
			edit.text,
			language_option.get_selected_id()
		)
	)
	strref_spin.value_changed.connect(func(new_value: float) -> void:
		_apply_locstring_strref_edit(struct_value, field_name, int(new_value))
		refresh_locstring_ui.call()
	)


func _add_dlg_bool_editor(struct_value: Dictionary, field_name: String, value: bool) -> void:
	var check := CheckBox.new()
	check.text = field_name
	check.button_pressed = value
	check.toggled.connect(func(pressed: bool) -> void:
		_apply_bool_edit(struct_value, field_name, pressed)
	)
	_dlg_details.add_child(check)


func _add_dlg_number_editor(struct_value: Dictionary, field_name: String, value: float, integer: bool) -> void:
	var row := HBoxContainer.new()
	_dlg_details.add_child(row)

	var label := Label.new()
	label.text = field_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	if integer and TypedFieldHelpers.has_enum_hints(field_name, _get_enum_registry()):
		var registry := _get_enum_registry()
		var option := OptionButton.new()
		var options := TypedFieldHelpers.get_enum_options_as_array(field_name, registry)
		for option_text in options:
			option.add_item(option_text)
		var selected_index := TypedFieldHelpers.find_enum_option_index(field_name, int(value), registry)
		if selected_index >= 0:
			option.select(selected_index)
		elif not TypedFieldHelpers.validate_enum_value(field_name, int(value), registry):
			push_warning("Field '%s' has out-of-range enum value %d" % [field_name, int(value)])
		option.item_selected.connect(func(index: int) -> void:
			var parsed := TypedFieldHelpers.parse_enum_option_index(option.get_item_text(index))
			if parsed >= 0:
				_apply_int_edit(struct_value, field_name, parsed)
		)
		row.add_child(option)
		return

	var spin := SpinBox.new()
	spin.min_value = -2147483648.0
	spin.max_value = 2147483647.0
	spin.step = 1.0 if integer else 0.1
	spin.value = value
	spin.rounded = integer
	spin.value_changed.connect(func(new_value: float) -> void:
		_apply_int_edit(struct_value, field_name, new_value)
	)
	row.add_child(spin)


func _refresh_dlg_validation() -> void:
	if _validation_panel == null:
		return
	if _dlg_document == null:
		_validation_panel.clear_report()
		return
	var issues := _get_validation_issues()
	if issues.is_empty():
		_validation_panel.set_success("Dialogue validation passed.", [
			"Start list indices resolve.",
			"Link targets resolve.",
			"Referenced scripts found where possible.",
		])
	else:
		_validation_panel.set_issues("Dialogue validation issues:", issues)


func _refresh_dlg_status() -> void:
	if _path_label == null:
		return
	if _dlg_document == null:
		_path_label.text = _dlg_status_text
		_emit_status_text(_dlg_status_text)
		return
	_path_label.text = "%s%s  [%d starts / %d entries / %d replies]" % [
		_current_dlg_file_name(),
		" *" if _dlg_dirty else "",
		_dlg_document.get_start_count(),
		_dlg_document.get_entry_count(),
		_dlg_document.get_reply_count(),
	]
	if not _dlg_status_text.is_empty():
		_path_label.text += " - %s" % _dlg_status_text
	_emit_status_text(_path_label.text)


func _on_dlg_document_changed() -> void:
	if _dlg_document == null:
		return
	_dlg_dirty = true
	_dlg_status_text = "Edited"
	_emit_dirty_state(_dlg_dirty)
	_update_controller_dirty_state()
	_refresh_dlg_selected_item_text()
	_refresh_dlg_detail()
	_refresh_dlg_validation()
	_refresh_dlg_status()


func _refresh_dlg_selected_item_text() -> void:
	if _dlg_tree == null or _dlg_document == null:
		return
	var item := _dlg_tree.get_selected()
	if item == null:
		return
	match str(_dlg_selection.get("kind", "")):
		"root":
			item.set_text(1, _dlg_document.get_display_name())
		"start":
			item.set_text(1, _dlg_target_label("start", int(_dlg_selection.get("index", -1)), -1))
		"entry", "reply":
			var kind := str(_dlg_selection.get("kind", "entry"))
			var index := int(_dlg_selection.get("index", -1))
			item.set_text(1, _dlg_node_preview(kind, index))
		"link":
			var owner := str(_dlg_selection.get("owner", "entry"))
			var owner_index := int(_dlg_selection.get("index", -1))
			var link_index := int(_dlg_selection.get("link_index", -1))
			item.set_text(0, _dlg_target_label(owner, owner_index, link_index))
			item.set_text(1, _dlg_document.build_link_preview(owner, owner_index, link_index))


func _dlg_field_is_editable(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_DICTIONARY:
			return _dlg_is_locstring(value)
		_:
			return false


func _dlg_is_locstring(value: Variant) -> bool:
	return typeof(value) == TYPE_DICTIONARY and value.has("strref") and value.has("strings")


func _dlg_locstring_text(locstring: Dictionary) -> String:
	var strings = locstring.get("strings", {})
	if typeof(strings) != TYPE_DICTIONARY:
		return ""
	if strings.has(0):
		return String(strings.get(0, ""))
	for key in strings.keys():
		var text := String(strings.get(key, ""))
		if not text.is_empty():
			return text
	return ""


func _dlg_resolved_locstring_text(locstring: Dictionary) -> String:
	var local_text := _dlg_locstring_text(locstring).strip_edges()
	if not local_text.is_empty():
		return local_text
	var gamefs := _resolve_gamefs()
	var strref := int(locstring.get("strref", 0xFFFFFFFF))
	if strref >= 0 and strref != 0xFFFFFFFF and gamefs != null and gamefs.has_method("get_dialog_string"):
		var tlk_text := String(gamefs.call("get_dialog_string", strref)).strip_edges()
		if not tlk_text.is_empty():
			return tlk_text
	return KotorDLGDocument.describe_locstring(locstring, "")


func _dlg_node_preview(kind: String, index: int) -> String:
	var node := _dlg_document.get_node(kind, index)
	if node.is_empty():
		return ""
	var text := _dlg_resolved_locstring_text(node.get("Text", {}))
	if text.is_empty():
		text = String(node.get("Comment", node.get("Speaker", ""))).strip_edges()
	return text.substr(0, 96) + ("..." if text.length() > 96 else "")


func _dlg_target_label(kind: String, index: int, link_index: int) -> String:
	if _dlg_document == null:
		return ""
	if kind == "start":
		var start := _dlg_document.get_start(index)
		var target_index := int(start.get("Index", -1))
		return "-> Entry %d - %s" % [target_index, _dlg_node_preview("entry", target_index)]
	var target_kind := _dlg_document.get_link_target_kind(kind)
	var link := _dlg_document.get_link(kind, index, link_index)
	var target_index := _dlg_document.get_link_target_index(link)
	return "-> %s %d - %s" % [
		"Reply" if target_kind == "reply" else "Entry",
		target_index,
		_dlg_node_preview(target_kind, target_index),
	]


func _select_first_dlg_item(root_item: TreeItem) -> void:
	if _dlg_tree == null or root_item == null:
		return
	var item := root_item.get_first_child()
	if item != null:
		item.select(0)
		_dlg_selection = item.get_metadata(0)


func _select_dlg_metadata(metadata: Dictionary) -> void:
	if _dlg_tree == null:
		return
	var root_item := _dlg_tree.get_root()
	if root_item == null:
		return
	var item := _find_tree_item_by_metadata(root_item, metadata)
	if item != null:
		item.select(0)
		_dlg_selection = metadata
		_refresh_dlg_detail()


func _find_tree_item_by_metadata(item: TreeItem, metadata: Dictionary) -> TreeItem:
	var current := item
	while current != null:
		var current_metadata = current.get_metadata(0)
		if typeof(current_metadata) == TYPE_DICTIONARY and _metadata_matches(current_metadata, metadata):
			return current
		var child := current.get_first_child()
		if child != null:
			var match := _find_tree_item_by_metadata(child, metadata)
			if match != null:
				return match
		current = current.get_next()
	return null


func _metadata_matches(left: Dictionary, right: Dictionary) -> bool:
	if str(left.get("kind", "")) != str(right.get("kind", "")):
		return false
	for key in ["owner", "index", "link_index"]:
		if left.get(key, null) != right.get(key, null):
			return false
	return true


func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


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


func _format_pipeline_result(result: Dictionary) -> String:
	if result.is_empty():
		return "No result."
	var text := String(result.get("message", ""))
	if result.get("status", "") == "written":
		var target_path := str(result.get("target_path", ""))
		if not target_path.is_empty():
			text += " -> %s" % target_path
		var backup_path := str(result.get("backup_path", ""))
		if not backup_path.is_empty():
			text += " (backup: %s)" % backup_path.get_file()
	return text


func _mutation_message(result: Dictionary) -> String:
	if result.has("result") and typeof(result.get("result", {})) == TYPE_DICTIONARY:
		return String((result.get("result", {}) as Dictionary).get("message", result.get("message", "")))
	return String(result.get("message", _format_pipeline_result(result)))


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
	if _editor_state != null and _editor_state.has_method("resolve_dialog_start_dir"):
		var initial_dir = _editor_state.call("resolve_dialog_start_dir", start_dir)
		if typeof(initial_dir) == TYPE_STRING and not String(initial_dir).is_empty():
			dialog.current_dir = String(initial_dir)
	if not current_file.is_empty():
		dialog.current_file = current_file
	return dialog


func _get_validation_issues() -> Array[String]:
	if _dlg_document == null:
		var empty: Array[String] = []
		return empty
	return _dlg_document.validate(_resolve_gamefs())


func _resolve_gamefs() -> RefCounted:
	var editor_state := get_editor_state()
	if editor_state == null:
		return null
	var gamefs = editor_state.get("gamefs")
	return gamefs as RefCounted


func _resolve_mutation_service() -> RefCounted:
	var controller := get_controller()
	if controller != null:
		var service = controller.get("mutation_service")
		if service != null:
			return service
	return KotorMutationService.new()


func _current_dlg_file_name() -> String:
	return _ensure_extension(_dlg_file_name, "dlg")


func _connect_document_signal() -> void:
	if _dlg_document == null:
		return
	var changed := Callable(self, "_on_dlg_document_changed")
	if not _dlg_document.changed.is_connected(changed):
		_dlg_document.changed.connect(changed)


func _disconnect_document_signal() -> void:
	if _dlg_document == null:
		return
	var changed := Callable(self, "_on_dlg_document_changed")
	if _dlg_document.changed.is_connected(changed):
		_dlg_document.changed.disconnect(changed)


func _clear_document_state(message: String) -> void:
	_disconnect_document_signal()
	_dlg_resource = null
	_dlg_document = null
	_dlg_source_path = ""
	_dlg_file_name = "dialogue.dlg"
	_dlg_dirty = false
	_dlg_selection = {}
	_dlg_status_text = message
	_document_key = ""
	if _dlg_tree != null:
		_dlg_tree.clear()
	if _dlg_details != null:
		_clear_container(_dlg_details)
	_refresh_dlg_validation()
	_refresh_dlg_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"dlg",
		_dlg_resource,
		_dlg_document,
		_dlg_source_path,
		_current_dlg_file_name(),
		_dlg_selection
	)
	_document_key = str(entry.get("key", ""))


func _update_controller_dirty_state() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_dirty"):
		return
	controller.call("update_document_dirty", _document_key, _dlg_dirty)


func _update_controller_selection() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_selection"):
		return
	controller.call("update_document_selection", _document_key, _dlg_selection)


func _remove_previous_controller_document(previous_key: String) -> void:
	var controller := get_controller()
	if controller == null or previous_key.is_empty() or previous_key == _document_key or not controller.has_method("remove_document"):
		return
	controller.call("remove_document", previous_key)


func _get_undo_redo() -> EditorUndoRedoManager:
	if not Engine.is_editor_hint():
		return null
	return EditorInterface.get_editor_undo_redo()


func _apply_string_edit(struct_value: Dictionary, field_name: String, new_text: String) -> void:
	if _dlg_document == null or struct_value.is_empty():
		return
	var current: Variant = struct_value.get(field_name, "")
	var validated_text := new_text
	
	if TypedFieldHelpers.is_resref_field(field_name):
		validated_text = _dlg_document.validate_resref(new_text)
	
	# Check for required field validation (blocking)
	if TypedFieldHelpers.is_required_field(field_name):
		# For Index field, we need to know the target list size
		# This is a simplified check; full validation happens at save time
		var entry_list_size := _dlg_document.get_struct_list("EntryList").size()
		if not TypedFieldHelpers.validate_required_field(field_name, validated_text, entry_list_size):
			push_error("Required field '%s' has invalid value '%s'. Must be 0-%d." % [field_name, validated_text, entry_list_size - 1])
			return
	
	# Check for optional field warnings
	var warning := TypedFieldHelpers.get_validation_warning(field_name, validated_text)
	if not warning.is_empty():
		push_warning("Field '%s': %s" % [field_name, warning])
	
	if String(current) == validated_text:
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Edit DLG string field", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_string_edit", struct_value, field_name, validated_text)
		ur.add_undo_method(self, "_exec_string_edit", struct_value, field_name, current)
		ur.commit_action()
	else:
		_exec_string_edit(struct_value, field_name, validated_text)


func _exec_string_edit(struct_value: Dictionary, field_name: String, value: String) -> void:
	if _dlg_document == null:
		return
	_dlg_document.set_struct_field(struct_value, field_name, value)


func _apply_locstring_edit(
	struct_value: Dictionary,
	field_name: String,
	new_text: String,
	language_id: int = 0
) -> void:
	if _dlg_document == null or struct_value.is_empty():
		return
	var current_locstring = struct_value.get(field_name, {})
	var strings = current_locstring.get("strings", {})
	if typeof(strings) != TYPE_DICTIONARY:
		strings = {}
	var current_text := String(strings.get(language_id, ""))
	if current_text == new_text:
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Edit DLG locstring field", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_locstring_edit", struct_value, field_name, new_text, language_id)
		ur.add_undo_method(self, "_exec_locstring_edit", struct_value, field_name, current_text, language_id)
		ur.commit_action()
	else:
		_exec_locstring_edit(struct_value, field_name, new_text, language_id)


func _exec_locstring_edit(
	struct_value: Dictionary,
	field_name: String,
	value: String,
	language_id: int = 0
) -> void:
	if _dlg_document == null:
		return
	_dlg_document.set_struct_locstring_text(struct_value, field_name, value, language_id)


func _apply_locstring_strref_edit(struct_value: Dictionary, field_name: String, new_strref: int) -> void:
	if _dlg_document == null or struct_value.is_empty():
		return
	var current_locstring = struct_value.get(field_name, {})
	var current_strref := int(current_locstring.get("strref", 0xFFFFFFFF))
	if current_strref == new_strref:
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Edit DLG locstring strref", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_locstring_strref_edit", struct_value, field_name, new_strref)
		ur.add_undo_method(self, "_exec_locstring_strref_edit", struct_value, field_name, current_strref)
		ur.commit_action()
	else:
		_exec_locstring_strref_edit(struct_value, field_name, new_strref)


func _exec_locstring_strref_edit(struct_value: Dictionary, field_name: String, strref: int) -> void:
	if _dlg_document == null:
		return
	var locstring = struct_value.get(field_name, {})
	if typeof(locstring) != TYPE_DICTIONARY:
		return
	locstring["strref"] = strref
	_dlg_document.set_struct_field(struct_value, field_name, locstring)


func _open_resref_picker_for_field(struct_value: Dictionary, field_name: String, current_value: String) -> void:
	var dialog := KotorResRefPickerDialog.new()
	dialog.configure(
		_editor_state,
		TypedFieldHelpers.get_resref_type_hint(field_name),
		current_value
	)
	add_child(dialog)
	dialog.resref_selected.connect(func(selected: String) -> void:
		if not selected.is_empty():
			_apply_string_edit(struct_value, field_name, selected)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)
	dialog.popup_centered_ratio(0.7)


func _apply_bool_edit(struct_value: Dictionary, field_name: String, pressed: bool) -> void:
	if _dlg_document == null or struct_value.is_empty():
		return
	var current: Variant = struct_value.get(field_name, false)
	if typeof(current) == TYPE_BOOL and bool(current) == pressed:
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Edit DLG bool field", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_bool_edit", struct_value, field_name, pressed)
		ur.add_undo_method(self, "_exec_bool_edit", struct_value, field_name, current)
		ur.commit_action()
	else:
		_exec_bool_edit(struct_value, field_name, pressed)


func _exec_bool_edit(struct_value: Dictionary, field_name: String, value: Variant) -> void:
	if _dlg_document == null:
		return
	_dlg_document.set_struct_field(struct_value, field_name, value)


func _get_enum_registry() -> RefCounted:
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.get("enum_registry") != null:
		return editor_state.enum_registry
	return null


func _apply_int_edit(struct_value: Dictionary, field_name: String, new_value: float) -> void:
	if _dlg_document == null or struct_value.is_empty():
		return
	var normalized := int(new_value)
	
	if TypedFieldHelpers.has_enum_hints(field_name, _get_enum_registry()):
		if not TypedFieldHelpers.validate_enum_value(field_name, normalized, _get_enum_registry()):
			push_warning("Field '%s' has out-of-range enum value %d" % [field_name, normalized])
	
	# Check for required field validation (blocking)
	if TypedFieldHelpers.is_required_field(field_name):
		var entry_list_size := _dlg_document.get_struct_list("EntryList").size()
		if not TypedFieldHelpers.validate_required_field(field_name, normalized, entry_list_size):
			push_error("Required field '%s' must be 0-%d, got %d" % [field_name, entry_list_size - 1, normalized])
			return
	
	var current: Variant = struct_value.get(field_name, 0)
	if typeof(current) == TYPE_INT and int(current) == normalized:
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Edit DLG int field", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_int_edit", struct_value, field_name, normalized)
		ur.add_undo_method(self, "_exec_int_edit", struct_value, field_name, current)
		ur.commit_action()
	else:
		_exec_int_edit(struct_value, field_name, normalized)


func _exec_int_edit(struct_value: Dictionary, field_name: String, value: Variant) -> void:
	if _dlg_document == null:
		return
	_dlg_document.set_struct_field(struct_value, field_name, value)


func _apply_array_insert(array_field_name: String, index: int, new_struct: Dictionary) -> void:
	if _dlg_document == null or array_field_name.is_empty():
		return
	if new_struct.is_empty():
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Insert DLG array item", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_array_insert", array_field_name, index, new_struct)
		ur.add_undo_method(self, "_exec_array_remove", array_field_name, index)
		ur.commit_action()
	else:
		_exec_array_insert(array_field_name, index, new_struct)


func _exec_array_insert(array_field_name: String, index: int, new_struct: Dictionary) -> void:
	if _dlg_document == null:
		return
	_dlg_document.insert_struct_at_array(array_field_name, index, new_struct)


func _apply_array_remove(array_field_name: String, index: int) -> void:
	if _dlg_document == null or array_field_name.is_empty():
		return
	var array_field = _dlg_document.get_field(array_field_name)
	if typeof(array_field) != TYPE_ARRAY:
		return
	var arr := array_field as Array
	if index < 0 or index >= arr.size():
		return
	var removed_struct = arr[index]
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Remove DLG array item", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_array_remove", array_field_name, index)
		ur.add_undo_method(self, "_exec_array_insert", array_field_name, index, removed_struct)
		ur.commit_action()
	else:
		_exec_array_remove(array_field_name, index)


func _exec_array_remove(array_field_name: String, index: int) -> void:
	if _dlg_document == null:
		return
	_dlg_document.remove_struct_from_array(array_field_name, index)


func _apply_array_reorder(array_field_name: String, from_index: int, to_index: int) -> void:
	if _dlg_document == null or array_field_name.is_empty():
		return
	if from_index == to_index:
		return
	var array_field = _dlg_document.get_field(array_field_name)
	if typeof(array_field) != TYPE_ARRAY:
		return
	var arr := array_field as Array
	if from_index < 0 or from_index >= arr.size() or to_index < 0 or to_index >= arr.size():
		return
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Reorder DLG array item", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_array_reorder", array_field_name, from_index, to_index)
		ur.add_undo_method(self, "_exec_array_reorder", array_field_name, to_index, from_index)
		ur.commit_action()
	else:
		_exec_array_reorder(array_field_name, from_index, to_index)


func _exec_array_reorder(array_field_name: String, from_index: int, to_index: int) -> void:
	if _dlg_document == null:
		return
	_dlg_document.reorder_array_item(array_field_name, from_index, to_index)
