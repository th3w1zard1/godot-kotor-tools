@tool
extends VBoxContainer
class_name KotorResourceBrowserPanel

signal resource_requested(entry: Dictionary)
signal install_requested(entry: Dictionary)
signal compare_requested(entry: Dictionary)
signal export_requested(entry: Dictionary)

const KotorResourceLocator := preload("../../../editor/navigation/kotor_resource_locator.gd")

var _target_context: RefCounted
var _status_label: Label
var _search_field: LineEdit
var _tree: Tree
var _detail: TextEdit


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
		var entry := get_selected_entry()
		if not entry.is_empty():
			resource_requested.emit(entry)
	)
	actions_row.add_child(open_btn)

	var install_btn := Button.new()
	install_btn.text = "Install → Override"
	install_btn.pressed.connect(func() -> void:
		var entry := get_selected_entry()
		if not entry.is_empty():
			install_requested.emit(entry)
	)
	actions_row.add_child(install_btn)

	var compare_btn := Button.new()
	compare_btn.text = "Compare"
	compare_btn.pressed.connect(func() -> void:
		var entry := get_selected_entry()
		if not entry.is_empty():
			compare_requested.emit(entry)
	)
	actions_row.add_child(compare_btn)

	var export_btn := Button.new()
	export_btn.text = "Export…"
	export_btn.pressed.connect(func() -> void:
		var entry := get_selected_entry()
		if not entry.is_empty():
			export_requested.emit(entry)
	)
	actions_row.add_child(export_btn)

	var search_row := HBoxContainer.new()
	add_child(search_row)

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


func _refresh_view() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _target_context == null:
		return
	var query := _search_field.text if _search_field != null else ""
	var entries: Array[Dictionary] = _target_context.call("list_resources", query)
	var root_item := _tree.create_item()
	for entry in entries:
		var item := _tree.create_item(root_item)
		item.set_text(0, str(entry.get("resref", "")))
		item.set_text(1, str(entry.get("extension", "")).to_upper())
		item.set_text(2, str(entry.get("source", "")))
		item.set_text(3, str(entry.get("location", "")))
		item.set_metadata(0, entry)
	_status_label.text = _target_context.call("get_status_text")
	_refresh_selection()


func _refresh_selection() -> void:
	if _detail == null or _tree == null:
		return
	var entry := get_selected_entry()
	if entry.is_empty() or _target_context == null:
		_detail.text = ""
		return
	var variants: Array[Dictionary] = _target_context.call("list_variants", entry)
	_detail.text = KotorResourceLocator.build_entry_details(entry, variants)


func get_selected_entry() -> Dictionary:
	if _tree == null:
		return {}
	var item := _tree.get_selected()
	if item == null:
		return {}
	var metadata = item.get_metadata(0)
	return metadata if typeof(metadata) == TYPE_DICTIONARY else {}


func _open_selected_entry() -> void:
	var entry := get_selected_entry()
	if entry.is_empty():
		return
	resource_requested.emit(entry)


func _set_detail_text(text: String) -> void:
	if _detail != null:
		_detail.text = text
