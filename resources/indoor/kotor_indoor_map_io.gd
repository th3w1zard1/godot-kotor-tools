## PyKotor/Holocron-compatible `.indoor` JSON read/write (headless).
class_name KotorIndoorMapIO

const EMBEDDED_KIT_ID := "__embedded__"


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.is_empty():
		return {}
	var text := data.get_string_from_utf8()
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


static func write_bytes(data: Dictionary) -> PackedByteArray:
	return JSON.stringify(data, "\t").to_utf8_buffer()


static func default_map_data(module_id: String = "test01") -> Dictionary:
	return {
		"module_id": module_id,
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"warp": module_id,
		"rooms": [],
	}
