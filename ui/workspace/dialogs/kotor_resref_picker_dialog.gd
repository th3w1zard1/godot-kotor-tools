@tool
extends AcceptDialog
class_name KotorResRefPickerDialog

signal resref_selected(resref: String)

const TypedFieldHelpers := preload("../typed_field_helpers.gd")

var _editor_state: RefCounted
var _resource_type_filter := ""
var _search_field: LineEdit
var _tree: Tree
var _status_label: Label
var _selected_resref := ""


func configure(editor_state: RefCounted, resource_type_filter: String = "", initial_query: String = "") -> KotorResRefPickerDialog:
	_editor_state = editor_state
	_resource_type_filter = resource_type_filter.strip_edges().to_lower()
	title = "Browse ResRef"
	ok_button_text = "Select"
	_ensure_ui()
	if _search_field != null:
		_search_field.text = initial_query
	return self


func _ready() -> void:
	_ensure_ui()


func _ensure_ui() -> void:
	if _tree != null:
		return
	min_size = Vector2(640, 420)
	var root := VBoxContainer.new()
	add_child(root)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)

	var search_row := HBoxContainer.new()
	root.add_child(search_row)

	var search_label := Label.new()
	search_label.text = "Find:"
	search_row.add_child(search_label)

	_search_field = LineEdit.new()
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.placeholder_text = "Search by resref, type, source, or path..."
	_search_field.text_submitted.connect(_refresh_entries)
	search_row.add_child(_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(_refresh_entries)
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
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	root.add_child(_tree)

	confirmed.connect(_on_confirmed)
	_refresh_entries()


func _refresh_entries(_query: String = "") -> void:
	_ensure_ui()
	if _tree == null:
		return
	_tree.clear()
	var gamefs := _resolve_gamefs()
	if gamefs == null:
		_status_label.text = "No indexed game install. Configure a game path first."
		_selected_resref = ""
		return

	var query := _search_field.text if _search_field != null else ""
	var type_filter: Variant = _resource_type_filter if not _resource_type_filter.is_empty() else null
	var entries: Array = gamefs.call("list_core_resources", query, type_filter, "", 256)
	var root_item := _tree.create_item()
	for entry_variant in entries:
		var entry: Dictionary = entry_variant if typeof(entry_variant) == TYPE_DICTIONARY else {}
		if entry.is_empty():
			continue
		var item := _tree.create_item(root_item)
		item.set_text(0, str(entry.get("resref", "")))
		item.set_text(1, str(entry.get("extension", "")).to_upper())
		item.set_text(2, str(entry.get("source", "")))
		item.set_text(3, str(entry.get("location", "")))
		item.set_metadata(0, entry)

	if gamefs.has_method("get_status_text"):
		_status_label.text = String(gamefs.call("get_status_text"))
	else:
		_status_label.text = "%d matching resources" % entries.size()
	_on_item_selected()


func _on_item_selected() -> void:
	if _tree == null:
		_selected_resref = ""
		return
	var item := _tree.get_selected()
	if item == null:
		_selected_resref = ""
		return
	var metadata = item.get_metadata(0)
	var entry: Dictionary = metadata if typeof(metadata) == TYPE_DICTIONARY else {}
	_selected_resref = TypedFieldHelpers.normalize_picker_selection(entry)


func _on_item_activated() -> void:
	_on_item_selected()
	if not _selected_resref.is_empty():
		emit_signal("resref_selected", _selected_resref)
		hide()


func _on_confirmed() -> void:
	if _selected_resref.is_empty():
		return
	emit_signal("resref_selected", _selected_resref)


func get_selected_resref() -> String:
	return _selected_resref


func _resolve_gamefs() -> RefCounted:
	if _editor_state == null:
		return null
	var gamefs = _editor_state.get("gamefs")
	return gamefs as RefCounted
