@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_load_populates_txi_editor()
	await _test_apply_txi_text_updates_metadata()
	await _test_apply_empty_clears_txi()
	await _test_apply_txi_button()
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


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null
