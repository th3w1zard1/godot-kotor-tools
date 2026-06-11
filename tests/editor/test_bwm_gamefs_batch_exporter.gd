@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorResourceBrowserPanel := preload("../../ui/workspace/panels/resource_browser_panel.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const BWMWriter := preload("../../formats/bwm_writer.gd")
const BwmGamefsBatchExporter := preload("../../formats/bwm_gamefs_batch_exporter.gd")
const BwmMetadataHelper := preload("../../editor/tools/bwm_metadata_helper.gd")

var _install_counter := 0
var _output_counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_metadata_helper()
	_test_batch_install_dry_run()
	_test_batch_install_writes_wok()
	_test_skip_existing()
	var button_ok := await _test_resource_browser_batch_wok_button()
	if not button_ok:
		push_error("Resource browser batch WOK export button test failed")
		quit(1)
	var module_button_ok := await _test_module_designer_batch_export_install_button()
	if not module_button_ok:
		push_error("Module Designer batch WOK export install button test failed")
		quit(1)
	print("✓ BWM GameFS batch exporter tests passed")
	quit()


func _test_metadata_helper() -> void:
	var wok_bytes := _build_minimal_wok(
		[Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 3.0, 0.0)],
		[0, 1, 2],
		[1]
	)
	var metadata := BwmMetadataHelper.summarize_bytes(wok_bytes)
	assert(metadata.get("ok", false))
	assert(int(metadata.get("vertex_count", 0)) == 3)
	assert(int(metadata.get("face_count", 0)) == 1)
	assert(int(metadata.get("walkable_face_count", 0)) == 1)
	assert(BwmMetadataHelper.format_summary(metadata).contains("3 vertices"))
	print("✓ BWM metadata helper passed")


func _test_batch_install_dry_run() -> void:
	var install_root := _make_install_root()
	var output_root := _make_output_root()
	DirAccess.make_dir_recursive_absolute(output_root)
	_seed_install_walkmeshes(install_root)
	var gamefs := _build_gamefs(install_root)
	var result := BwmGamefsBatchExporter.batch_install(gamefs, output_root, {
		"dry_run": true,
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	_cleanup(install_root)
	_cleanup(output_root)
	print("✓ GameFS batch WOK dry-run passed")


func _test_batch_install_writes_wok() -> void:
	var install_root := _make_install_root()
	var output_root := _make_output_root()
	DirAccess.make_dir_recursive_absolute(output_root)
	_seed_install_walkmeshes(install_root)
	var gamefs := _build_gamefs(install_root)
	var result := BwmGamefsBatchExporter.batch_install(gamefs, output_root, {})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	assert(FileAccess.file_exists(output_root.path_join("area_a.wok")))
	assert(FileAccess.file_exists(output_root.path_join("area_b.wok")))
	var first: Dictionary = generated[0]
	assert(first.has("vertex_count"))
	assert(first.has("walkable_face_count"))
	_cleanup(install_root)
	_cleanup(output_root)
	print("✓ GameFS batch WOK write passed")


func _test_skip_existing() -> void:
	var install_root := _make_install_root()
	var output_root := _make_output_root()
	DirAccess.make_dir_recursive_absolute(output_root)
	_seed_install_walkmeshes(install_root)
	_write_file(output_root.path_join("area_a.wok"), PackedByteArray([0x00]))

	var gamefs := _build_gamefs(install_root)
	var result := BwmGamefsBatchExporter.batch_install(gamefs, output_root, {
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(install_root)
	_cleanup(output_root)
	print("✓ GameFS batch WOK skip-existing passed")


func _test_resource_browser_batch_wok_button() -> bool:
	var panel := KotorResourceBrowserPanel.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(panel)
	await process_frame

	var button := _find_button(panel, "Batch Export Install WOK...")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ Resource browser batch WOK export button passed")
	return true


func _test_module_designer_batch_export_install_button() -> bool:
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var button := _find_button(editor, "Batch Export Install WOK...")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ Module Designer batch WOK export install button passed")
	return true


func _make_install_root() -> String:
	_install_counter += 1
	var install_root := ProjectSettings.globalize_path(
		"user://bwm_gamefs_batch_exporter_install_%d_%d" % [_install_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(install_root.path_join("override"))
	return install_root


func _make_output_root() -> String:
	_output_counter += 1
	return ProjectSettings.globalize_path(
		"user://bwm_gamefs_batch_exporter_output_%d_%d" % [_output_counter, Time.get_ticks_usec()]
	)


func _build_gamefs(install_root: String) -> RefCounted:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = install_root
	editor_state.refresh_gamefs()
	return editor_state.gamefs


func _seed_install_walkmeshes(install_root: String) -> void:
	var override_dir := install_root.path_join("override")
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
	_write_file(override_dir.path_join("area_a.wok"), wok_a)
	_write_file(override_dir.path_join("area_b.wok"), wok_b)


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
