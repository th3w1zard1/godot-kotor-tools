@tool
extends VBoxContainer
class_name KotorResourceBrowserPanel

signal resource_requested(entry: Dictionary)
signal install_requested(entry: Dictionary)
signal compare_requested(entry: Dictionary)
signal export_requested(entry: Dictionary)
signal references_requested(entry: Dictionary)

const KotorResourceLocator := preload("../../../editor/navigation/kotor_resource_locator.gd")
const KotorResRefReferenceScanner := preload("../../../editor/tools/kotor_resref_reference_scanner.gd")
const MdlGamefsBatchExporter := preload("../../../formats/mdl_gamefs_batch_exporter.gd")
const MdlGamefsBatchImporter := preload("../../../formats/mdl_gamefs_batch_importer.gd")
const BwmGamefsBatchExporter := preload("../../../formats/bwm_gamefs_batch_exporter.gd")
const BwmGamefsBatchImporter := preload("../../../formats/bwm_gamefs_batch_importer.gd")

var _target_context: RefCounted
var _status_label: Label
var _search_field: LineEdit
var _source_filter: OptionButton
var _bif_catalog_toggle: CheckButton
var _tree: Tree
var _detail: TextEdit
var _selected_bif_index := -1


func _init(target_context: RefCounted = null) -> void:
	_target_context = target_context
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(target_context: RefCounted) -> void:
	_target_context = target_context
	if is_node_ready():
		_connect_target_context()
		_refresh_view()


func _ready() -> void:
	_build_ui()
	_connect_target_context()
	_refresh_view()


