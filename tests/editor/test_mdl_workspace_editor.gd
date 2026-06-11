@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorMDLWorkspaceEditor := preload("../../ui/workspace/editors/mdl_workspace_editor.gd")
const KotorResourceLocator := preload("../../editor/navigation/kotor_resource_locator.gd")
const MDLParser := preload("../../formats/mdl_parser.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://mdl_workspace_editor_install_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_open_valid_mdl_bytes()
	await _test_invalid_mdl_bytes()
	await _test_mdx_button_visibility()
	_test_resource_locator_mdl_metadata()
	var button_ok := await _test_mdl_editor_toolbar_buttons()
	_cleanup()
	if not button_ok:
		push_error("MDL workspace editor toolbar test failed")
		quit(1)
	print("✓ MDL workspace editor tests passed")
	quit()


func _test_open_valid_mdl_bytes() -> void:
	var editor := KotorMDLWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var mdl_bytes := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	editor.open_mdl_bytes(mdl_bytes, "", "room_a.mdl", PackedByteArray([0x01]))
	await process_frame

	var meta_label: RichTextLabel = editor.get_node_or_null("RichTextLabel") as RichTextLabel
	if meta_label == null:
		for child in editor.get_children():
			if child is RichTextLabel:
				meta_label = child
				break
	assert(meta_label != null)
	assert(meta_label.text.contains("Vertices"))
	assert(meta_label.text.contains("3"))
	holder.queue_free()
	await process_frame
	print("✓ MDL editor open valid bytes passed")


func _test_invalid_mdl_bytes() -> void:
	var editor := KotorMDLWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	editor.open_mdl_bytes("bad".to_utf8_buffer())
	await process_frame

	var meta_label: RichTextLabel = _find_meta_label(editor)
	assert(meta_label != null)
	assert(meta_label.text.to_lower().contains("invalid") or meta_label.text.to_lower().contains("failed"))
	holder.queue_free()
	await process_frame
	print("✓ MDL editor invalid bytes passed")


func _test_mdx_button_visibility() -> void:
	var editor := KotorMDLWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var mdl_bytes := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0)],
		[0, 1, 2]
	)
	editor.open_mdl_bytes(mdl_bytes, "", "test.mdl")
	await process_frame
	var export_mdx := _find_button(editor, "Export MDX...")
	assert(export_mdx != null)
	assert(not export_mdx.visible)

	editor.open_mdl_bytes(mdl_bytes, "", "test.mdl", PackedByteArray([0xAA]))
	await process_frame
	assert(export_mdx.visible)
	holder.queue_free()
	await process_frame
	print("✓ MDL editor MDX button visibility passed")


func _test_resource_locator_mdl_metadata() -> void:
	_seed_override_model()
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var gamefs := editor_state.gamefs
	var entries: Array = gamefs.list_core_resources("", "mdl", "override", 1)
	assert(entries.size() == 1)
	var entry: Dictionary = entries[0]
	var base := KotorResourceLocator.build_entry_details(entry, [])
	var enriched := KotorResourceLocator.append_mdl_metadata_details(base, entry, gamefs)
	assert(enriched.contains("vertices"))
	print("✓ Resource locator MDL metadata passed")


func _test_mdl_editor_toolbar_buttons() -> bool:
	var editor := KotorMDLWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	assert(_find_button(editor, "Open MDL...") != null)
	assert(_find_button(editor, "Export MDL...") != null)
	assert(_find_button(editor, "Install MDL to Override") != null)
	holder.queue_free()
	await process_frame
	print("✓ MDL editor toolbar buttons passed")
	return true


func _seed_override_model() -> void:
	var mdl_bytes := _build_minimal_mdl(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2]
	)
	var path := _install_root.path_join("override").path_join("room_a.mdl")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(mdl_bytes)
	file.close()


func _find_meta_label(editor: Node) -> RichTextLabel:
	for child in editor.get_children():
		if child is RichTextLabel:
			return child
	return null


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _cleanup() -> void:
	_remove_dir_recursive(_install_root)


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
