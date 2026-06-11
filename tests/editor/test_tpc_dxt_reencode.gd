@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_reencode_dxt1()
	await _test_reencode_dxt5()
	await _test_reencode_toolbar_buttons()
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


func _test_reencode_toolbar_buttons() -> void:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Re-encode DXT1...") != null)
	assert(_find_button(editor, "Re-encode DXT5...") != null)
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


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null
