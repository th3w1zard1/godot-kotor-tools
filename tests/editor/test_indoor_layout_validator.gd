@tool
extends SceneTree

const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorKitLibrary := preload("../../resources/indoor/kotor_indoor_kit_library.gd")
const KotorIndoorLayoutValidator := preload("../../resources/indoor/kotor_indoor_layout_validator.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")
const KotorIndoorModExporter := preload("../../resources/indoor/kotor_indoor_mod_exporter.gd")
const BWMParser := preload("../../formats/bwm_parser.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var kits_root := _create_fixture_kits_directory()
	var game_root := kits_root.get_base_dir()
	_test_missing_module_identity()
	_test_missing_room_kit_component()
	_test_unknown_kit_component(kits_root)
	_test_missing_embedded_component()
	_test_open_hook_warning()
	_test_valid_layout(kits_root)
	_test_preflight_merges_layout_errors(kits_root, game_root)
	_cleanup_fixture(kits_root)
	print("✓ Indoor layout validator tests passed")
	quit()


func _test_missing_module_identity() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "",
		"warp": "",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [
			{
				"position": [0.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": "testkit",
				"component": "room_a",
			},
		],
	})
	var result := KotorIndoorLayoutValidator.validate(document)
	assert(not result.get("ok", true))
	var errors: Array = result.get("errors", [])
	assert(_errors_contain(errors, "module ID or warp"))
	print("✓ Indoor layout validator module identity passed")


func _test_missing_room_kit_component() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [
			{
				"position": [0.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": "",
				"component": "room_a",
			},
		],
	})
	var result := KotorIndoorLayoutValidator.validate(document)
	assert(not result.get("ok", true))
	var errors: Array = result.get("errors", [])
	assert(_errors_contain(errors, "missing kit or component"))
	print("✓ Indoor layout validator room kit/component passed")


func _test_unknown_kit_component(kits_root: String) -> void:
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
		"rooms": [
			{
				"position": [0.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": "testkit",
				"component": "missing_room",
			},
		],
	})
	document.set_kit_library(library)
	var result := KotorIndoorLayoutValidator.validate(document, library)
	assert(not result.get("ok", true))
	var errors: Array = result.get("errors", [])
	assert(_errors_contain(errors, "unknown kit component"))
	print("✓ Indoor layout validator unknown kit component passed")


func _test_missing_embedded_component() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [
			{
				"position": [0.0, 0.0, 0.0],
				"rotation": 0.0,
				"flip_x": false,
				"flip_y": false,
				"kit": KotorIndoorMapIO.EMBEDDED_KIT_ID,
				"component": "ghost_room",
			},
		],
	})
	var result := KotorIndoorLayoutValidator.validate(document)
	assert(not result.get("ok", true))
	var errors: Array = result.get("errors", [])
	assert(_errors_contain(errors, "missing embedded component"))
	print("✓ Indoor layout validator embedded component passed")


func _test_open_hook_warning() -> void:
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
				"bwm": "",
				"hooks": [{"position": [1.0, 0.0, 0.0]}],
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
	var result := KotorIndoorLayoutValidator.validate(document)
	assert(result.get("ok", true))
	var warnings: Array = result.get("warnings", [])
	assert(_errors_contain(warnings, "open door hook"))
	print("✓ Indoor layout validator open hook warning passed")


func _test_valid_layout(kits_root: String) -> void:
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

	var result := KotorIndoorLayoutValidator.validate(document, library)
	assert(result.get("ok", false))
	var warnings: Array = result.get("warnings", [])
	assert(warnings.is_empty())
	print("✓ Indoor layout validator valid layout passed")


func _test_preflight_merges_layout_errors(kits_root: String, game_root: String) -> void:
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
	var config := {
		"document": document,
		"input_path": "/tmp/layout.indoor",
		"output_path": "/tmp/layout.mod",
		"game_path": game_root,
		"kits_path": kits_root,
		"pykotor_cli_path": "/bin/true",
	}
	var preflight := KotorIndoorModExporter.validate_preflight(config)
	assert(not preflight.get("ok", true))
	var errors: Array = preflight.get("errors", [])
	assert(_errors_contain(errors, "no rooms"))
	print("✓ Indoor layout validator preflight merge passed")


func _errors_contain(errors: Array, needle: String) -> bool:
	for error_text in errors:
		if needle.to_lower() in str(error_text).to_lower():
			return true
	return false


func _create_fixture_kits_directory() -> String:
	var root: String = "/tmp/kotor_indoor_layout_validator_%d" % Time.get_ticks_usec()
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
