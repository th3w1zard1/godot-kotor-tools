## LIP (Lip Sync) parser — KotOR V1.0 keyframe stream.
class_name LIPParser

const HEADER_SIZE := 16
const FILE_TYPE := "LIP "
const FILE_VERSION := "V1.0"
const SHAPE_COUNT := 16

const SHAPE_NAMES: PackedStringArray = [
	"NEUTRAL",
	"EE",
	"EH",
	"AH",
	"OH",
	"OOH",
	"Y",
	"STS",
	"FV",
	"NG",
	"TH",
	"MPB",
	"TD",
	"SH",
	"L",
	"KG",
]


static func shape_name(shape_index: int) -> String:
	if shape_index < 0 or shape_index >= SHAPE_NAMES.size():
		return "SHAPE_%d" % shape_index
	return SHAPE_NAMES[shape_index]


static func parse_shape_token(text: String) -> int:
	var trimmed := text.strip_edges().to_upper()
	if trimmed.is_empty():
		return -1
	if trimmed.is_valid_int():
		var value := int(trimmed)
		if value >= 0 and value < SHAPE_COUNT:
			return value
		return -1
	for index in SHAPE_COUNT:
		if SHAPE_NAMES[index] == trimmed:
			return index
	return -1


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.size() < HEADER_SIZE:
		return {}

	var file_type := data.slice(0, 4).get_string_from_ascii()
	var file_version := data.slice(4, 8).get_string_from_ascii()
	if file_type != FILE_TYPE or file_version != FILE_VERSION:
		return {}

	var length := _read_f32(data, 8)
	var entry_count := _read_u32(data, 12)
	var required_size := HEADER_SIZE + entry_count * 5
	if required_size > data.size():
		return {}

	var keyframes: Array = []
	for index in entry_count:
		var offset := HEADER_SIZE + index * 5
		var time := _read_f32(data, offset)
		var shape := data[offset + 4]
		if shape >= SHAPE_COUNT:
			shape = 0
		keyframes.append({"time": time, "shape": int(shape)})

	sort_keyframes_array(keyframes)

	return {
		"length": length,
		"keyframes": keyframes,
	}


static func sort_keyframes_array(keyframes: Array) -> void:
	keyframes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
	)


static func _read_u32(data: PackedByteArray, offset: int) -> int:
	return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24)


static func _read_f32(data: PackedByteArray, offset: int) -> float:
	if offset + 4 > data.size():
		return 0.0
	return data.decode_float(offset)
