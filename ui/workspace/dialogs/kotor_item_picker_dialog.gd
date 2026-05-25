@tool
extends "./kotor_resref_picker_dialog.gd"
class_name KotorItemPickerDialog

signal item_selected(resref: String)


func configure(
	editor_state: RefCounted,
	_resource_type_filter: String = "uti",
	initial_query: String = ""
) -> KotorResRefPickerDialog:
	super.configure(editor_state, "uti", initial_query)
	title = "Browse Item Template"
	if not resref_selected.is_connected(_forward_item_selected):
		resref_selected.connect(_forward_item_selected)
	return self


func _forward_item_selected(selected: String) -> void:
	item_selected.emit(selected)
