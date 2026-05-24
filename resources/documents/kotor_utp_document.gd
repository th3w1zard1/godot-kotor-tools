@tool
extends "../kotor_gff_document.gd"
class_name KotorUTPDocument


func get_template_resref() -> String:
	return get_resref("TemplateResRef")


func get_tag() -> String:
	return get_string("Tag")


func get_name_text() -> String:
	return get_locstring_text("LocName")


func get_conversation_resref() -> String:
	return get_resref("Conversation")


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
	_append_summary_line(lines, "Conversation", get_conversation_resref())
	_append_summary_line(lines, "Has Inventory", get_bool("HasInventory"))
	_append_summary_line(lines, "Useable", get_bool("Useable"))
	return lines
