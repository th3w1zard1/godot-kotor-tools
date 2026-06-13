@tool
extends SceneTree

const KEYBIFParser := preload("../../formats/key_bif_parser.gd")
const KotorGameFS := preload("../../gamefs/kotor_gamefs.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTargetContext := preload("../../editor/workspace/kotor_target_context.gd")

const RES_TYPE_2DA := 0x0018


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_gamefs_catalog_and_source_filter()
	print("✓ GameFS chitin catalog tests passed")
	quit()


func _test_gamefs_catalog_and_source_filter() -> void:
	var install_root := _make_install_root()
	_seed_chitin_install(install_root)
	var gamefs := KotorGameFS.new()
	assert(gamefs.index_install(install_root))

	var catalog: Array[Dictionary] = gamefs.list_chitin_bif_catalog()
	assert(catalog.size() == 1)
	assert(int(catalog[0].get("key_entry_count", 0)) == 1)
	assert(str(catalog[0].get("filename", "")).contains("test.bif"))

	var chitin_entries: Array[Dictionary] = gamefs.list_core_resources("", null, "chitin.key", 0)
	assert(chitin_entries.size() == 1)
	assert(str(chitin_entries[0].get("resref", "")) == "test2da")

	var bytes := gamefs.load_resource_entry_bytes(chitin_entries[0])
	assert(bytes == "2DA V2.0\n\n".to_utf8_buffer())

	var state := KotorEditorState.new()
	state.game_path = install_root
	state.refresh_gamefs()
	var context := KotorTargetContext.new().setup(state)
	var filtered: Array[Dictionary] = context.list_resources_filtered("", "", "chitin.key", 0)
	assert(filtered.size() == 1)
	var context_catalog: Array[Dictionary] = context.list_chitin_bif_catalog()
	assert(context_catalog.size() == 1)

	_cleanup(install_root)
	print("✓ GameFS chitin catalog and source filter passed")


func _seed_chitin_install(install_root: String) -> void:
	var payload := "2DA V2.0\n\n".to_utf8_buffer()
	var bif_bytes := _build_minimal_bif_bytes(payload, RES_TYPE_2DA)
	var data_dir := install_root.path_join("data")
	DirAccess.make_dir_recursive_absolute(data_dir)
	_write_bytes(data_dir.path_join("test.bif"), bif_bytes)

	var key_bytes := _build_minimal_key_bytes()
	_write_u32(key_bytes, 64, bif_bytes.size())
	_write_bytes(install_root.path_join("chitin.key"), key_bytes)


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


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _make_install_root() -> String:
	var counter := Time.get_ticks_msec()
	return ProjectSettings.globalize_path("user://chitin_catalog_test_%d" % counter)


func _cleanup(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)