func _build_ui() -> void:
	if _status_label != null:
		return
	var toolbar := HBoxContainer.new()
	add_child(toolbar)

	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.clip_text = true
	toolbar.add_child(_status_label)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(_refresh_view)
	toolbar.add_child(refresh_btn)

	var actions_row := HBoxContainer.new()
	add_child(actions_row)

	var open_btn := Button.new()
	open_btn.text = "Open"
	open_btn.pressed.connect(func() -> void:
		var entry := _selected_resource_entry()
		if not entry.is_empty():
			resource_requested.emit(entry)
	)
	actions_row.add_child(open_btn)

	var install_btn := Button.new()
	install_btn.text = "Install → Override"
	install_btn.pressed.connect(func() -> void:
		var entry := _selected_resource_entry()
		if not entry.is_empty():
			install_requested.emit(entry)
	)
	actions_row.add_child(install_btn)

	var compare_btn := Button.new()
	compare_btn.text = "Compare"
	compare_btn.pressed.connect(func() -> void:
		var entry := _selected_resource_entry()
		if not entry.is_empty():
			compare_requested.emit(entry)
	)
	actions_row.add_child(compare_btn)

	var export_btn := Button.new()
	export_btn.text = "Export…"
	export_btn.pressed.connect(func() -> void:
		var entry := _selected_resource_entry()
		if not entry.is_empty():
			export_requested.emit(entry)
	)
	actions_row.add_child(export_btn)

	var references_btn := Button.new()
	references_btn.text = "Find References"
	references_btn.pressed.connect(_find_references_for_selected)
	actions_row.add_child(references_btn)

	var batch_mdl_btn := Button.new()
	batch_mdl_btn.text = "Batch Export Install MDL..."
	batch_mdl_btn.pressed.connect(_batch_export_install_mdl)
	actions_row.add_child(batch_mdl_btn)

	var batch_wok_btn := Button.new()
	batch_wok_btn.text = "Batch Export Install WOK..."
	batch_wok_btn.pressed.connect(_batch_export_install_wok)
	actions_row.add_child(batch_wok_btn)

	var batch_copy_wok_btn := Button.new()
	batch_copy_wok_btn.text = "Batch Copy Install WOK to Override..."
	batch_copy_wok_btn.pressed.connect(_batch_copy_install_wok_to_override)
	actions_row.add_child(batch_copy_wok_btn)

	var batch_copy_mdl_btn := Button.new()
	batch_copy_mdl_btn.text = "Batch Copy Install MDL to Override..."
	batch_copy_mdl_btn.pressed.connect(_batch_copy_install_mdl_to_override)
	actions_row.add_child(batch_copy_mdl_btn)

	var search_row := HBoxContainer.new()
	add_child(search_row)

	var source_label := Label.new()
	source_label.text = "Source:"
	search_row.add_child(source_label)

	_source_filter = OptionButton.new()
	_source_filter.add_item("All sources", 0)
	_source_filter.set_item_metadata(0, "")
	_source_filter.add_item("override", 1)
	_source_filter.set_item_metadata(1, "override")
	_source_filter.add_item("chitin.key", 2)
	_source_filter.set_item_metadata(2, "chitin.key")
	_source_filter.add_item("modules", 3)
	_source_filter.set_item_metadata(3, "modules")
	_source_filter.item_selected.connect(_on_source_filter_changed)
	search_row.add_child(_source_filter)

	_bif_catalog_toggle = CheckButton.new()
	_bif_catalog_toggle.text = "BIF catalog"
	_bif_catalog_toggle.disabled = true
	_bif_catalog_toggle.toggled.connect(_on_bif_catalog_toggled)
	search_row.add_child(_bif_catalog_toggle)

	var search_label := Label.new()
	search_label.text = "Find:"
	search_row.add_child(search_label)

	_search_field = LineEdit.new()
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.placeholder_text = "Search by resref, type, source, or path..."
	_search_field.text_submitted.connect(_on_search)
	search_row.add_child(_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(func() -> void:
		_on_search(_search_field.text)
	)
	search_row.add_child(search_btn)

	_tree = Tree.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 4
	_tree.set_column_title(0, "ResRef")
	_tree.set_column_title(1, "Type")
	_tree.set_column_title(2, "Source")
	_tree.set_column_title(3, "Location")
	_tree.column_titles_visible = true
	_tree.item_selected.connect(_refresh_selection)
	_tree.item_activated.connect(_open_selected_entry)
	add_child(_tree)

	_detail = TextEdit.new()
	_detail.custom_minimum_size = Vector2(0, 96)
	_detail.editable = false
	_detail.placeholder_text = "Select a resource to inspect its explicit variants."
	add_child(_detail)


func _connect_target_context() -> void:
	if _target_context == null or not _target_context.has_signal("state_changed"):
		return
	var callback := Callable(self, "_refresh_view")
	if not _target_context.state_changed.is_connected(callback):
		_target_context.state_changed.connect(callback)


func _on_search(query: String) -> void:
	if _search_field != null:
		_search_field.text = query
	_refresh_view()


func _on_source_filter_changed(_index: int) -> void:
	_selected_bif_index = -1
	if _bif_catalog_toggle != null:
		var source := _get_selected_source_filter()
		_bif_catalog_toggle.disabled = source != "chitin.key"
		if _bif_catalog_toggle.disabled:
			_bif_catalog_toggle.button_pressed = false
	_refresh_view()


func _on_bif_catalog_toggled(_pressed: bool) -> void:
	_selected_bif_index = -1
	_refresh_view()


func _get_selected_source_filter() -> String:
	if _source_filter == null:
		return ""
	var index := _source_filter.selected
	if index < 0:
		return ""
	var metadata = _source_filter.get_item_metadata(index)
	return str(metadata) if metadata != null else ""


func _refresh_view() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _target_context == null:
		return

	var catalog_mode := _bif_catalog_toggle != null and _bif_catalog_toggle.button_pressed
	if catalog_mode and _target_context.has_method("list_chitin_bif_catalog"):
		_refresh_bif_catalog_view()
		return

	var query := _search_field.text if _search_field != null else ""
	var source := _get_selected_source_filter()
	var entries: Array[Dictionary] = []
	if _target_context.has_method("list_resources_filtered"):
		entries = _target_context.call("list_resources_filtered", query, "", source, 256)
	else:
		entries = _target_context.call("list_resources", query)

	_tree.set_column_title(0, "ResRef")
	_tree.set_column_title(1, "Type")
	_tree.set_column_title(2, "Source")
	_tree.set_column_title(3, "Location")

	var root_item := _tree.create_item()
	for entry in entries:
		if _selected_bif_index >= 0 and int(entry.get("bif_index", -1)) != _selected_bif_index:
			continue
		var item := _tree.create_item(root_item)
		item.set_text(0, str(entry.get("resref", "")))
		item.set_text(1, str(entry.get("extension", "")).to_upper())
		item.set_text(2, str(entry.get("source", "")))
		item.set_text(3, str(entry.get("location", "")))
		item.set_metadata(0, entry)
	_status_label.text = _target_context.call("get_status_text")
	_refresh_selection()


func _refresh_bif_catalog_view() -> void:
	_tree.set_column_title(0, "BIF File")
	_tree.set_column_title(1, "Entries")
	_tree.set_column_title(2, "Size")
	_tree.set_column_title(3, "Location")

	var catalog: Array[Dictionary] = _target_context.call("list_chitin_bif_catalog")
	var root_item := _tree.create_item()
	for bif_entry in catalog:
		var item := _tree.create_item(root_item)
		item.set_text(0, str(bif_entry.get("filename", "")))
		item.set_text(1, str(bif_entry.get("key_entry_count", 0)))
		item.set_text(2, str(bif_entry.get("file_size", 0)))
		item.set_text(3, str(bif_entry.get("location", "")))
		var metadata := bif_entry.duplicate(true)
		metadata["catalog_entry"] = true
		item.set_metadata(0, metadata)
	_status_label.text = "%s | %d BIF archives" % [
		_target_context.call("get_status_text"),
		catalog.size(),
	]
	_refresh_selection()


func _refresh_selection() -> void:
	if _detail == null or _tree == null:
		return
	var entry := get_selected_entry()
	if entry.is_empty() or _target_context == null:
		_detail.text = ""
		return
	if bool(entry.get("catalog_entry", false)):
		_detail.text = "BIF archive\nFilename: %s\nKey entries: %s\nDeclared size: %s\nPath: %s\n\nUncheck BIF catalog to browse resources in this BIF." % [
			entry.get("filename", ""),
			entry.get("key_entry_count", 0),
			entry.get("file_size", 0),
			entry.get("location", ""),
		]
		_selected_bif_index = int(entry.get("bif_index", -1))
		return

	var variants: Array[Dictionary] = _target_context.call("list_variants", entry)
	var details := KotorResourceLocator.build_entry_details(entry, variants)
	if _target_context.has_method("get_gamefs"):
		details = KotorResourceLocator.append_mdl_metadata_details(
			details,
			entry,
			_target_context.get_gamefs()
		)
	_detail.text = details


func get_selected_entry() -> Dictionary:
	if _tree == null:
		return {}
	var item := _tree.get_selected()
	if item == null:
		return {}
	var metadata = item.get_metadata(0)
	return metadata if typeof(metadata) == TYPE_DICTIONARY else {}


func _selected_resource_entry() -> Dictionary:
	var entry := get_selected_entry()
	if bool(entry.get("catalog_entry", false)):
		return {}
	return entry


func _open_selected_entry() -> void:
	var entry := _selected_resource_entry()
	if entry.is_empty():
		return
	resource_requested.emit(entry)


func _set_detail_text(text: String) -> void:
	if _detail != null:
		_detail.text = text


func _find_references_for_selected() -> void:
	var entry := _selected_resource_entry()
	if entry.is_empty():
		_set_detail_text("Select a resource to find references.")
		return
	references_requested.emit(entry)
	if _target_context == null or not _target_context.has_method("get_gamefs"):
		_set_detail_text("Target context is unavailable for reference scan.")
		return
	var gamefs: RefCounted = _target_context.get_gamefs()
	var target_resref := str(entry.get("resref", ""))
	var result := KotorResRefReferenceScanner.scan_install_references(gamefs, target_resref)
	_set_detail_text(KotorResRefReferenceScanner.format_report(result))


func _batch_export_install_mdl() -> void:
	if _target_context == null or not _target_context.has_method("get_gamefs"):
		_set_detail_text("Target context is unavailable for batch MDL export.")
		return
	var gamefs: RefCounted = _target_context.get_gamefs()
	if gamefs == null:
		_set_detail_text("Configure a valid game install before batch MDL export.")
		return

	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Batch Export MDL from install index"
	if _target_context.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = _target_context.call("resolve_dialog_start_dir", "")
	dialog.dir_selected.connect(func(dir_path: String) -> void:
		_run_batch_install_mdl_export(gamefs, dir_path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _run_batch_install_mdl_export(gamefs: RefCounted, output_dir: String) -> void:
	var result := MdlGamefsBatchExporter.batch_install(gamefs, output_dir, {
		"source_filter": "override",
	})
	_set_detail_text(MdlGamefsBatchExporter.format_report(result))


func _batch_export_install_wok() -> void:
	if _target_context == null or not _target_context.has_method("get_gamefs"):
		_set_detail_text("Target context is unavailable for batch WOK export.")
		return
	var gamefs: RefCounted = _target_context.get_gamefs()
	if gamefs == null:
		_set_detail_text("Configure a valid game install before batch WOK export.")
		return

	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Batch Export WOK from install index"
	if _target_context.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = _target_context.call("resolve_dialog_start_dir", "")
	dialog.dir_selected.connect(func(dir_path: String) -> void:
		_run_batch_install_wok_export(gamefs, dir_path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _run_batch_install_wok_export(gamefs: RefCounted, output_dir: String) -> void:
	var result := BwmGamefsBatchExporter.batch_install(gamefs, output_dir, {
		"source_filter": "override",
	})
	_set_detail_text(BwmGamefsBatchExporter.format_report(result))


func _batch_copy_install_wok_to_override() -> void:
	if _target_context == null or not _target_context.has_method("get_gamefs"):
		_set_detail_text("Target context is unavailable for batch WOK copy.")
		return
	var gamefs: RefCounted = _target_context.get_gamefs()
	if gamefs == null:
		_set_detail_text("Configure a valid game install before batch WOK copy.")
		return
	_run_batch_copy_install_wok_to_override(gamefs)


func _run_batch_copy_install_wok_to_override(gamefs: RefCounted) -> void:
	var result := BwmGamefsBatchImporter.batch_install_to_override(gamefs, {})
	_set_detail_text(BwmGamefsBatchImporter.format_report(result))
	if not (result.get("generated", []) as Array).is_empty():
		_refresh_after_batch_copy()


func _batch_copy_install_mdl_to_override() -> void:
	if _target_context == null or not _target_context.has_method("get_gamefs"):
		_set_detail_text("Target context is unavailable for batch MDL copy.")
		return
	var gamefs: RefCounted = _target_context.get_gamefs()
	if gamefs == null:
		_set_detail_text("Configure a valid game install before batch MDL copy.")
		return
	_run_batch_copy_install_mdl_to_override(gamefs)


func _run_batch_copy_install_mdl_to_override(gamefs: RefCounted) -> void:
	var result := MdlGamefsBatchImporter.batch_install_to_override(gamefs, {})
	_set_detail_text(MdlGamefsBatchImporter.format_report(result))
	if not (result.get("generated", []) as Array).is_empty():
		_refresh_after_batch_copy()


func _refresh_after_batch_copy() -> void:
	if _target_context != null and _target_context.has_method("refresh_gamefs"):
		_target_context.call("refresh_gamefs")
	_refresh_view()
