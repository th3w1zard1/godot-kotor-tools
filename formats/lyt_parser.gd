## KotOR/Jade Empire LYT area layout parser.
##
## Parses the ASCII layout description used by module archives to declare room models,
## track objects, obstacles, and door hooks.
class_name LYTParser

const COUNT_KEYS := {
	"roomcount": "room_count",
	"trackcount": "track_count",
	"obstaclecount": "obstacle_count",
	"doorhookcount": "doorhook_count",
}


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.is_empty():
		return {}
	var text := data.get_string_from_utf8()
	if text.is_empty():
		text = data.get_string_from_ascii()
	if text.is_empty():
		return {}

	var result := {
		"file_dependencies": [],
		"rooms": [],
		"tracks": [],
		"obstacles": [],
		"doorhooks": [],
		"declared_counts": {
			"room_count": 0,
			"track_count": 0,
			"obstacle_count": 0,
			"doorhook_count": 0,
		},
		"unparsed_lines": [],
	}

	var lines := text.replace("\r", "").split("\n", false)
	for raw_line in lines:
		var line := String(raw_line).strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with(";") or line.begins_with("//"):
			continue
		var tokens := _tokenize(line)
		if tokens.is_empty():
			continue

		var keyword := String(tokens[0]).to_lower()
		if keyword == "beginlayout" or keyword == "donelayout" or keyword == "endlayout":
			continue
		if keyword == "filedependancy" or keyword == "filedependency":
			if tokens.size() > 1:
				(result["file_dependencies"] as Array).append(_join_tokens(tokens, 1))
			continue
		if COUNT_KEYS.has(keyword):
			var count_key := String(COUNT_KEYS[keyword])
			var count_value := int(tokens[1]) if tokens.size() > 1 and String(tokens[1]).is_valid_int() else 0
			(result["declared_counts"] as Dictionary)[count_key] = count_value
			continue

		match keyword:
			"roommodel":
				(result["rooms"] as Array).append(_parse_model_entry(tokens))
			"trackobj", "trackobject":
				(result["tracks"] as Array).append(_parse_model_entry(tokens))
			"obstacleobj", "obstacleobject", "obstaclemodel":
				(result["obstacles"] as Array).append(_parse_model_entry(tokens))
			"doorhook":
				(result["doorhooks"] as Array).append(_parse_doorhook(tokens))
			_:
				(result["unparsed_lines"] as Array).append(line)

	return result


static func parse_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LYTParser: cannot open '%s'" % path)
		return {}
	var data := file.get_buffer(file.get_length())
	file.close()
	return parse_bytes(data)


static func _parse_model_entry(tokens: Array[String]) -> Dictionary:
	var entry := {
		"model": tokens[1] if tokens.size() > 1 else "",
		"position": Vector3.ZERO,
		"raw_tokens": tokens.duplicate(),
	}
	if tokens.size() > 4:
		entry["position"] = Vector3(
			_to_float(tokens[2]),
			_to_float(tokens[3]),
			_to_float(tokens[4])
		)
	return entry


static func _parse_doorhook(tokens: Array[String]) -> Dictionary:
	var entry := {
		"name": tokens[1] if tokens.size() > 1 else "",
		"door": tokens[2] if tokens.size() > 2 else "",
		"room": tokens[3] if tokens.size() > 3 else "",
		"position": Vector3.ZERO,
		"raw_tokens": tokens.duplicate(),
	}
	if tokens.size() > 6:
		entry["position"] = Vector3(
			_to_float(tokens[tokens.size() - 3]),
			_to_float(tokens[tokens.size() - 2]),
			_to_float(tokens[tokens.size() - 1])
		)
	return entry


static func _tokenize(line: String) -> Array[String]:
	var pieces := line.replace("\t", " ").split(" ", false)
	var tokens: Array[String] = []
	for piece in pieces:
		var token := String(piece).strip_edges()
		if not token.is_empty():
			tokens.append(token)
	return tokens


static func _join_tokens(tokens: Array[String], start_index: int) -> String:
	var parts: Array[String] = []
	for index in range(start_index, tokens.size()):
		parts.append(tokens[index])
	return " ".join(parts)


static func _to_float(value: Variant) -> float:
	return float(str(value))
