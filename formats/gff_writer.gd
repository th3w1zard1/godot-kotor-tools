@tool
class_name GFFWriter

const GFFParser := preload("./gff_parser.gd")
const GFFResource := preload("../resources/gff_resource.gd")


static func save_resource(resource: GFFResource, path: String) -> Error:
	var bytes := serialize(resource)
	if bytes.is_empty():
		return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	var err := file.get_error()
	file.close()
	return OK if err == OK or err == ERR_FILE_EOF else err


static func serialize(resource: Resource) -> PackedByteArray:
	if not resource is GFFResource:
		push_error("GFFWriter: resource is not a GFFResource")
		return PackedByteArray()
	var gff_resource := resource as GFFResource
	if String(gff_resource.file_type).strip_edges().is_empty():
		push_error("GFFWriter: file_type is required")
		return PackedByteArray()
	if gff_resource.schema_data.is_empty():
		push_error("GFFWriter: schema_data is required to serialize GFF resources")
		return PackedByteArray()
	return _Builder.new(gff_resource).build()


class _Builder:
	var _resource: GFFResource
	var _structs: Array[Dictionary] = []
	var _fields: Array[Dictionary] = []
	var _labels: Array[String] = []
	var _label_lookup: Dictionary = {}
	var _field_data := PackedByteArray()
	var _field_indices := PackedByteArray()
	var _list_indices := PackedByteArray()


	func _init(resource: GFFResource) -> void:
		_resource = resource


	func build() -> PackedByteArray:
		_encode_struct(_resource.gff_data, _resource.schema_data, true)

		var structs_offset := 56
		var fields_offset := structs_offset + _structs.size() * 12
		var labels_offset := fields_offset + _fields.size() * 12
		var field_data_offset := labels_offset + _labels.size() * 16
		var field_indices_offset := field_data_offset + _field_data.size()
		var list_indices_offset := field_indices_offset + _field_indices.size()

		var bytes := PackedByteArray()
		_append_ascii(bytes, _normalize_file_type(_resource.file_type), 4)
		_append_ascii(bytes, "V3.2", 4)
		_append_u32(bytes, structs_offset)
		_append_u32(bytes, _structs.size())
		_append_u32(bytes, fields_offset)
		_append_u32(bytes, _fields.size())
		_append_u32(bytes, labels_offset)
		_append_u32(bytes, _labels.size())
		_append_u32(bytes, field_data_offset)
		_append_u32(bytes, _field_data.size())
		_append_u32(bytes, field_indices_offset)
		_append_u32(bytes, _field_indices.size())
		_append_u32(bytes, list_indices_offset)
		_append_u32(bytes, _list_indices.size())

		for struct_info in _structs:
			_append_u32(bytes, int(struct_info.get("type", 0xFFFFFFFF)))
			_append_u32(bytes, int(struct_info.get("data_or_offset", 0)))
			_append_u32(bytes, int(struct_info.get("field_count", 0)))
		for field_info in _fields:
			_append_u32(bytes, int(field_info.get("type", 0)))
			_append_u32(bytes, int(field_info.get("label_index", 0)))
			_append_u32(bytes, int(field_info.get("data_or_offset", 0)))
		for label in _labels:
			_append_ascii(bytes, label, 16)
		bytes.append_array(_field_data)
		bytes.append_array(_field_indices)
		bytes.append_array(_list_indices)
		return bytes


	func _encode_struct(value: Dictionary, schema: Dictionary, is_root: bool = false) -> int:
		var struct_index := _structs.size()
		_structs.append({})

		var field_indices: Array[int] = []
		var schema_fields: Array = schema.get("fields", [])
		for field_schema in schema_fields:
			var field_name := str(field_schema.get("name", ""))
			if field_name.is_empty() or not value.has(field_name):
				continue
			field_indices.append(_encode_field(field_name, value.get(field_name), field_schema))

		var data_or_offset := 0
		if field_indices.size() == 1:
			data_or_offset = field_indices[0]
		elif field_indices.size() > 1:
			data_or_offset = _field_indices.size()
			for field_index in field_indices:
				_append_u32(_field_indices, field_index)

		_structs[struct_index] = {
			"type": 0xFFFFFFFF if is_root else int(schema.get("struct_type", 0)),
			"data_or_offset": data_or_offset,
			"field_count": field_indices.size(),
		}
		return struct_index


	func _encode_field(field_name: String, value: Variant, field_schema: Dictionary) -> int:
		var field_type := int(field_schema.get("type", GFFParser.FIELD_CEXOSTRING))
		var label_index := _ensure_label(field_name)
		var data_or_offset := 0

		match field_type:
			GFFParser.FIELD_BYTE:
				data_or_offset = int(value) & 0xFF
			GFFParser.FIELD_CHAR:
				data_or_offset = int(value) & 0xFF
			GFFParser.FIELD_WORD:
				data_or_offset = int(value) & 0xFFFF
			GFFParser.FIELD_SHORT:
				data_or_offset = int(value) & 0xFFFF
			GFFParser.FIELD_DWORD, GFFParser.FIELD_INT:
				data_or_offset = int(value) & 0xFFFFFFFF
			GFFParser.FIELD_FLOAT:
				data_or_offset = _float_to_u32(float(value))
			GFFParser.FIELD_DWORD64, GFFParser.FIELD_INT64:
				data_or_offset = _field_data.size()
				_append_i64(_field_data, int(value))
			GFFParser.FIELD_DOUBLE:
				data_or_offset = _field_data.size()
				_append_double(_field_data, float(value))
			GFFParser.FIELD_CEXOSTRING:
				data_or_offset = _field_data.size()
				_append_cexostring(_field_data, String(value))
			GFFParser.FIELD_CRESREF:
				data_or_offset = _field_data.size()
				_append_resref(_field_data, String(value))
			GFFParser.FIELD_CEXOLOCSTR:
				data_or_offset = _field_data.size()
				_append_locstring(_field_data, value if typeof(value) == TYPE_DICTIONARY else {})
			GFFParser.FIELD_VOID:
				data_or_offset = _field_data.size()
				_append_void(_field_data, value if value is PackedByteArray else PackedByteArray())
			GFFParser.FIELD_STRUCT:
				data_or_offset = _encode_struct(value if typeof(value) == TYPE_DICTIONARY else {}, field_schema.get("schema", {}))
			GFFParser.FIELD_LIST:
				var struct_indices := _build_list_struct_indices(
					value if typeof(value) == TYPE_ARRAY else [],
					field_schema.get("items", [])
				)
				data_or_offset = _list_indices.size()
				_append_u32(_list_indices, struct_indices.size())
				for struct_index in struct_indices:
					_append_u32(_list_indices, struct_index)
			GFFParser.FIELD_QUATERNION:
				data_or_offset = _field_data.size()
				_append_quaternion(_field_data, value if value is Quaternion else Quaternion.IDENTITY)
			GFFParser.FIELD_VECTOR:
				data_or_offset = _field_data.size()
				_append_vector(_field_data, value if value is Vector3 else Vector3.ZERO)
			_:
				data_or_offset = _field_data.size()
				_append_cexostring(_field_data, String(value))

		_fields.append({
			"type": field_type,
			"label_index": label_index,
			"data_or_offset": data_or_offset,
		})
		return _fields.size() - 1


	func _build_list_struct_indices(values: Array, item_schemas: Array) -> Array[int]:
		var struct_indices: Array[int] = []
		for index in range(values.size()):
			var item_schema: Dictionary = {}
			if index < item_schemas.size():
				item_schema = item_schemas[index]
			elif not item_schemas.is_empty():
				item_schema = item_schemas[item_schemas.size() - 1]
			struct_indices.append(_encode_struct(
				values[index] if typeof(values[index]) == TYPE_DICTIONARY else {},
				item_schema
			))
		return struct_indices


	func _ensure_label(field_name: String) -> int:
		if _label_lookup.has(field_name):
			return int(_label_lookup[field_name])
		var label_index := _labels.size()
		_labels.append(field_name)
		_label_lookup[field_name] = label_index
		return label_index


	static func _normalize_file_type(file_type: String) -> String:
		var normalized := file_type.strip_edges().to_upper()
		if normalized.length() > 4:
			return normalized.substr(0, 4)
		while normalized.length() < 4:
			normalized += " "
		return normalized


	static func _append_u32(target: PackedByteArray, value: int) -> void:
		target.append(value & 0xFF)
		target.append((value >> 8) & 0xFF)
		target.append((value >> 16) & 0xFF)
		target.append((value >> 24) & 0xFF)


	static func _append_i64(target: PackedByteArray, value: int) -> void:
		_append_u32(target, value & 0xFFFFFFFF)
		_append_u32(target, (value >> 32) & 0xFFFFFFFF)


	static func _append_ascii(target: PackedByteArray, text: String, length: int) -> void:
		var bytes := text.to_ascii_buffer()
		var limit := mini(length, bytes.size())
		for index in range(limit):
			target.append(bytes[index])
		for _pad in range(length - limit):
			target.append(0)


	static func _append_bytes(target: PackedByteArray, bytes: PackedByteArray) -> void:
		target.append_array(bytes)


	static func _append_cexostring(target: PackedByteArray, text: String) -> void:
		var bytes := text.to_utf8_buffer()
		_append_u32(target, bytes.size())
		_append_bytes(target, bytes)


	static func _append_resref(target: PackedByteArray, text: String) -> void:
		var bytes := text.strip_edges().substr(0, 16).to_ascii_buffer()
		target.append(bytes.size() & 0xFF)
		_append_bytes(target, bytes)


	static func _append_locstring(target: PackedByteArray, locstring: Dictionary) -> void:
		var payload := PackedByteArray()
		_append_u32(payload, int(locstring.get("strref", 0xFFFFFFFF)) & 0xFFFFFFFF)
		var strings: Dictionary = locstring.get("strings", {})
		var language_ids: Array[int] = []
		for key in strings.keys():
			language_ids.append(int(key))
		language_ids.sort()
		_append_u32(payload, language_ids.size())
		for language_id in language_ids:
			var text_bytes := String(strings.get(language_id, "")).to_utf8_buffer()
			_append_u32(payload, language_id & 0xFFFFFFFF)
			_append_u32(payload, text_bytes.size())
			_append_bytes(payload, text_bytes)
		_append_u32(target, payload.size())
		_append_bytes(target, payload)


	static func _append_void(target: PackedByteArray, bytes: PackedByteArray) -> void:
		_append_u32(target, bytes.size())
		_append_bytes(target, bytes)


	static func _append_vector(target: PackedByteArray, value: Vector3) -> void:
		_append_bytes(target, _float_bytes(value.x))
		_append_bytes(target, _float_bytes(value.y))
		_append_bytes(target, _float_bytes(value.z))


	static func _append_quaternion(target: PackedByteArray, value: Quaternion) -> void:
		_append_bytes(target, _float_bytes(value.w))
		_append_bytes(target, _float_bytes(value.x))
		_append_bytes(target, _float_bytes(value.y))
		_append_bytes(target, _float_bytes(value.z))


	static func _append_double(target: PackedByteArray, value: float) -> void:
		var buffer := StreamPeerBuffer.new()
		buffer.big_endian = false
		buffer.put_double(value)
		_append_bytes(target, buffer.data_array)


	static func _float_to_u32(value: float) -> int:
		var bytes := _float_bytes(value)
		return (bytes[0]
			| (bytes[1] << 8)
			| (bytes[2] << 16)
			| (bytes[3] << 24)) & 0xFFFFFFFF


	static func _float_bytes(value: float) -> PackedByteArray:
		var buffer := StreamPeerBuffer.new()
		buffer.big_endian = false
		buffer.put_float(value)
		return buffer.data_array
