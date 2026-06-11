@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const BWMWriter := preload("../../formats/bwm_writer.gd")
const BwmGamefsBatchImporter := preload("../../formats/bwm_gamefs_batch_importer.gd")

var _install_counter := 0
var _source_counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_folder_import_dry_run()
	_test_batch_folder_import_writes_override()
	_test_skip_existing()
	var button_ok := await _test_module_designer_batch_import_button()
	if not button_ok:
		push_error("BWM GameFS batch importer toolbar test failed")
		quit(1)
	print("✓ BWM GameFS batch importer tests passed")
	quit()


func _test_batch_folder_import_dry_run() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_walkmeshes(source_root)
	var gamefs := _build_gamefs(install_root)

	var result := BwmGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"dry_run": true,
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	assert(str(result.get("summary", "")).contains("Install batch WOK import"))
	assert(not FileAccess.file_exists(install_root.path_join("override").path_join("area_a.wok")))
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch WOK import dry-run passed")


func _test_batch_folder_import_writes_override() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_walkmeshes(source_root)
	var gamefs := _build_gamefs(install_root)

	var result := BwmGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	var override_dir := install_root.path_join("override")
	assert(FileAccess.file_exists(override_dir.path_join("area_a.wok")))
	assert(FileAccess.file_exists(override_dir.path_join("area_b.wok")))
	var first: Dictionary = generated[0]
	assert(first.has("vertex_count"))
	assert(first.has("walkable_face_count"))
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch WOK import write passed")


func _test_skip_existing() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_walkmeshes(source_root)
	_write_file(install_root.path_join("override").path_join("area_a.wok"), PackedByteArray([0x00]))
	var gamefs := _build_gamefs(install_root)

	var result := BwmGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch WOK import skip-existing passed")


func _test_module_designer_batch_import_button() -> bool:
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Batch Import WOK Folder to Override...") != null)
	holder.queue_free()
	await process_frame
	print("✓ Module Designer batch import WOK button passed")
	return true


func _make_install_root() -> String:
	_install_counter += 1
	var install_root := ProjectSettings.globalize_path(
		"user://bwm_gamefs_batch_importer_install_%d_%d" % [_install_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(install_root.path_join("override"))
	return install_root


func _make_source_root() -> String:
	_source_counter += 1
	return ProjectSettings.globalize_path(
		"user://bwm_gamefs_batch_importer_source_%d_%d" % [_source_counter, Time.get_ticks_usec()]
	)


func _build_gamefs(install_root: String) -> RefCounted:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = install_root
	editor_state.refresh_gamefs()
	return editor_state.gamefs


func _seed_walkmeshes(source_root: String) -> void:
	DirAccess.make_dir_recursive_absolute(source_root)
	var wok_a := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var wok_b := _build_minimal_wok(
		[Vector3(1.0, 0.0, 0.0), Vector3(3.0, 0.0, 0.0), Vector3(1.0, 2.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	_write_file(source_root.path_join("area_a.wok"), wok_a)
	_write_file(source_root.path_join("area_b.wok"), wok_b)


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


static func _build_minimal_wok(vertices: Array, face_indices: Array, materials: Array) -> PackedByteArray:
	return BWMWriter.build_minimal(vertices, face_indices, materials)
