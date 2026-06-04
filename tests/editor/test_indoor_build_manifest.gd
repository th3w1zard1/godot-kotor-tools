@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const KotorIndoorBuildManifest := preload("../../resources/indoor/kotor_indoor_build_manifest.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorKitLibrary := preload("../../resources/indoor/kotor_indoor_kit_library.gd")
const KotorIndoorMapIO := preload("../../resources/indoor/kotor_indoor_map_io.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var kits_root := _create_fixture_kits_directory()
	_test_validation_failure()
	_test_core_module_resources(kits_root)
	_test_room_asset_entries(kits_root)
	_test_format_report(kits_root)
	_test_normalize_module_id()
	_cleanup_fixture(kits_root)
	print("✓ Indoor build manifest tests passed")
	quit()


func _test_validation_failure() -> void:
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "",
		"warp": "",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [],
	})
	var manifest := KotorIndoorBuildManifest.build(document)
	assert(not manifest.get("ok", true))
	assert(manifest.get("errors", []).size() >= 1)
	print("✓ Indoor build manifest validation failure passed")


func _test_core_module_resources(kits_root: String) -> void:
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

	var manifest := KotorIndoorBuildManifest.build(document, library)
	assert(manifest.get("ok", false))
	assert(str(manifest.get("module_id", "")) == "test01")
	var resources: Array = manifest.get("resources", [])
	var core_extensions: Array[String] = []
	for raw_resource in resources:
		if typeof(raw_resource) != TYPE_DICTIONARY:
			continue
		var resource: Dictionary = raw_resource
		if str(resource.get("kind", "")) == "core_module":
			core_extensions.append(str(resource.get("extension", "")))
	assert(core_extensions.has("are"))
	assert(core_extensions.has("git"))
	assert(core_extensions.has("ifo"))
	assert(core_extensions.has("lyt"))
	assert(core_extensions.has("vis"))
	print("✓ Indoor build manifest core module resources passed")


func _test_room_asset_entries(kits_root: String) -> void:
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

	var manifest := KotorIndoorBuildManifest.build(document, library)
	var room_assets: Array = manifest.get("room_assets", [])
	assert(room_assets.size() == 1)
	var asset: Dictionary = room_assets[0]
	assert(str(asset.get("component", "")) == "room_a")
	assert(str(asset.get("model_resref", "")) == "room_a")
	var resources: Array = manifest.get("resources", [])
	var has_mdl := false
	var has_wok := false
	for raw_resource in resources:
		if typeof(raw_resource) != TYPE_DICTIONARY:
			continue
		var resource: Dictionary = raw_resource
		if str(resource.get("resref", "")) != "room_a":
			continue
		if str(resource.get("extension", "")) == "mdl":
			has_mdl = true
		if str(resource.get("extension", "")) == "wok":
			has_wok = true
	assert(has_mdl and has_wok)
	print("✓ Indoor build manifest room asset entries passed")


func _test_format_report(kits_root: String) -> void:
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

	var manifest := KotorIndoorBuildManifest.build(document, library)
	var report := KotorIndoorBuildManifest.format_report(manifest)
	assert(report.find("Module ID: test01") >= 0)
	assert(report.find("test01.are") >= 0)
	assert(report.find("room_a") >= 0)
	print("✓ Indoor build manifest format report passed")


func _test_normalize_module_id() -> void:
	assert(KotorIndoorBuildManifest.normalize_module_id("  MyModule01  ") == "mymodule01")
	assert(
		KotorIndoorBuildManifest.normalize_module_id("abcdefghijklmnopqrstuvwxyz").length()
		== 16
	)
	print("✓ Indoor build manifest module id normalization passed")


func _create_fixture_kits_directory() -> String:
	var root: String = "/tmp/kotor_indoor_build_manifest_%d" % Time.get_ticks_usec()
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
