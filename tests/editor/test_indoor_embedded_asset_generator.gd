@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const KotorIndoorEmbeddedAssetGenerator := preload(
	"../../resources/indoor/kotor_indoor_embedded_asset_generator.gd"
)


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wok_bytes := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	_test_decode_empty_fields()
	_test_asset_flags(wok_bytes)
	_test_list_entries(wok_bytes)
	_test_invalid_bwm_warning()
	print("✓ Indoor embedded asset generator tests passed")
	quit()


func _test_decode_empty_fields() -> void:
	assert(KotorIndoorEmbeddedAssetGenerator.decode_base64_field("").is_empty())
	print("✓ Embedded asset generator decode empty passed")


func _test_asset_flags(wok_bytes: PackedByteArray) -> void:
	var encoded := Marshalls.raw_to_base64(wok_bytes)
	var flags := KotorIndoorEmbeddedAssetGenerator.asset_flags({
		"id": "room_a",
		"bwm": encoded,
		"mdl": Marshalls.raw_to_base64(PackedByteArray([1, 2, 3])),
	})
	assert(flags.get("has_wok", false))
	assert(flags.get("has_mdl", false))
	assert(not flags.get("has_mdx", true))
	print("✓ Embedded asset generator asset flags passed")


func _test_list_entries(wok_bytes: PackedByteArray) -> void:
	var encoded := Marshalls.raw_to_base64(wok_bytes)
	var mdl_bytes := PackedByteArray([9, 8, 7])
	var entries := KotorIndoorEmbeddedAssetGenerator.list_entries("room_a", {
		"id": "room_a",
		"bwm": encoded,
		"mdl": Marshalls.raw_to_base64(mdl_bytes),
	})
	assert(entries.size() == 2)
	assert(str(entries[0].get("extension", "")) == "wok" or str(entries[1].get("extension", "")) == "wok")
	var wok_entry: Dictionary = entries[0] if str(entries[0].get("extension", "")) == "wok" else entries[1]
	assert(wok_entry.get("bytes", PackedByteArray()) == wok_bytes)
	print("✓ Embedded asset generator list entries passed")


func _test_invalid_bwm_warning() -> void:
	var warnings: Array = []
	var entries := KotorIndoorEmbeddedAssetGenerator.list_entries(
		"room_a",
		{"id": "room_a", "bwm": Marshalls.raw_to_base64(PackedByteArray([0, 1, 2]))},
		warnings
	)
	assert(entries.is_empty())
	assert(warnings.size() >= 1)
	print("✓ Embedded asset generator invalid BWM warning passed")


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
