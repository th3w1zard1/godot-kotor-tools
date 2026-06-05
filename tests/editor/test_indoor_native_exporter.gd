@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const ERFParser := preload("../../formats/erf_parser.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorKitLibrary := preload("../../resources/indoor/kotor_indoor_kit_library.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")
const KotorIndoorModBuilder := preload("../../resources/indoor/kotor_indoor_mod_builder.gd")
const KotorIndoorNativeExporter := preload("../../resources/indoor/kotor_indoor_native_exporter.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var kits_root := _create_fixture_kits_directory()
	_test_preflight_requires_rooms()
	_test_preflight_embedded_without_kits_path()
	_test_preflight_kit_room_requires_kits_path()
	_test_export_embedded_mod()
	_test_export_kit_mod(kits_root)
	_cleanup_fixture(kits_root)
	print("✓ Indoor native exporter tests passed")
	quit()


func _test_preflight_requires_rooms() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [],
	})
	var preflight := KotorIndoorNativeExporter.validate_preflight({
		"document": document,
		"output_path": "/tmp/test01.mod",
	})
	assert(not preflight.get("ok", true))
	print("✓ Indoor native exporter preflight requires rooms passed")


func _test_preflight_embedded_without_kits_path() -> void:
	var document := _document_with_embedded_room()
	var preflight := KotorIndoorNativeExporter.validate_preflight({
		"document": document,
		"output_path": "/tmp/test01.mod",
	})
	assert(preflight.get("ok", false))
	print("✓ Indoor native exporter embedded preflight without kits passed")


func _test_preflight_kit_room_requires_kits_path() -> void:
	var library := KotorIndoorKitLibrary.new()
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [],
	})
	document.set_kit_library(library)
	document.add_room_from_kit("testkit", "room_a", Vector3.ZERO, 0.0)

	var preflight := KotorIndoorNativeExporter.validate_preflight({
		"document": document,
		"output_path": "/tmp/test01.mod",
	})
	assert(not preflight.get("ok", true))
	print("✓ Indoor native exporter kit room requires kits path passed")


func _test_export_embedded_mod() -> void:
	var document := _document_with_embedded_room()
	var output_path := "/tmp/kotor_indoor_native_export_%d.mod" % Time.get_ticks_usec()
	var result := KotorIndoorNativeExporter.export_indoor_to_mod({
		"document": document,
		"output_path": output_path,
	})
	assert(result.get("ok", false))
	assert(FileAccess.file_exists(output_path))
	var parsed := ERFParser.parse_file(output_path)
	var names := KotorIndoorModBuilder.list_entry_names(parsed)
	assert(names.has("test01.are"))
	assert(names.has("test01.git"))
	assert(names.has("test01.ifo"))
	assert(names.has("test01.lyt"))
	assert(names.has("test01.vis"))
	DirAccess.remove_absolute(output_path)
	print("✓ Indoor native exporter embedded MOD export passed")


func _test_export_kit_mod(kits_root: String) -> void:
	var library := KotorIndoorKitLibrary.new()
	library.configure(kits_root)
	library.refresh()

	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [],
	})
	document.set_kit_library(library)
	document.add_room_from_kit("testkit", "room_a", Vector3.ZERO, 0.0)

	var output_path := "/tmp/kotor_indoor_native_export_kit_%d.mod" % Time.get_ticks_usec()
	var result := KotorIndoorNativeExporter.export_indoor_to_mod({
		"document": document,
		"kit_library": library,
		"kits_path": kits_root,
		"output_path": output_path,
	})
	assert(result.get("ok", false))
	assert(FileAccess.file_exists(output_path))
	DirAccess.remove_absolute(output_path)
	print("✓ Indoor native exporter kit MOD export passed")


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


func _create_fixture_kits_directory() -> String:
	var root: String = "/tmp/kotor_indoor_native_export_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	var kit_dir: String = root.path_join("testkit")
	DirAccess.make_dir_recursive_absolute(kit_dir)

	var wok_bytes := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var wok_file := FileAccess.open(kit_dir.path_join("room_a.wok"), FileAccess.WRITE)
	wok_file.store_buffer(wok_bytes)
	wok_file.close()

	var kit_json := {
		"id": "testkit",
		"name": "Test Kit",
		"format_version": 1,
		"doors": [],
		"components": [
			{
				"id": "room_a",
				"name": "room_a",
				"doorhooks": [],
			},
		],
	}
	var json_file := FileAccess.open(root.path_join("testkit.json"), FileAccess.WRITE)
	json_file.store_string(JSON.stringify(kit_json))
	json_file.close()
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
