@tool
extends SceneTree

const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const TpcBatchExporter := preload("../../formats/tpc_batch_exporter.gd")

var _test_root := ""


func _initialize() -> void:
	_test_root = ProjectSettings.globalize_path("user://tpc_batch_exporter_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_test_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_directory_dry_run()
	_test_skip_existing()
	var button_ok := await _test_tpc_editor_batch_export_button()
	_cleanup()
	if not button_ok:
		push_error("TPC editor batch export button test failed")
		quit(1)
	print("✓ TPC batch exporter tests passed")
	quit()


func _test_batch_directory_dry_run() -> void:
	var batch_dir := _test_root.path_join("batch")
	DirAccess.make_dir_recursive_absolute(batch_dir)
	_write_tpc(batch_dir.path_join("tex_a.tpc"))
	_write_tpc(batch_dir.path_join("tex_b.tpc"))

	var batch := TpcBatchExporter.batch_directory(batch_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
	})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 2)
	print("✓ TPC batch directory dry-run passed")


func _test_skip_existing() -> void:
	var batch_dir := _test_root.path_join("skip")
	DirAccess.make_dir_recursive_absolute(batch_dir)
	_write_tpc(batch_dir.path_join("tex_a.tpc"))
	_write_file(batch_dir.path_join("tex_a.tga"), PackedByteArray([0x00]))

	var batch := TpcBatchExporter.batch_directory(batch_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"skip_existing": true,
	})
	var skipped: Array = batch.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = batch.get("generated", [])
	assert(generated.is_empty())
	print("✓ TPC batch skip-existing passed")


func _test_tpc_editor_batch_export_button() -> bool:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var button := _find_button(editor, "Batch Export TGA...")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor batch export button passed")
	return true


func _write_tpc(path: String) -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 0.5, 1.0))
	var bytes := TPCWriter.serialize_rgba(image)
	assert(not bytes.is_empty())
	_write_file(path, bytes)


func _write_file(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
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
