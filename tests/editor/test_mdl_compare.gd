@tool
extends SceneTree

const MDLParser := preload("../../formats/mdl_parser.gd")
const ERFWriter := preload("../../formats/erf_writer.gd")
const MdlCompare := preload("../../formats/mdl_compare.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")

var _install_counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_vertex_count_diff()
	_test_mdx_size_diff()
	_test_mdx_presence_diff()
	_test_identical_mdl_and_mdx_no_report()
	_test_identical_no_report()
	_test_invalid_bytes_fallback()
	_test_pipeline_wiring()
	_test_gamefs_mdx_pairing()
	print("✓ MDL compare tests passed")
	quit()


func _test_vertex_count_diff() -> void:
	var base := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var mod := _build_minimal_mdl(
		[
			Vector3(0.0, 0.0, 0.0),
			Vector3(2.0, 0.0, 0.0),
			Vector3(0.0, 2.0, 0.0),
			Vector3(1.0, 1.0, 0.0),
		],
		[0, 1, 2]
	)
	var report := MdlCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("MDL differs") >= 0)
	assert(report.find("vertices: 3 -> 4") >= 0)
	print("✓ MDL vertex count diff passed")


func _test_mdx_size_diff() -> void:
	var mdl := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var report := MdlCompare.build_difference_report(
		mdl,
		mdl,
		PackedByteArray([0x01, 0x02]),
		PackedByteArray([0x01, 0x02, 0x03])
	)
	assert(not report.is_empty())
	assert(report.find("MDX size: 2 -> 3 B") >= 0)
	print("✓ MDL MDX size diff passed")


func _test_mdx_presence_diff() -> void:
	var mdl := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var report := MdlCompare.build_difference_report(
		mdl,
		mdl,
		PackedByteArray(),
		PackedByteArray([0x01])
	)
	assert(not report.is_empty())
	assert(report.find("MDX sidecar: absent -> present") >= 0)
	print("✓ MDL MDX presence diff passed")


func _test_identical_mdl_and_mdx_no_report() -> void:
	var mdl := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)],
		[0, 1, 2]
	)
	var mdx := PackedByteArray([0x01, 0x02, 0x03])
	assert(MdlCompare.build_difference_report(mdl, mdl, mdx, mdx).is_empty())
	print("✓ MDL identical MDL+MDX no report passed")


func _test_identical_no_report() -> void:
	var bytes := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)],
		[0, 1, 2]
	)
	assert(MdlCompare.build_difference_report(bytes, bytes).is_empty())
	print("✓ MDL identical no report passed")


