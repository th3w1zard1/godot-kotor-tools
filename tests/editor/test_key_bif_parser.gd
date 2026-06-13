@tool
extends SceneTree

const KEYBIFParser := preload("../../formats/key_bif_parser.gd")

const RES_TYPE_2DA := 0x0018


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_parse_synthetic_key()
	_test_parse_synthetic_bif()
	_test_extract_resource_round_trip()
	_test_key_resref_lookup()
	print("✓ KEY/BIF parser tests passed")
	quit()


func _test_parse_synthetic_key() -> void:
	var key_bytes := _build_minimal_key_bytes()
	var parsed := KEYBIFParser.parse_key_bytes(key_bytes)
	assert(not parsed.is_empty())
	var bif_entries: Array = parsed.get("bif_entries", [])
	var key_entries: Array = parsed.get("key_entries", [])
	assert(bif_entries.size() == 1)
	assert(key_entries.size() == 1)
	assert(str(bif_entries[0].filename).ends_with("test.bif"))
	assert(str(key_entries[0].resref).strip_edges() == "test2da")
	assert(key_entries[0].resource_type == RES_TYPE_2DA)
	assert(key_entries[0].bif_index == 0)
	assert(key_entries[0].fixed_index == 0)
	print("✓ Synthetic KEY parse passed")


func _test_parse_synthetic_bif() -> void:
	var payload := "2DA V2.0\n\n".to_utf8_buffer()
	var bif_bytes := _build_minimal_bif_bytes(payload, RES_TYPE_2DA)
	var parsed := KEYBIFParser.parse_bif_bytes(bif_bytes)
	assert(not parsed.is_empty())
	var entries: Array = parsed.get("var_entries", [])
	assert(entries.size() == 1)
	assert(entries[0].offset > 0)
	assert(entries[0].file_size == payload.size())
	assert(entries[0].resource_type == RES_TYPE_2DA)
	print("✓ Synthetic BIF parse passed")


func _test_extract_resource_round_trip() -> void:
	var payload := "2DA V2.0\n\n".to_utf8_buffer()
	var bif_bytes := _build_minimal_bif_bytes(payload, RES_TYPE_2DA)
	var key_bytes := _build_minimal_key_bytes()
	var key_result := KEYBIFParser.parse_key_bytes(key_bytes)
	var extracted := KEYBIFParser.extract_resource(key_result, {0: bif_bytes}, "test2da", RES_TYPE_2DA)
	assert(extracted == payload)
	var found := KEYBIFParser.find_key_entry(key_result, "test2da", RES_TYPE_2DA)
	assert(found != null)
	print("✓ KEY/BIF extract round-trip passed")


func _test_key_resref_lookup() -> void:
	var key_bytes := _build_minimal_key_bytes()
	var key_result := KEYBIFParser.parse_key_bytes(key_bytes)
	assert(KEYBIFParser.find_key_entry(key_result, "missing", RES_TYPE_2DA) == null)
	var catalog: Array = key_result.get("bif_entries", [])
	assert(catalog.size() == 1)
	print("✓ KEY resref lookup passed")


func _build_minimal_key_bytes() -> PackedByteArray:
	var bif_filename := "data\\test.bif"
	var filename_bytes := bif_filename.to_utf8_buffer()
	if filename_bytes[filename_bytes.size() - 1] != 0:
		filename_bytes.append(0)
	var filename_size := filename_bytes.size()
	var offset_filetable := 64
	var offset_keytable := offset_filetable + 12 + filename_size
	var total_size := offset_keytable + 22
	var buf := PackedByteArray()
	buf.resize(total_size)

	_write_ascii(buf, 0, "KEY ")
	_write_ascii(buf, 4, "V1.0")
	_write_u32(buf, 0x08, 1)
	_write_u32(buf, 0x0C, 1)
	_write_u32(buf, 0x10, offset_filetable)
	_write_u32(buf, 0x14, offset_keytable)

	_write_u32(buf, offset_filetable + 0, 0)
	_write_u32(buf, offset_filetable + 4, 0)
	_write_u16(buf, offset_filetable + 8, filename_size)
	_write_u16(buf, offset_filetable + 10, 0x0001)

	var filename_offset := offset_filetable + 12
	for i in filename_size:
		buf[filename_offset + i] = filename_bytes[i]

	_write_ascii(buf, offset_keytable, "test2da", 16)
	_write_u16(buf, offset_keytable + 16, RES_TYPE_2DA)
	_write_u32(buf, offset_keytable + 18, 0)
	return buf


func _build_minimal_bif_bytes(payload: PackedByteArray, resource_type: int) -> PackedByteArray:
	var header_size := 20
	var table_size := 16
	var data_offset := header_size + table_size
	var total_size := data_offset + payload.size()
	var buf := PackedByteArray()
	buf.resize(total_size)

	_write_ascii(buf, 0, "BIFF")
	_write_ascii(buf, 4, "V1.0")
	_write_u32(buf, 0x08, 1)
	_write_u32(buf, 0x0C, 0)
	_write_u32(buf, 0x10, header_size)

	_write_u32(buf, header_size + 0, 0)
	_write_u32(buf, header_size + 4, data_offset)
	_write_u32(buf, header_size + 8, payload.size())
	_write_u16(buf, header_size + 12, resource_type)
	_write_u16(buf, header_size + 14, 0)

	for i in payload.size():
		buf[data_offset + i] = payload[i]
	return buf


func _write_ascii(buf: PackedByteArray, offset: int, text: String, max_len: int = -1) -> void:
	var bytes := text.to_ascii_buffer()
	var limit := max_len if max_len > 0 else bytes.size()
	for i in limit:
		if i < bytes.size():
			buf[offset + i] = bytes[i]
		else:
			buf[offset + i] = 0


func _write_u16(buf: PackedByteArray, offset: int, value: int) -> void:
	buf[offset] = value & 0xFF
	buf[offset + 1] = (value >> 8) & 0xFF


func _write_u32(buf: PackedByteArray, offset: int, value: int) -> void:
	buf[offset] = value & 0xFF
	buf[offset + 1] = (value >> 8) & 0xFF
	buf[offset + 2] = (value >> 16) & 0xFF
	buf[offset + 3] = (value >> 24) & 0xFF
