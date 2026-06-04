## SSF (Sound Set File) writer — 28 StrRef slots in KotOR V1.1 layout.
class_name SSFWriter

const SSFParser := preload("ssf_parser.gd")
const SSFResource := preload("../resources/ssf_resource.gd")

const PADDING_SLOTS := 12


static func serialize(resource: Resource) -> PackedByteArray:
	if not resource is SSFResource:
		return PackedByteArray()
	return serialize_strrefs((resource as SSFResource).strrefs)


static func serialize_strrefs(strrefs: Array) -> PackedByteArray:
	var values: Array[int] = []
	values.resize(SSFParser.SLOT_COUNT)
	for index in SSFParser.SLOT_COUNT:
		if index < strrefs.size():
			values[index] = int(strrefs[index])
		else:
			values[index] = -1

	var buffer := PackedByteArray()
	buffer.resize(SSFParser.HEADER_SIZE + SSFParser.SLOT_COUNT * 4 + PADDING_SLOTS * 4)
	buffer.fill(0)

	_write_ascii(buffer, 0, SSFParser.FILE_TYPE)
	_write_ascii(buffer, 4, SSFParser.FILE_VERSION)
	_write_u32(buffer, 8, SSFParser.HEADER_SIZE)

	for index in SSFParser.SLOT_COUNT:
		_write_i32(buffer, SSFParser.HEADER_SIZE + index * 4, values[index])

	var padding_offset := SSFParser.HEADER_SIZE + SSFParser.SLOT_COUNT * 4
	for index in PADDING_SLOTS:
		_write_u32(buffer, padding_offset + index * 4, 0xFFFFFFFF)

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


static func _write_ascii(buffer: PackedByteArray, offset: int, text: String) -> void:
	for index in text.length():
		buffer[offset + index] = text.unicode_at(index)


static func _write_u32(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF
	buffer[offset + 2] = (value >> 16) & 0xFF
	buffer[offset + 3] = (value >> 24) & 0xFF


static func _write_i32(buffer: PackedByteArray, offset: int, value: int) -> void:
	if value < 0:
		_write_u32(buffer, offset, 0xFFFFFFFF)
	else:
		_write_u32(buffer, offset, value)
