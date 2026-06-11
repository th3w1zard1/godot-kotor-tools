## LTR (Letter) parser — KotOR V1.0 name-generation probability tables.
class_name LTRParser

const FILE_TYPE := "LTR "
const FILE_VERSION := "V1.0"
const HEADER_SIZE := 9
const KOTOR_LETTER_COUNT := 28
const KOTOR_ALPHABET := "abcdefghijklmnopqrstuvwxyz'-"


static func alphabet_for_count(letter_count: int) -> String:
	if letter_count == KOTOR_LETTER_COUNT:
		return KOTOR_ALPHABET
	if letter_count == 26:
		return "abcdefghijklmnopqrstuvwxyz"
	return ""


static func letter_label(letter_count: int, index: int) -> String:
	var alphabet := alphabet_for_count(letter_count)
	if index < 0 or index >= alphabet.length():
		return "?"
	return alphabet[index]


static func expected_file_size(letter_count: int) -> int:
	if letter_count <= 0:
		return 0
	var block_bytes := letter_count * 3 * 4
	return HEADER_SIZE + block_bytes + (letter_count * block_bytes) + (letter_count * letter_count * block_bytes)


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.size() < HEADER_SIZE:
		return {}
	if data.slice(0, 4).get_string_from_ascii() != FILE_TYPE:
		return {}
	if data.slice(4, 8).get_string_from_ascii() != FILE_VERSION:
		return {}

	var letter_count := int(data[8])
	if letter_count != 26 and letter_count != KOTOR_LETTER_COUNT:
		return {}
	var expected_size := expected_file_size(letter_count)
	if data.size() < expected_size:
		return {}

	var offset := HEADER_SIZE
	var singles := _read_block(data, offset, letter_count)
	offset += letter_count * 3 * 4

	var doubles: Array = []
	for _index in letter_count:
		doubles.append(_read_block(data, offset, letter_count))
		offset += letter_count * 3 * 4

	var triples: Array = []
	for _row in letter_count:
		var row_blocks: Array = []
		for _column in letter_count:
			row_blocks.append(_read_block(data, offset, letter_count))
			offset += letter_count * 3 * 4
		triples.append(row_blocks)

	return {
		"letter_count": letter_count,
		"alphabet": alphabet_for_count(letter_count),
		"singles": singles,
		"doubles": doubles,
		"triples": triples,
	}


static func parse_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LTRParser: cannot open '%s'" % path)
		return {}
	var data := file.get_buffer(file.get_length())
	file.close()
	return parse_bytes(data)


static func _read_block(data: PackedByteArray, offset: int, letter_count: int) -> Dictionary:
	return {
		"start": _read_float_array(data, offset, letter_count),
		"middle": _read_float_array(data, offset + letter_count * 4, letter_count),
		"end": _read_float_array(data, offset + letter_count * 8, letter_count),
	}


static func _read_float_array(data: PackedByteArray, offset: int, count: int) -> Array:
	var values: Array = []
	values.resize(count)
	for index in count:
		values[index] = _read_f32(data, offset + index * 4)
	return values


static func _read_f32(data: PackedByteArray, offset: int) -> float:
	if offset + 4 > data.size():
		return 0.0
	return data.decode_float(offset)
