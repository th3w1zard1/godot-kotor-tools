@tool
extends "../kotor_gff_document.gd"
class_name KotorJRLDocument


func get_name_text() -> String:
	return get_locstring_text("Name")


func get_tag() -> String:
	return get_string("Tag")


func get_entry_count() -> int:
	var entries: Variant = get_field("EntriesList", [])
	if typeof(entries) == TYPE_ARRAY:
		return (entries as Array).size()
	return 0


func get_entry_ids() -> Array[int]:
	var ids: Array[int] = []
	for entry in get_struct_list("EntriesList"):
		ids.append(int(entry.get("ID", 0)))
	return ids


func get_display_name() -> String:
	var name := get_name_text()
	if not name.is_empty():
		return name
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_name_text())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Quest Entries", get_entry_count())
	return lines
