@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const TPCReader := preload("../../formats/tpc_reader.gd")
const TpcGamefsBatchImporter := preload("../../formats/tpc_gamefs_batch_importer.gd")

var _install_counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_install_dry_run()
	_test_batch_install_writes_tpc()
	_test_skip_existing()
	var button_ok := await _test_tpc_editor_batch_install_import_button()
	if not button_ok:
		push_error("TPC editor install batch import button test failed")
		quit(1)
	print("✓ TPC GameFS batch importer tests passed")
	quit()


func _test_batch_install_dry_run() -> void:
	var install_root := _make_install_root()
	_seed_install_images(install_root)
	var gamefs := _build_gamefs(install_root)
	var result := TpcGamefsBatchImporter.batch_install_to_override(gamefs, {
		"dry_run": true,
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	_cleanup(install_root)
	print("✓ GameFS batch install import dry-run passed")


func _test_batch_install_writes_tpc() -> void:
	var install_root := _make_install_root()
	_seed_install_images(install_root)
	var gamefs := _build_gamefs(install_root)
	var result := TpcGamefsBatchImporter.batch_install_to_override(gamefs, {})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)

	var override_dir := install_root.path_join("override")
	assert(FileAccess.file_exists(override_dir.path_join("tex_a.tpc")))
	assert(FileAccess.file_exists(override_dir.path_join("tex_b.tpc")))

	var metadata := TPCReader.read_metadata(FileAccess.get_file_as_bytes(override_dir.path_join("tex_a.tpc")))
	assert(metadata.get("ok", false))
	_cleanup(install_root)
	print("✓ GameFS batch install import write passed")


func _test_skip_existing() -> void:
	var install_root := _make_install_root()
	_seed_install_images(install_root)
	_write_tpc(install_root.path_join("override").path_join("tex_a.tpc"))

	var gamefs := _build_gamefs(install_root)
	var result := TpcGamefsBatchImporter.batch_install_to_override(gamefs, {
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(install_root)
	print("✓ GameFS batch import skip-existing passed")


func _test_tpc_editor_batch_install_import_button() -> bool:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var button := _find_button(editor, "Batch Import Install TGA/PNG→TPC...")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor install batch import button passed")
	return true


func _make_install_root() -> String:
	_install_counter += 1
	var install_root := ProjectSettings.globalize_path(
		"user://tpc_gamefs_batch_importer_install_%d_%d" % [_install_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(install_root.path_join("override"))
	return install_root


func _build_gamefs(install_root: String) -> RefCounted:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = install_root
	editor_state.refresh_gamefs()
	return editor_state.gamefs


func _seed_install_images(install_root: String) -> void:
	var override_dir := install_root.path_join("override")
	_write_image(override_dir.path_join("tex_a.png"), 8, 8)
	_write_image(override_dir.path_join("tex_b.png"), 4, 4)


func _write_image(path: String, width: int, height: int) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.6, 1.0))
	assert(image.save_png(path) == OK)


func _write_tpc(path: String) -> void:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var bytes := TPCWriter.serialize_rgba(image)
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
