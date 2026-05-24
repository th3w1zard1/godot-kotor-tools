## TLK V3.0 serializer for writing TLKResource data back to disk.
@tool
extends RefCounted
class_name TLKWriter

const TLKResource := preload("../resources/tlk_resource.gd")
const FILE_TYPE := "TLK "
const DEFAULT_VERSION := "V3.0"
const ELEMENT_SIZE := 40
const FLAG_TEXT_PRESENT := 0x1


static func save_resource(resource: Resource, path: String) -> Error:
	if resource == null:
		return ERR_INVALID_PARAMETER

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_buffer(serialize(resource))
	var err := file.get_error()
	file.close()
	if err == OK or err == ERR_FILE_EOF:
		return OK
	return err


static func serialize(resource: Resource) -> PackedByteArray:
	if not resource is TLKResource:
		return PackedByteArray()

	var data: Dictionary = (resource as TLKResource).to_writer_data()
	var entries: Array = data.get("entries", [])
	var version := String(data.get("version", DEFAULT_VERSION))
	if version.is_empty():
		version = DEFAULT_VERSION

	var output := PackedByteArray()
	output.append_array(_fixed_text_bytes(FILE_TYPE, 4))
	output.append_array(_fixed_text_bytes(version, 4))
	_append_u32(output, int(data.get("language_id", 0)))
	_append_u32(output, entries.size())
	_append_u32(output, 0x14 + entries.size() * ELEMENT_SIZE)

	var entry_bytes := PackedByteArray()
	var string_data := PackedByteArray()

	for index in entries.size():
		var entry: Dictionary = entries[index]
		var text_bytes := _encode_text(String(entry.get("text", "")))
		var flags := int(entry.get("flags", 0))
		if text_bytes.is_empty():
			flags &= ~FLAG_TEXT_PRESENT
		else:
			flags |= FLAG_TEXT_PRESENT

		_append_u32(entry_bytes, flags)
		entry_bytes.append_array(_fixed_text_bytes(String(entry.get("sound_resref", "")), 16))
		_append_u32(entry_bytes, int(entry.get("volume_variance", 0)))
		_append_u32(entry_bytes, int(entry.get("pitch_variance", 0)))
		_append_u32(entry_bytes, string_data.size())
		_append_u32(entry_bytes, text_bytes.size())
		_append_f32(entry_bytes, float(entry.get("sound_length", 0.0)))
		string_data.append_array(text_bytes)

	output.append_array(entry_bytes)
	output.append_array(string_data)
	return output


static func _encode_text(text: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	for index in text.length():
		var codepoint := text.unicode_at(index)
		bytes.append(codepoint if codepoint <= 0xFF else 0x3F)
	return bytes


static func _fixed_text_bytes(text: String, length: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	var encoded := _encode_text(text)
	for index in range(mini(length, encoded.size())):
		bytes.append(encoded[index])
	while bytes.size() < length:
		bytes.append(0)
	return bytes


static func _append_u32(buffer: PackedByteArray, value: int) -> void:
	buffer.append(value & 0xFF)
	buffer.append((value >> 8) & 0xFF)
	buffer.append((value >> 16) & 0xFF)
	buffer.append((value >> 24) & 0xFF)


static func _append_f32(buffer: PackedByteArray, value: float) -> void:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_float(value)
	buffer.append_array(stream.data_array)
