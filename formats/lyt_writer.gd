## KotOR/Jade Empire LYT area layout writer (ASCII round-trip with LYTParser).
class_name LYTWriter

static func write_text(parsed: Dictionary) -> String:
	var lines: Array[String] = ["beginlayout"]

	for dependency in parsed.get("file_dependencies", []):
		lines.append("filedependancy %s" % str(dependency))

	var rooms: Array = parsed.get("rooms", [])
	var tracks: Array = parsed.get("tracks", [])
	var obstacles: Array = parsed.get("obstacles", [])
	var doorhooks: Array = parsed.get("doorhooks", [])

	if not rooms.is_empty():
		lines.append("roomcount %d" % rooms.size())
	for entry in rooms:
		lines.append(_format_model_line("roommodel", entry))

	if not tracks.is_empty():
		lines.append("trackcount %d" % tracks.size())
	for entry in tracks:
		lines.append(_format_model_line("trackobj", entry))

	if not obstacles.is_empty():
		lines.append("obstaclecount %d" % obstacles.size())
	for entry in obstacles:
		lines.append(_format_model_line("obstaclemodel", entry))

	if not doorhooks.is_empty():
		lines.append("doorhookcount %d" % doorhooks.size())
	for entry in doorhooks:
		lines.append(_format_doorhook_line(entry))

	for raw_line in parsed.get("unparsed_lines", []):
		lines.append(str(raw_line))

	lines.append("donelayout")
	return "\n".join(lines)


static func write_bytes(parsed: Dictionary) -> PackedByteArray:
	return write_text(parsed).to_utf8_buffer()


static func _format_model_line(keyword: String, entry: Variant) -> String:
	if typeof(entry) != TYPE_DICTIONARY:
		return "%s" % keyword
	var model_entry: Dictionary = entry
	var model := str(model_entry.get("model", "")).strip_edges()
	var position: Vector3 = model_entry.get("position", Vector3.ZERO)
	return "%s %s %.6f %.6f %.6f" % [keyword, model, position.x, position.y, position.z]


static func _format_doorhook_line(entry: Variant) -> String:
	if typeof(entry) != TYPE_DICTIONARY:
		return "doorhook"
	var hook: Dictionary = entry
	var name := str(hook.get("name", "")).strip_edges()
	var door := str(hook.get("door", "")).strip_edges()
	var room := str(hook.get("room", "")).strip_edges()
	var position: Vector3 = hook.get("position", Vector3.ZERO)
	return "doorhook %s %s %s %.6f %.6f %.6f" % [
		name,
		door,
		room,
		position.x,
		position.y,
		position.z,
	]
