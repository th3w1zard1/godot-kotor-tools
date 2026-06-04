## Generate KotOR `.lyt` ASCII from `.indoor` room placements (native build slice).
class_name KotorIndoorLyTBuilder

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const LYTParser := preload("../../formats/lyt_parser.gd")


static func build_from_document(document: KotorIndoorDocument) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}

	var room_entries: Array[Dictionary] = []
	for index in document.get_room_count():
		var room := document.get_room_dictionary(index)
		var component_id := str(room.get("component", "")).strip_edges()
		if component_id.is_empty():
			continue
		var position := _read_position(room)
		room_entries.append({
			"model": component_id,
			"position": position,
		})

	if room_entries.is_empty():
		return {"ok": false, "errors": ["Indoor map has no rooms to place in LYT."]}

	var text := build_text(room_entries)
	var bytes := text.to_utf8_buffer()
	return {
		"ok": true,
		"text": text,
		"bytes": bytes,
		"room_count": room_entries.size(),
	}


static func build_text(room_entries: Array) -> String:
	var lines: Array[String] = ["beginlayout", "roomcount %d" % room_entries.size()]
	for raw_entry in room_entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var model := str(entry.get("model", "")).strip_edges()
		var position: Vector3 = entry.get("position", Vector3.ZERO)
		lines.append(
			"roommodel %s %.6f %.6f %.6f" % [model, position.x, position.y, position.z]
		)
	lines.append("donelayout")
	return "\n".join(lines)


static func parse_built_text(text: String) -> Dictionary:
	return LYTParser.parse_bytes(text.to_utf8_buffer())


static func _read_position(room: Dictionary) -> Vector3:
	var raw: Variant = room.get("position", [0.0, 0.0, 0.0])
	if typeof(raw) != TYPE_ARRAY:
		return Vector3.ZERO
	var values: Array = raw
	return Vector3(
		float(values[0]) if values.size() > 0 else 0.0,
		float(values[1]) if values.size() > 1 else 0.0,
		float(values[2]) if values.size() > 2 else 0.0
	)
