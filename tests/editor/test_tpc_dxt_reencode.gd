@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


var _test_root := ""


func _run_tests() -> void:
	_test_root = ProjectSettings.globalize_path("user://tpc_dxt_import_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_test_root)
	await _test_reencode_dxt1()
	await _test_reencode_dxt5()
	await _test_import_image_as_dxt1()
	await _test_import_image_as_dxt5()
	await _test_reencode_toolbar_buttons()
	_cleanup()
	print("✓ TPC DXT re-encode tests passed")
	quit()


func _test_reencode_dxt1() -> void:
	var editor := await _make_editor_with_rgba_tpc()
	var ok := editor.reencode_loaded_as_dxt1()
	assert(ok)
	assert(editor.is_document_dirty())
	assert(int(editor.get("_metadata").get("encoding", 0)) == TPCReader.ENC_DXT1)
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC editor DXT1 re-encode passed")


func _test_reencode_dxt5() -> void:
	var editor := await _make_editor_with_rgba_tpc()
	var ok := editor.reencode_loaded_as_dxt5()
	assert(ok)
	assert(editor.is_document_dirty())
	assert(int(editor.get("_metadata").get("encoding", 0)) == TPCReader.ENC_DXT5)
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC editor DXT5 re-encode passed")


func _test_import_image_as_dxt1() -> void:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var png_path := _test_root.path_join("import_dxt1.png")
	_write_png(png_path, 16, 16)
	var ok := editor.load_image_as_dxt1(png_path)
	assert(ok)
	assert(editor.is_document_dirty())
	assert(int(editor.get("_metadata").get("encoding", 0)) == TPCReader.ENC_DXT1)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor import image as DXT1 passed")


func _test_import_image_as_dxt5() -> void:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var png_path := _test_root.path_join("import_dxt5.png")
	_write_png(png_path, 8, 8)
	var ok := editor.load_image_as_dxt5(png_path)
	assert(ok)
	assert(editor.is_document_dirty())
	assert(int(editor.get("_metadata").get("encoding", 0)) == TPCReader.ENC_DXT5)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor import image as DXT5 passed")


func _test_reencode_toolbar_buttons() -> void:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Re-encode DXT1...") != null)
	assert(_find_button(editor, "Re-encode DXT5...") != null)
	assert(_find_button(editor, "Import TGA/PNG as DXT1...") != null)
	assert(_find_button(editor, "Import TGA/PNG as DXT5...") != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor DXT re-encode toolbar passed")


func _make_editor_with_rgba_tpc() -> KotorTPCWorkspaceEditor:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			image.set_pixel(x, y, Color(float(x) / 7.0, 0.3, 0.6, 1.0))
	var bytes := TPCWriter.serialize_rgba(image)
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	editor.open_tpc_bytes(bytes, "", "test.tpc")
	await process_frame
	return editor


func _write_png(path: String, width: int, height: int) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.8, 1.0))
	assert(image.save_png(path) == OK)


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(_test_root):
		_remove_dir_recursive(_test_root)


func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry == "." or entry == "..":
			continue
		var full := path.path_join(entry)
		if dir.current_is_dir():
			_remove_dir_recursive(full)
		elif FileAccess.file_exists(full):
			DirAccess.remove_absolute(full)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null
