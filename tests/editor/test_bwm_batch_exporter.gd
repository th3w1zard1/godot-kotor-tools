@tool
extends SceneTree

const BWMWriter := preload("../../formats/bwm_writer.gd")
const BwmBatchExporter := preload("../../formats/bwm_batch_exporter.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")

var _counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_directory_dry_run()
	_test_batch_directory_writes_wok()
	_test_skip_existing()
	var button_ok := await _test_module_designer_batch_copy_button()
	if not button_ok:
		push_error("BWM batch exporter toolbar test failed")
		quit(1)
	print("✓ BWM batch exporter tests passed")
	quit()


func _test_batch_directory_dry_run() -> void:
	var source_root := _make_dir("source")
	var output_root := _make_dir("output")
	_seed_walkmeshes(source_root)

	var result := BwmBatchExporter.batch_directory(source_root, output_root, {
		"dry_run": true,
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	_cleanup(source_root)
	_cleanup(output_root)
	print("✓ WOK folder batch dry-run passed")


func _test_batch_directory_writes_wok() -> void:
	var source_root := _make_dir("source")
	var output_root := _make_dir("output")
	_seed_walkmeshes(source_root)

	var result := BwmBatchExporter.batch_directory(source_root, output_root, {})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	assert(FileAccess.file_exists(output_root.path_join("area_a.wok")))
	assert(FileAccess.file_exists(output_root.path_join("area_b.wok")))
	var first: Dictionary = generated[0]
	assert(first.has("vertex_count"))
	assert(first.has("walkable_face_count"))
	assert(str(first.get("metadata_summary", "")).contains("vertices"))
	_cleanup(source_root)
	_cleanup(output_root)
	print("✓ WOK folder batch write passed")


func _test_skip_existing() -> void:
	var source_root := _make_dir("source")
	var output_root := _make_dir("output")
	_seed_walkmeshes(source_root)
	_write_file(output_root.path_join("area_a.wok"), PackedByteArray([0x00]))

	var result := BwmBatchExporter.batch_directory(source_root, output_root, {
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(source_root)
	_cleanup(output_root)
	print("✓ WOK folder batch skip-existing passed")


func _test_module_designer_batch_copy_button() -> bool:
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Batch Copy WOK Folder...") != null)
	holder.queue_free()
	await process_frame
	print("✓ Module Designer batch copy WOK button passed")
	return true


func _make_dir(label: String) -> String:
	_counter += 1
	var path := ProjectSettings.globalize_path(
		"user://bwm_batch_exporter_%s_%d_%d" % [label, _counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(path)
	return path


func _seed_walkmeshes(source_root: String) -> void:
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
