## KotOR ASCII `.vis` room visibility writer (round-trip with VISParser).
class_name VISWriter


static func write_text(parsed: Dictionary) -> String:
	var rooms: Variant = parsed.get("rooms", {})
	if typeof(rooms) != TYPE_DICTIONARY:
		return ""
	return write_visibility_map(rooms)


static func write_bytes(parsed: Dictionary) -> PackedByteArray:
	return write_text(parsed).to_utf8_buffer()


static func write_visibility_map(visibility: Dictionary) -> String:
	var parent_names: Array[String] = []
	for parent_name in visibility.keys():
		parent_names.append(str(parent_name))
	parent_names.sort()

	var lines: Array[String] = []
	for parent_name in parent_names:
		var children: Array = visibility.get(parent_name, [])
		var child_names: Array[String] = []
		for raw_child in children:
			child_names.append(str(raw_child))
		child_names.sort()
		lines.append("%s %d" % [parent_name, child_names.size()])
		for child_name in child_names:
			lines.append("  %s" % child_name)
	return "\n".join(lines).strip_edges()
