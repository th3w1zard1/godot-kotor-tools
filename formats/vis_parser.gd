## KotOR ASCII `.vis` room visibility parser.
class_name VISParser


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.is_empty():
		return {}
	return parse_text(data.get_string_from_utf8())


static func parse_text(text: String) -> Dictionary:
	var rooms: Dictionary = {}
	var current_parent := ""
	var expected_children := 0
	var collected_children: Array[String] = []

	for raw_line in text.replace("\r", "").split("\n", false):
		if raw_line.strip_edges().is_empty():
			continue
		if raw_line.begins_with(" ") or raw_line.begins_with("\t"):
			if current_parent.is_empty():
				continue
			collected_children.append(raw_line.strip_edges())
			if collected_children.size() >= expected_children:
				rooms[current_parent] = collected_children.duplicate()
				current_parent = ""
				expected_children = 0
				collected_children.clear()
			continue

		var line := raw_line.strip_edges()
		var tokens := line.split(" ", false)
		if tokens.size() < 2:
			continue
		if not current_parent.is_empty() and collected_children.size() < expected_children:
			rooms[current_parent] = collected_children.duplicate()
		current_parent = str(tokens[0]).strip_edges()
		expected_children = int(tokens[1]) if str(tokens[1]).is_valid_int() else 0
		collected_children.clear()

	if not current_parent.is_empty():
		rooms[current_parent] = collected_children.duplicate()

	return {"rooms": rooms}


static func room_count(parsed: Dictionary) -> int:
	var rooms: Variant = parsed.get("rooms", {})
	return rooms.size() if typeof(rooms) == TYPE_DICTIONARY else 0
