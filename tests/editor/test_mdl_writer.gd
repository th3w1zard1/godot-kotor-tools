@tool
extends SceneTree

const MDLParser := preload("../../formats/mdl_parser.gd")
const MDLWriter := preload("../../formats/mdl_writer.gd")
const MdlResource := preload("../../resources/mdl_resource.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_passthrough_round_trip()
	_test_reject_invalid_mdl()
	_test_mdx_passthrough()
	_test_mdl_resource_setup()
	_test_pipeline_serialize_mdl_resource()
	print("✓ MDL writer tests passed")
	quit()


func _test_passthrough_round_trip() -> void:
	var source := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var written := MDLWriter.serialize_passthrough(source)
	assert(written.size() == source.size())
	for index in range(source.size()):
		assert(written[index] == source[index])
	print("✓ MDL passthrough round-trip passed")


func _test_reject_invalid_mdl() -> void:
	assert(MDLWriter.serialize_passthrough(PackedByteArray()).is_empty())
	assert(MDLWriter.serialize_passthrough("bad".to_utf8_buffer()).is_empty())
	print("✓ MDL invalid passthrough rejection passed")


func _test_mdx_passthrough() -> void:
	var mdx := PackedByteArray([0x01, 0x02, 0x03])
	var written := MDLWriter.serialize_mdx_passthrough(mdx)
	assert(written == mdx)
	assert(MDLWriter.serialize_mdx_passthrough(PackedByteArray()).is_empty())
	print("✓ MDX passthrough passed")


func _test_mdl_resource_setup() -> void:
	var mdl := _build_minimal_mdl(
		[Vector3(1.0, 0.0, 0.0), Vector3(3.0, 0.0, 0.0), Vector3(1.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var mdx := PackedByteArray([0xAA])
	var resource := MdlResource.from_bytes(mdl, mdx)
	assert(resource != null)
	assert(resource.is_valid())
	assert(resource.has_mdx())
	assert(resource.serialize_mdl().size() == mdl.size())
	assert(resource.serialize_mdx() == mdx)
	print("✓ MdlResource setup passed")


func _test_pipeline_serialize_mdl_resource() -> void:
	var mdl := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)],
		[0, 1, 2]
	)
	var resource := MdlResource.from_bytes(mdl)
	var serialized := KotorModdingPipeline.serialize_payload("room_a.mdl", resource)
	assert(serialized.get("ok", false))
	var payload: PackedByteArray = serialized.get("payload", PackedByteArray())
	assert(payload.size() == mdl.size())
	print("✓ Pipeline MDL resource serialize passed")


static func _build_minimal_mdl(vertices: Array, face_indices: Array) -> PackedByteArray:
	return preload("res://tests/editor/test_mdl_parser.gd")._build_minimal_mdl(vertices, face_indices)
