@tool
extends "../kotor_gff_document.gd"
class_name KotorUTDDocument


func get_template_resref() -> String:
	return get_resref("TemplateResRef")


func get_tag() -> String:
	return get_string("Tag")


func get_name_text() -> String:
	return get_locstring_text("LocName")


func get_conversation_resref() -> String:
	return get_resref("Conversation")


func is_static() -> bool:
	return get_bool("Static")


func is_plot() -> bool:
	return get_bool("Plot")


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
	_append_summary_line(lines, "Static", is_static())
	_append_summary_line(lines, "Plot", is_plot())
	append_trap_scalar_summary_lines(lines)
	append_script_hook_summary_lines(lines)
	return lines