func _test_invalid_bytes_fallback() -> void:
	assert(MdlCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(32)
	assert(MdlCompare.build_difference_report(short, short).is_empty())
	print("✓ MDL invalid bytes fallback passed")


func _test_pipeline_wiring() -> void:
	var base := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var mod := _build_minimal_mdl(
		[
			Vector3(0.0, 0.0, 0.0),
			Vector3(2.0, 0.0, 0.0),
			Vector3(0.0, 2.0, 0.0),
			Vector3(1.0, 1.0, 0.0),
		],
		[0, 1, 2]
	)
	var report := KotorModdingPipeline._build_difference_report("mdl", base, mod)
	assert(not report.is_empty())
	assert(report.find("MDL differs") >= 0)
	assert(report.find("vertices:") >= 0)
	print("✓ MDL pipeline wiring passed")


func _test_gamefs_mdx_pairing() -> void:
	var install_root := _make_install_root()
	var mdl := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var base_mdx := PackedByteArray([0x01, 0x02])
	var mod_mdx := PackedByteArray([0x01, 0x02, 0x03])

	var modules_dir := install_root.path_join("modules")
	DirAccess.make_dir_recursive_absolute(modules_dir)
	var module_bytes := ERFWriter.build("MOD ", [
		{"resref": "room_a", "extension": "mdl", "bytes": mdl},
		{"resref": "room_a", "extension": "mdx", "bytes": base_mdx},
	])
	_write_file(modules_dir.path_join("roomcore.mod"), module_bytes)

	var override_dir := install_root.path_join("override")
	_write_file(override_dir.path_join("room_a.mdl"), mdl)
	_write_file(override_dir.path_join("room_a.mdx"), mod_mdx)

	var editor_state := KotorEditorState.new()
	editor_state.game_path = install_root
	editor_state.refresh_gamefs()
	var result := KotorModdingPipeline.compare_gamefs_resource(editor_state.gamefs, "room_a", "mdl")
	assert(result.get("ok", false))
	assert(str(result.get("status", "")) == "different")
	var details := str(result.get("details", ""))
	assert(details.find("MDX size: 2 -> 3 B") >= 0)
	_cleanup(install_root)
	print("✓ MDL GameFS MDX pairing passed")


func _make_install_root() -> String:
	_install_counter += 1
	var install_root := ProjectSettings.globalize_path(
		"user://mdl_compare_install_%d_%d" % [_install_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(install_root.path_join("override"))
	return install_root


func _write_file(path: String, bytes: PackedByteArray) -> void:
	var parent := path.get_base_dir()
	if not parent.is_empty():
		DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Failed to open %s for write" % path)
	file.store_buffer(bytes)
	file.close()


func _cleanup(path: String) -> void:
	_remove_dir_recursive(path)


func _remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		var child := path.path_join(name)
		if dir.current_is_dir():
			_remove_dir_recursive(child)
		else:
			DirAccess.remove_absolute(child)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


static func _build_minimal_mdl(vertices: Array, face_indices: Array) -> PackedByteArray:
	assert(vertices.size() >= 3)
	assert(face_indices.size() == 3)

	const DATA_OFFSET := 12
	const MODEL_HEADER_SIZE := 196
	const NODE_HEADER_SIZE := 80
	const TRIMESH_HEADER_K1_SIZE := 332
	const FACE_SIZE := 32

	var node_offset := MODEL_HEADER_SIZE
	var trimesh_offset := node_offset + NODE_HEADER_SIZE
	var vertices_offset := trimesh_offset + TRIMESH_HEADER_K1_SIZE
	var faces_offset := vertices_offset + vertices.size() * 12
	var total_data_size := faces_offset + FACE_SIZE

	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.resize(DATA_OFFSET + total_data_size)

	stream.seek(DATA_OFFSET)
	stream.put_u32(MDLParser.K1_GEOMETRY_TOKEN0)
	stream.put_u32(MDLParser.K1_GEOMETRY_TOKEN1)
	_write_fixed_string(stream, "testmdl", 32)
	stream.put_u32(node_offset)
	stream.seek(DATA_OFFSET + MODEL_HEADER_SIZE)

	stream.seek(DATA_OFFSET + node_offset)
	stream.put_u16(MDLParser.FLAG_HEADER | MDLParser.FLAG_MESH)
	stream.put_u16(0)
	stream.put_u16(0)
	stream.put_u16(0)
	stream.put_u32(node_offset)
	stream.put_u32(0xFFFFFFFF)
	_write_vector3(stream, Vector3.ZERO)
	stream.put_float(1.0)
	stream.put_float(0.0)
	stream.put_float(0.0)
	stream.put_float(0.0)
	for _i in range(9):
		stream.put_u32(0)

	stream.seek(DATA_OFFSET + trimesh_offset)
	stream.put_u32(MDLParser.K1_TRIMESH_TOKEN0)
	stream.put_u32(MDLParser.K1_TRIMESH_TOKEN1)
	stream.put_u32(faces_offset)
	stream.put_u32(1)
	stream.put_u32(1)
	_write_vector3(stream, Vector3.ZERO)
	_write_vector3(stream, Vector3.ZERO)
	stream.put_float(0.0)
	_write_vector3(stream, Vector3.ZERO)
	_write_vector3(stream, Vector3.ZERO)
	_write_vector3(stream, Vector3.ZERO)
	stream.put_u32(0)
	stream.seek(stream.get_position() + 64)
	stream.seek(stream.get_position() + 24)
	stream.seek(stream.get_position() + 36)
	stream.seek(stream.get_position() + 12)
	stream.seek(stream.get_position() + 8)
	stream.put_u32(0)
	for _i in range(4):
		stream.put_float(0.0)
	stream.put_u32(0)
	stream.put_u32(0)
	stream.put_u32(0)
	stream.seek(stream.get_position() + 40)
	stream.put_u16(vertices.size())
	stream.put_u16(0)
	stream.seek(stream.get_position() + 6)
	stream.put_u16(0)
	stream.put_float(0.0)
	stream.put_u32(0)
	stream.put_u32(0)
	stream.put_u32(vertices_offset)

	stream.seek(DATA_OFFSET + vertices_offset)
	for vertex in vertices:
		_write_vector3(stream, vertex)

	stream.seek(DATA_OFFSET + faces_offset)
	_write_vector3(stream, Vector3(0.0, 1.0, 0.0))
	stream.put_float(0.0)
	stream.put_u32(0)
	stream.put_u16(0xFFFF)
	stream.put_u16(0xFFFF)
	stream.put_u16(0xFFFF)
	stream.put_u16(face_indices[0])
	stream.put_u16(face_indices[1])
	stream.put_u16(face_indices[2])

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
