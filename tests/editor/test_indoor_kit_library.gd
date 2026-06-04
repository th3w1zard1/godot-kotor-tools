@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const KotorIndoorKitLoader := preload("../../resources/indoor/kotor_indoor_kit_loader.gd")
const KotorIndoorKitLibrary := preload("../../resources/indoor/kotor_indoor_kit_library.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var kits_root := _create_fixture_kits_directory()
	_test_loader_reads_kit_and_component(kits_root)
	_test_library_refresh_and_lookup(kits_root)
	_test_document_add_room_from_kit(kits_root)
	_cleanup_fixture(kits_root)
	print("✓ Indoor kit library tests passed")
	quit()


func _test_loader_reads_kit_and_component(kits_root: String) -> void:
	var loaded := KotorIndoorKitLoader.load_kits_from_directory(kits_root)
	var kits: Array = loaded.get("kits", [])
	assert(kits.size() == 1)
	var kit: Dictionary = kits[0]
	assert(str(kit.get("id", "")) == "testkit")
	var components: Array = kit.get("components", [])
	assert(components.size() == 1)
	var component: Dictionary = components[0]
	assert(str(component.get("id", "")) == "room_a")
	assert(float(component.get("half_width", 0.0)) > 0.0)
	assert(float(component.get("half_height", 0.0)) > 0.0)
	print("✓ Indoor kit loader fixture passed")


func _test_library_refresh_and_lookup(kits_root: String) -> void:
	var library := KotorIndoorKitLibrary.new()
	library.configure(kits_root)
	library.refresh()
	assert(library.get_kit_count() == 1)
	var ids := library.get_kit_ids()
	assert(ids.size() == 1)
	assert(ids[0] == "testkit")
	assert(library.has_component("testkit", "room_a"))
	var footprint := library.get_component_footprint("testkit", "room_a")
	assert(footprint.x > 0.0)
	assert(footprint.y > 0.0)
	var summaries := library.get_component_summaries("testkit")
	assert(summaries.size() == 1)
	print("✓ Indoor kit library refresh passed")


func _test_document_add_room_from_kit(kits_root: String) -> void:
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
	var index := document.add_room_from_kit("testkit", "room_a", Vector3(3.0, 4.0, 0.0), 0.25)
	assert(index == 0)
	assert(document.get_room_count() == 1)
	var record := document.find_room_record(0)
	assert(is_equal_approx(float(record.get("x", 0.0)), 3.0))
	assert(is_equal_approx(float(record.get("y", 0.0)), 4.0))
	assert(is_equal_approx(float(record.get("rotation", 0.0)), 0.25))
	assert(str(record.get("label", "")) == "testkit/room_a")
	assert(float(record.get("half_width", 0.0)) > 0.0)
	assert(document.remove_room(0))
	assert(document.get_room_count() == 0)
	var round_trip := KotorIndoorMapIO.parse_bytes(document.serialize_to_bytes())
	assert((round_trip.get("rooms", []) as Array).is_empty())
	print("✓ Indoor document kit placement passed")


func _create_fixture_kits_directory() -> String:
	var root: String = "/tmp/kotor_indoor_kit_test_%d" % Time.get_ticks_usec()
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
