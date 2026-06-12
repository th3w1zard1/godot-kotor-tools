## LTR (Letter) writer — KotOR V1.0 binary layout.
class_name LTRWriter

const LTRParser := preload("ltr_parser.gd")
const LTRResource := preload("../resources/ltr_resource.gd")


static func serialize(resource: Resource) -> PackedByteArray:
	if not resource is LTRResource:
		return PackedByteArray()
	return serialize_parsed((resource as LTRResource).to_parser_result())


static func serialize_parsed(parsed: Dictionary) -> PackedByteArray:
	if parsed.is_empty():
		return PackedByteArray()
	var letter_count := int(parsed.get("letter_count", 0))
	if letter_count != 26 and letter_count != LTRParser.KOTOR_LETTER_COUNT:
		return PackedByteArray()

	var singles: Dictionary = parsed.get("singles", {})
	var doubles: Array = parsed.get("doubles", [])
	var triples: Array = parsed.get("triples", [])
	if doubles.size() != letter_count or triples.size() != letter_count:
		return PackedByteArray()

	var size := LTRParser.expected_file_size(letter_count)
	var buffer := PackedByteArray()
	buffer.resize(size)
	buffer.fill(0)

	_write_ascii(buffer, 0, LTRParser.FILE_TYPE)
	_write_ascii(buffer, 4, LTRParser.FILE_VERSION)
	buffer[8] = letter_count & 0xFF

	var offset := LTRParser.HEADER_SIZE
	offset = _write_block(buffer, offset, singles, letter_count)
	for block_index in letter_count:
		var block: Dictionary = doubles[block_index] if block_index < doubles.size() else {}
		offset = _write_block(buffer, offset, block, letter_count)
	for row_index in letter_count:
		var row: Array = triples[row_index] if row_index < triples.size() else []
		for column_index in letter_count:
			var block: Dictionary = row[column_index] if column_index < row.size() else {}
			offset = _write_block(buffer, offset, block, letter_count)

	return buffer


static func save_resource(resource: Resource, path: String) -> Error:
	var bytes := serialize(resource)
	if bytes.is_empty():
		return ERR_INVALID_PARAMETER
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	var err := file.get_error()
	file.close()
	return err if err != OK and err != ERR_FILE_EOF else OK


static func _write_block(buffer: PackedByteArray, offset: int, block: Dictionary, letter_count: int) -> int:
	offset = _write_float_array(buffer, offset, block.get("start", []), letter_count)
	offset = _write_float_array(buffer, offset, block.get("middle", []), letter_count)
	return _write_float_array(buffer, offset, block.get("end", []), letter_count)


static func _write_float_array(buffer: PackedByteArray, offset: int, values: Variant, count: int) -> int:
	for index in count:
		var value := 0.0
		if typeof(values) == TYPE_ARRAY and index < (values as Array).size():
			value = float((values as Array)[index])
		buffer.encode_float(offset + index * 4, value)
	return offset + count * 4


static func _write_ascii(buffer: PackedByteArray, offset: int, text: String) -> void:
	for index in text.length():
		buffer[offset + index] = text.unicode_at(index)
