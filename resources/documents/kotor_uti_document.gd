@tool
extends "../kotor_gff_document.gd"
class_name KotorUTIDocument


func get_template_resref() -> String:
	return get_resref("TemplateResRef")


func get_tag() -> String:
	return get_string("Tag")


func get_name_text() -> String:
	return get_locstring_text("LocalizedName")


func get_base_item_id() -> int:
	return get_int("BaseItem")


func get_stack_size() -> int:
	return get_int("StackSize")


func get_display_name() -> String:
	var name := get_name_text()
	if not name.is_empty():
		return name
	var template := get_template_resref()
	if not template.is_empty():
		return template
	return get_tag() if not get_tag().is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_name_text())
	_append_summary_line(lines, "Template", get_template_resref())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Base Item", get_base_item_id())
	_append_summary_line(lines, "Stack Size", get_stack_size())
	return lines
