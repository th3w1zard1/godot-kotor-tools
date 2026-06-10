@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const TpcGamefsBatchExporter := preload("../../formats/tpc_gamefs_batch_exporter.gd")

var _install_root := ""
var _output_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://tpc_gamefs_batch_exporter_install_%d" % Time.get_ticks_usec())
	_output_root = ProjectSettings.globalize_path("user://tpc_gamefs_batch_exporter_output_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	DirAccess.make_dir_recursive_absolute(_output_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	_seed_install_textures()
	_test_batch_install_dry_run()
	_test_skip_existing()
	var button_ok := await _test_tpc_editor_batch_install_export_button()
	_cleanup()
	if not button_ok:
		push_error("TPC editor install batch export button test failed")
		quit(1)
	print("✓ TPC GameFS batch exporter tests passed")
	quit()


func _test_batch_install_dry_run() -> void:
	var gamefs := _build_gamefs()
	var result := TpcGamefsBatchExporter.batch_install(gamefs, _output_root, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	print("✓ GameFS batch install dry-run passed")


func _test_skip_existing() -> void:
	var skip_output := _output_root.path_join("skip")
	DirAccess.make_dir_recursive_absolute(skip_output)
	_write_file(skip_output.path_join("tex_a.tga"), PackedByteArray([0x00]))

	var gamefs := _build_gamefs()
	var result := TpcGamefsBatchExporter.batch_install(gamefs, skip_output, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	print("✓ GameFS batch skip-existing passed")


func _test_tpc_editor_batch_install_export_button() -> bool:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var button := _find_button(editor, "Batch Export Install TGA...")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor install batch export button passed")
	return true


func _build_gamefs() -> RefCounted:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	return editor_state.gamefs


func _seed_install_textures() -> void:
	var override_dir := _install_root.path_join("override")
	_write_tpc(override_dir.path_join("tex_a.tpc"))
	_write_tpc(override_dir.path_join("tex_b.tpc"))


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
	_remove_dir_recursive(_output_root)
	_remove_dir_recursive(_install_root)
	var temp_dir := ProjectSettings.globalize_path("user://kotor_tools/tmp/gamefs_batch")
	if DirAccess.dir_exists_absolute(temp_dir):
		_remove_dir_recursive(temp_dir)


func _remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
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
