## LIP (Lip Sync) writer — KotOR V1.0 binary layout.
class_name LIPWriter

const LIPParser := preload("lip_parser.gd")
const LIPResource := preload("../resources/lip_resource.gd")


static func serialize(resource: Resource) -> PackedByteArray:
	if not resource is LIPResource:
		return PackedByteArray()
	return serialize_keyframes((resource as LIPResource).length, (resource as LIPResource).keyframes)


static func serialize_keyframes(length: float, keyframes: Array) -> PackedByteArray:
	var sorted: Array = []
	for entry in keyframes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var time := maxf(0.0, float(entry.get("time", 0.0)))
		var shape := clampi(int(entry.get("shape", 0)), 0, LIPParser.SHAPE_COUNT - 1)
		sorted.append({"time": time, "shape": shape})
	LIPParser.sort_keyframes_array(sorted)

	var buffer := PackedByteArray()
	buffer.resize(LIPParser.HEADER_SIZE + sorted.size() * 5)
	buffer.fill(0)

	_write_ascii(buffer, 0, LIPParser.FILE_TYPE)
	_write_ascii(buffer, 4, LIPParser.FILE_VERSION)
	_write_f32(buffer, 8, maxf(0.0, length))
	_write_u32(buffer, 12, sorted.size())

	for index in sorted.size():
		var entry: Dictionary = sorted[index]
		var offset := LIPParser.HEADER_SIZE + index * 5
		_write_f32(buffer, offset, float(entry.get("time", 0.0)))
		buffer[offset + 4] = int(entry.get("shape", 0)) & 0xFF

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


static func _write_f32(buffer: PackedByteArray, offset: int, value: float) -> void:
	var encoded := PackedByteArray()
	encoded.resize(4)
	encoded.encode_float(0, value)
	for index in 4:
		buffer[offset + index] = encoded[index]
