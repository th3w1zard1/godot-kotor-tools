@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorMDLWorkspaceEditor := preload("../../ui/workspace/editors/mdl_workspace_editor.gd")
const MDLParser := preload("../../formats/mdl_parser.gd")
const MdlGamefsBatchImporter := preload("../../formats/mdl_gamefs_batch_importer.gd")

var _install_counter := 0
var _source_counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_folder_import_dry_run()
	_test_batch_folder_import_writes_override()
	_test_skip_existing()
	_test_batch_folder_import_recursive()
	var button_ok := await _test_mdl_editor_batch_import_button()
	if not button_ok:
		push_error("MDL GameFS batch importer toolbar test failed")
		quit(1)
	print("✓ MDL GameFS batch importer tests passed")
	quit()


func _test_batch_folder_import_dry_run() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_models(source_root)
	var gamefs := _build_gamefs(install_root)

	var result := MdlGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"dry_run": true,
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	assert(str(result.get("summary", "")).contains("Install batch MDL import"))
	assert(not FileAccess.file_exists(install_root.path_join("override").path_join("room_a.mdl")))
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch MDL import dry-run passed")


func _test_batch_folder_import_writes_override() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_models(source_root)
	var gamefs := _build_gamefs(install_root)

	var result := MdlGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	var override_dir := install_root.path_join("override")
	assert(FileAccess.file_exists(override_dir.path_join("room_a.mdl")))
	assert(FileAccess.file_exists(override_dir.path_join("room_b.mdl")))
	assert(FileAccess.file_exists(override_dir.path_join("room_a.mdx")))
	var first: Dictionary = generated[0]
	assert(first.has("vertex_count"))
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch MDL import write passed")


func _test_skip_existing() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_models(source_root)
	_write_file(install_root.path_join("override").path_join("room_a.mdl"), PackedByteArray([0x00]))
	var gamefs := _build_gamefs(install_root)

	var result := MdlGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch MDL import skip-existing passed")


func _test_batch_folder_import_recursive() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	var nested := source_root.path_join("nested")
	DirAccess.make_dir_recursive_absolute(nested)
	var mdl_root := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var mdl_nested := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)],
		[0, 1, 2]
	)
	_write_file(source_root.path_join("root.mdl"), mdl_root)
	_write_file(nested.path_join("nested.mdl"), mdl_nested)
	_write_file(nested.path_join("nested.mdx"), PackedByteArray([0x01, 0x02]))
	var gamefs := _build_gamefs(install_root)

	var result := MdlGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"recursive": true,
	})
	assert(result.get("ok", false))
	var override_dir := install_root.path_join("override")
	assert(FileAccess.file_exists(override_dir.path_join("root.mdl")))
	assert(FileAccess.file_exists(override_dir.path_join("nested.mdl")))
	assert(FileAccess.file_exists(override_dir.path_join("nested.mdx")))
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch MDL folder import recursive passed")


func _test_mdl_editor_batch_import_button() -> bool:
	var editor := KotorMDLWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Batch Import MDL Folder to Override...") != null)
	holder.queue_free()
	await process_frame
	print("✓ MDL editor batch import button passed")
	return true


func _make_install_root() -> String:
	_install_counter += 1
	var install_root := ProjectSettings.globalize_path(
		"user://mdl_gamefs_batch_importer_install_%d_%d" % [_install_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(install_root.path_join("override"))
	return install_root


func _make_source_root() -> String:
	_source_counter += 1
	var source_root := ProjectSettings.globalize_path(
		"user://mdl_gamefs_batch_importer_source_%d_%d" % [_source_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(source_root)
	return source_root


func _build_gamefs(install_root: String) -> RefCounted:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = install_root
	editor_state.refresh_gamefs()
	return editor_state.gamefs


func _seed_models(source_root: String) -> void:
	var mdl_a := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var mdl_b := _build_minimal_mdl(
		[Vector3(1.0, 0.0, 0.0), Vector3(3.0, 0.0, 0.0), Vector3(1.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	_write_file(source_root.path_join("room_a.mdl"), mdl_a)
	_write_file(source_root.path_join("room_a.mdx"), PackedByteArray([0x01, 0x02]))
	_write_file(source_root.path_join("room_b.mdl"), mdl_b)


func _write_file(path: String, bytes: PackedByteArray) -> void:
	var parent := path.get_base_dir()
	if not parent.is_empty():
		DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Failed to open %s for write" % path)
	file.store_buffer(bytes)
	file.close()


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


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
	assert(vertices.size() == 3)
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
