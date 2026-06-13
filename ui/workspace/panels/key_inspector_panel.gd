@tool
extends AcceptDialog
class_name KotorKeyInspectorPanel

const KotorGameFS := preload("../../../gamefs/kotor_gamefs.gd")

var _gamefs: RefCounted
var _lookup_field: LineEdit
var _type_field: SpinBox
var _lookup_result: Label
var _tree: Tree


func _init(gamefs: RefCounted = null) -> void:
	_gamefs = gamefs
	title = "KEY Inspector (read-only)"
	dialog_hide_on_ok = true
	min_size = Vector2(720, 420)
	_build_ui()


func setup(gamefs: RefCounted) -> void:
	_gamefs = gamefs
	_refresh_view()


func _ready() -> void:
	if _tree == null:
		_build_ui()
	_refresh_view()


func _build_ui() -> void:
	if _tree != null:
		return
	var root := VBoxContainer.new()
	add_child(root)

	var lookup_row := HBoxContainer.new()
	root.add_child(lookup_row)
	var resref_label := Label.new()
	resref_label.text = "ResRef"
	lookup_row.add_child(resref_label)
	_lookup_field = LineEdit.new()
	_lookup_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lookup_field.placeholder_text = "test2da"
	lookup_row.add_child(_lookup_field)
	var type_label := Label.new()
	type_label.text = "Type"
	lookup_row.add_child(type_label)
	_type_field = SpinBox.new()
	_type_field.min_value = 0
	_type_field.max_value = 0xFFFF
	_type_field.value = 0x0018
	lookup_row.add_child(_type_field)
	var lookup_btn := Button.new()
	lookup_btn.text = "Lookup"
	lookup_btn.pressed.connect(_run_lookup)
	lookup_row.add_child(lookup_btn)

	_lookup_result = Label.new()
	_lookup_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_lookup_result)

	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 4
	_tree.column_titles_visible = true
	_tree.set_column_title(0, "BIF Index")
	_tree.set_column_title(1, "Filename")
	_tree.set_column_title(2, "Declared Size")
	_tree.set_column_title(3, "Key Entries")
	root.add_child(_tree)


func _refresh_view() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _gamefs == null or not (_gamefs is KotorGameFS):
		_lookup_result.text = "GameFS index unavailable."
		return
	if not _gamefs.has_chitin_key():
		_lookup_result.text = "chitin.key is not indexed for this install."
		return
	var catalog: Array[Dictionary] = _gamefs.list_chitin_bif_catalog()
	var root_item := _tree.create_item()
	for bif_entry in catalog:
		var item := _tree.create_item(root_item)
		item.set_text(0, str(bif_entry.get("bif_index", "")))
		item.set_text(1, str(bif_entry.get("filename", "")))
		item.set_text(2, str(bif_entry.get("file_size", 0)))
		item.set_text(3, str(bif_entry.get("key_entry_count", 0)))
	_lookup_result.text = "%d BIF archives indexed from %s" % [
		catalog.size(),
		_gamefs.chitin_key_path.get_file(),
	]


func _run_lookup() -> void:
	if _gamefs == null or not (_gamefs is KotorGameFS):
		_lookup_result.text = "GameFS index unavailable."
		return
	var resref := _lookup_field.text.strip_edges()
	var resource_type := int(_type_field.value)
	var entry := _gamefs.lookup_chitin_key_entry(resref, resource_type)
	if entry.is_empty():
		_lookup_result.text = "No KEY entry for %s (type 0x%04X)." % [resref, resource_type]
		return
	_lookup_result.text = "Found %s.%s in BIF %s (%s)" % [
		entry.get("resref", ""),
		entry.get("extension", ""),
		entry.get("bif_index", -1),
		entry.get("location", ""),
	]
