@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const ERFParser := preload("../../formats/erf_parser.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")
const KotorIndoorModBuilder := preload("../../resources/indoor/kotor_indoor_mod_builder.gd")
const KotorIndoorModuleInstaller := preload("../../resources/indoor/kotor_indoor_module_installer.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_root := _create_game_install_directory()
	_test_preflight_requires_game_path()
	_test_resolve_modules_path(game_root)
	_test_install_embedded_mod(game_root)
	_test_install_creates_backup(game_root)
	_cleanup_fixture(game_root)
	print("✓ Indoor module installer tests passed")
	quit()


func _test_preflight_requires_game_path() -> void:
	var document := _document_with_embedded_room()
	var preflight := KotorIndoorModuleInstaller.validate_preflight({
		"document": document,
		"output_path": "/tmp/test01.mod",
	})
	assert(not preflight.get("ok", true))
	print("✓ Indoor module installer preflight requires game path passed")


func _test_resolve_modules_path(game_root: String) -> void:
	var modules_path := KotorIndoorModuleInstaller.resolve_modules_path(game_root)
	assert(not modules_path.is_empty())
	assert(DirAccess.dir_exists_absolute(modules_path))
	print("✓ Indoor module installer resolve modules path passed")


func _test_install_embedded_mod(game_root: String) -> void:
	var document := _document_with_embedded_room()
	var result := KotorIndoorModuleInstaller.install_indoor_mod_to_modules({
		"document": document,
		"game_path": game_root,
		"output_path": "/tmp/test01.mod",
	})
	assert(result.get("ok", false))
	var mod_path := str(result.get("output_path", ""))
	assert(FileAccess.file_exists(mod_path))
	var parsed := ERFParser.parse_file(mod_path)
	var names := KotorIndoorModBuilder.list_entry_names(parsed)
	assert(names.has("test01.are"))
	assert(names.has("test01.git"))
	assert(names.has("test01.ifo"))
	assert(names.has("test01.lyt"))
	assert(names.has("test01.vis"))
	print("✓ Indoor module installer embedded MOD install passed")


func _test_install_creates_backup(game_root: String) -> void:
	var document := _document_with_embedded_room()
	var modules_path := KotorIndoorModuleInstaller.resolve_modules_path(game_root)
	var mod_path := modules_path.path_join("test01.mod")
	var stale_file := FileAccess.open(mod_path, FileAccess.WRITE)
	stale_file.store_string("stale module bytes")
	stale_file.close()

	var result := KotorIndoorModuleInstaller.install_indoor_mod_to_modules({
		"document": document,
		"game_path": game_root,
		"output_path": "/tmp/test01.mod",
	})
	assert(result.get("ok", false))
	assert(FileAccess.file_exists("%s.bak" % mod_path))
	var parsed := ERFParser.parse_file(mod_path)
	assert(str(parsed.get("file_type", "")) == "MOD ")
	print("✓ Indoor module installer backup on overwrite passed")


func _document_with_embedded_room() -> KotorIndoorDocument:
	var wok_bytes := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [
			{
				"id": "room_a",
				"name": "room_a",
				"bwm": Marshalls.raw_to_base64(wok_bytes),
				"hooks": [],
			},
		],
		"rooms": [
			{
				"position": [0.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
				"component": "room_a",
			},
		],
	})
	return document


func _create_game_install_directory() -> String:
	var root: String = "/tmp/kotor_indoor_module_install_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	return root


func _cleanup_fixture(root: String) -> void:
	_remove_dir_recursive(root)


func _remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var child := path.path_join(entry)
		if dir.current_is_dir():
			_remove_dir_recursive(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


static func _build_minimal_wok(vertices: Array, face_indices: Array, materials: Array) -> PackedByteArray:
	var vertex_count := vertices.size()
	var face_count := materials.size()
	assert(face_indices.size() == face_count * 3)

	var vertices_offset := BWMParser.HEADER_SIZE
	var indices_offset := vertices_offset + vertex_count * 12
	var materials_offset := indices_offset + face_count * 12
	var total_size := materials_offset + face_count * 4

	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.resize(total_size)

	_write_fixed_string(stream, BWMParser.MAGIC, 4)
	_write_fixed_string(stream, BWMParser.VERSION, 4)
	stream.put_u32(0)
	for _i in range(5):
		_write_vector3(stream, Vector3.ZERO)
	stream.put_u32(vertex_count)
	stream.put_u32(vertices_offset)
	stream.put_u32(face_count)
	stream.put_u32(indices_offset)
	stream.put_u32(materials_offset)

	stream.seek(vertices_offset)
	for vertex in vertices:
		_write_vector3(stream, vertex)

	stream.seek(indices_offset)
	for index in face_indices:
		stream.put_u32(index)

	stream.seek(materials_offset)
	for material_id in materials:
		stream.put_u32(material_id)

	return stream.data_array


static func _write_vector3(stream: StreamPeerBuffer, value: Vector3) -> void:
	stream.put_float(value.x)
	stream.put_float(value.y)
	stream.put_float(value.z)


static func _write_fixed_string(stream: StreamPeerBuffer, text: String, length: int) -> void:
	var bytes := text.to_ascii_buffer()
	for index in range(length):
		if index < bytes.size():
			stream.put_u8(bytes[index])
		else:
			stream.put_u8(0)
