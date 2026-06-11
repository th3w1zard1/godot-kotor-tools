@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")


var _test_root := ""


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_root = ProjectSettings.globalize_path("user://tpc_txi_editor_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_test_root)
	await _test_load_populates_txi_editor()
	await _test_apply_txi_text_updates_metadata()
	await _test_apply_empty_clears_txi()
	await _test_import_txi_from_file()
	await _test_export_txi_to_file()
	await _test_import_txi_missing_file()
	await _test_apply_txi_button()
	await _test_txi_file_buttons()
	_cleanup()
	print("✓ TPC TXI editor tests passed")
	quit()


func _test_load_populates_txi_editor() -> void:
	var editor := await _make_editor_with_txi_tpc("envmap\n")
	assert(editor.get_txi_text().contains("envmap"))
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC TXI editor load populate passed")


func _test_apply_txi_text_updates_metadata() -> void:
	var editor := await _make_editor_with_rgba_tpc()
	assert(editor.apply_txi_text("proceduretype cycle\n"))
	assert(editor.is_document_dirty())
	assert(int(editor.get("_metadata").get("txi_length", 0)) > 0)
	assert(editor.get_txi_text().contains("proceduretype"))
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC TXI apply update passed")


func _test_apply_empty_clears_txi() -> void:
	var editor := await _make_editor_with_txi_tpc("envmap\n")
	assert(editor.apply_txi_text(""))
	assert(int(editor.get("_metadata").get("txi_length", 0)) == 0)
	assert(editor.get_txi_text().is_empty())
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC TXI apply clear passed")


func _test_import_txi_from_file() -> void:
	var editor := await _make_editor_with_rgba_tpc()
	var txi_path := _test_root.path_join("imported.txi")
	_write_file(txi_path, "bumpmap\n".to_utf8_buffer())
	assert(editor.import_txi_from_file(txi_path))
	assert(editor.is_document_dirty())
	assert(editor.get_txi_text().contains("bumpmap"))
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC TXI import from file passed")


func _test_export_txi_to_file() -> void:
	var editor := await _make_editor_with_txi_tpc("envmap\nproceduretype cycle\n")
	var export_path := _test_root.path_join("exported.txi")
	assert(editor.export_txi_to_file(export_path))
	assert(FileAccess.file_exists(export_path))
	var file := FileAccess.open(export_path, FileAccess.READ)
	var exported := file.get_as_text()
	file.close()
	assert(exported.contains("envmap"))
	assert(exported.contains("proceduretype"))
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC TXI export to file passed")


func _test_import_txi_missing_file() -> void:
	var editor := await _make_editor_with_rgba_tpc()
	assert(not editor.import_txi_from_file(_test_root.path_join("missing.txi")))
	editor.get_parent().queue_free()
	await process_frame
	print("✓ TPC TXI import missing file passed")


func _test_apply_txi_button() -> void:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Apply TXI") != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC TXI apply button passed")


func _make_editor_with_rgba_tpc() -> KotorTPCWorkspaceEditor:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			image.set_pixel(x, y, Color8(255, 0, 0, 255))
	var bytes := TPCWriter.serialize_rgba(image)
	return await _spawn_editor(bytes)


func _make_editor_with_txi_tpc(txi_text: String) -> KotorTPCWorkspaceEditor:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			image.set_pixel(x, y, Color8(0, 255, 0, 255))
	var bytes := TPCWriter.serialize_rgba(image)
	bytes = TPCWriter.append_txi_bytes(bytes, txi_text.to_utf8_buffer())
	return await _spawn_editor(bytes)


func _spawn_editor(bytes: PackedByteArray) -> KotorTPCWorkspaceEditor:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	editor.open_tpc_bytes(bytes, "", "test.tpc")
	await process_frame
	return editor


func _test_txi_file_buttons() -> void:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Import TXI...") != null)
	assert(_find_button(editor, "Export TXI...") != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC TXI file buttons passed")


func _write_file(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


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
