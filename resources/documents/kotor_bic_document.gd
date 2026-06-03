@tool
extends "./kotor_utc_document.gd"
class_name KotorBICDocument


func get_first_name_text() -> String:
	return get_locstring_text("FirstName")


func get_last_name_text() -> String:
	return get_locstring_text("LastName")


func get_player_name() -> String:
	return join_non_empty([
		get_first_name_text(),
		get_last_name_text(),
	])


func get_display_name() -> String:
	var name := get_player_name()
	if not name.is_empty():
		return name
	var template := get_template_resref()
	if not template.is_empty():
		return template
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_player_name())
	_append_summary_line(lines, "First Name", get_first_name_text())
	_append_summary_line(lines, "Last Name", get_last_name_text())
	_append_summary_line(lines, "Template", get_template_resref())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Conversation", get_conversation_resref())
	return lines
