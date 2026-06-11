@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const TpcBatchConverter := preload("../../formats/tpc_batch_converter.gd")
const KotorTPCWorkspaceEditor := preload("../../ui/workspace/editors/tpc_workspace_editor.gd")

var _test_root := ""


func _initialize() -> void:
	_test_root = ProjectSettings.globalize_path("user://tpc_batch_converter_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_test_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_convert_from_png_file()
	_test_convert_from_png_dxt1()
	_test_convert_from_png_dxt3()
	_test_convert_from_png_with_txi_sidecar()
	_test_convert_skips_txi_when_disabled()
	_test_batch_directory_dxt3()
	_test_batch_directory_dxt5()
	_test_invalid_image_rejected()
	_test_batch_directory()
	_test_batch_directory_with_txi_sidecar()
	_test_batch_directory_to_output()
	var button_ok := await _test_tpc_editor_batch_buttons()
	_cleanup()
	if not button_ok:
		push_error("TPC editor batch convert button test failed")
		quit(1)
	print("✓ TPC batch converter tests passed")
	quit()


func _test_convert_from_png_file() -> void:
	var png_path := _test_root.path_join("icon.png")
	_write_png(png_path, 32, 16)

	var result := TpcBatchConverter.convert_from_image_file(png_path)
	assert(result.get("ok", false))

	var bytes: PackedByteArray = result.get("bytes", PackedByteArray())
	assert(not bytes.is_empty())

	var metadata := TPCReader.read_metadata(bytes)
	assert(metadata.get("ok", false))
	assert(int(metadata.get("width", 0)) == 32)
	assert(int(metadata.get("height", 0)) == 16)
	print("✓ TPC convert from PNG file passed")


func _test_convert_from_png_with_txi_sidecar() -> void:
	var png_path := _test_root.path_join("sidecar.png")
	_write_png(png_path, 16, 16)
	var txi_text := "envmap\nproceduretype cycle\n"
	_write_file(_test_root.path_join("sidecar.txi"), txi_text.to_utf8_buffer())

	var result := TpcBatchConverter.convert_from_image_file(png_path)
	assert(result.get("ok", false))
	assert(result.get("txi_attached", false))

	var bytes: PackedByteArray = result.get("bytes", PackedByteArray())
	var metadata := TPCReader.read_metadata(bytes)
	assert(int(metadata.get("txi_length", 0)) == txi_text.to_utf8_buffer().size())
	assert(TPCWriter.read_txi_bytes(bytes) == txi_text.to_utf8_buffer())
	print("✓ TPC convert from PNG with TXI sidecar passed")


func _test_convert_skips_txi_when_disabled() -> void:
	var png_path := _test_root.path_join("no_txi.png")
	_write_png(png_path, 8, 8)
	_write_file(_test_root.path_join("no_txi.txi"), "envmap\n".to_utf8_buffer())

	var result := TpcBatchConverter.convert_from_image_file(png_path, {"include_txi_sidecar": false})
	assert(result.get("ok", false))
	assert(not result.get("txi_attached", true))

	var bytes: PackedByteArray = result.get("bytes", PackedByteArray())
	var metadata := TPCReader.read_metadata(bytes)
	assert(int(metadata.get("txi_length", 0)) == 0)
	print("✓ TPC convert skips TXI when disabled passed")


func _test_convert_from_png_dxt1() -> void:
	var png_path := _test_root.path_join("dxt1.png")
	_write_png(png_path, 16, 16)

	var result := TpcBatchConverter.convert_from_image_file(png_path, {"encoding": "dxt1"})
	assert(result.get("ok", false))

	var bytes: PackedByteArray = result.get("bytes", PackedByteArray())
	assert(not bytes.is_empty())

	var metadata := TPCReader.read_metadata(bytes)
	assert(metadata.get("ok", false))
	assert(int(metadata.get("encoding", -1)) == TPCReader.ENC_DXT1)
	print("✓ TPC convert from PNG DXT1 passed")


func _test_convert_from_png_dxt3() -> void:
	var png_path := _test_root.path_join("dxt3.png")
	_write_png(png_path, 16, 16)

	var result := TpcBatchConverter.convert_from_image_file(png_path, {"encoding": "dxt3"})
	assert(result.get("ok", false))

	var bytes: PackedByteArray = result.get("bytes", PackedByteArray())
	assert(not bytes.is_empty())

	var metadata := TPCReader.read_metadata(bytes)
	assert(metadata.get("ok", false))
	assert(int(metadata.get("encoding", -1)) == TPCReader.ENC_DXT3)
	print("✓ TPC convert from PNG DXT3 passed")


func _test_batch_directory_dxt3() -> void:
	var batch_dir := _test_root.path_join("batch_dxt3")
	DirAccess.make_dir_recursive_absolute(batch_dir)

	_write_png(batch_dir.path_join("tex_dxt3.png"), 8, 8)

	var batch := TpcBatchConverter.batch_directory(batch_dir, {"encoding": "dxt3"})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 1)

	var tpc_path := batch_dir.path_join("tex_dxt3.tpc")
	assert(FileAccess.file_exists(tpc_path))

	var file := FileAccess.open(tpc_path, FileAccess.READ)
	var metadata := TPCReader.read_metadata(file.get_buffer(file.get_length()))
	file.close()
	assert(metadata.get("ok", false))
	assert(int(metadata.get("encoding", -1)) == TPCReader.ENC_DXT3)
	print("✓ TPC batch directory DXT3 passed")


func _test_batch_directory_dxt5() -> void:
	var batch_dir := _test_root.path_join("batch_dxt5")
	DirAccess.make_dir_recursive_absolute(batch_dir)

	_write_png(batch_dir.path_join("tex_dxt5.png"), 8, 8)

	var batch := TpcBatchConverter.batch_directory(batch_dir, {"encoding": "dxt5"})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 1)

	var tpc_path := batch_dir.path_join("tex_dxt5.tpc")
	assert(FileAccess.file_exists(tpc_path))

	var file := FileAccess.open(tpc_path, FileAccess.READ)
	var metadata := TPCReader.read_metadata(file.get_buffer(file.get_length()))
	file.close()
	assert(metadata.get("ok", false))
	assert(int(metadata.get("encoding", -1)) == TPCReader.ENC_DXT5)
	print("✓ TPC batch directory DXT5 passed")


func _test_invalid_image_rejected() -> void:
	var bad_path := _test_root.path_join("not_image.png")
	_write_file(bad_path, PackedByteArray([0x00, 0x01, 0x02]))

	var result := TpcBatchConverter.convert_from_image_file(bad_path)
	assert(not result.get("ok", true))
	assert(str(result.get("message", "")) != "")
	print("✓ TPC invalid image rejection passed")


func _test_batch_directory_with_txi_sidecar() -> void:
	var batch_dir := _test_root.path_join("batch_txi")
	DirAccess.make_dir_recursive_absolute(batch_dir)

	_write_png(batch_dir.path_join("tex_txi.png"), 8, 8)
	_write_file(batch_dir.path_join("tex_txi.txi"), "bumpmap\n".to_utf8_buffer())

	var batch := TpcBatchConverter.batch_directory(batch_dir)
	assert(batch.get("ok", false))
	assert(int((batch.get("generated", []) as Array).size()) == 1)

	var tpc_path := batch_dir.path_join("tex_txi.tpc")
	var file := FileAccess.open(tpc_path, FileAccess.READ)
	var metadata := TPCReader.read_metadata(file.get_buffer(file.get_length()))
	file.close()
	assert(int(metadata.get("txi_length", 0)) > 0)
	print("✓ TPC batch directory with TXI sidecar passed")


func _test_batch_directory_to_output() -> void:
	var source_dir := _test_root.path_join("import_source")
	var output_dir := _test_root.path_join("import_output")
	DirAccess.make_dir_recursive_absolute(source_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)

	_write_png(source_dir.path_join("tex_out.png"), 8, 8)

	var batch := TpcBatchConverter.batch_directory_to_output(source_dir, output_dir)
	assert(batch.get("ok", false))
	assert(int((batch.get("generated", []) as Array).size()) == 1)
	assert(FileAccess.file_exists(output_dir.path_join("tex_out.tpc")))
	assert(not FileAccess.file_exists(source_dir.path_join("tex_out.tpc")))
	print("✓ TPC batch directory to output passed")


func _test_batch_directory() -> void:
	var batch_dir := _test_root.path_join("batch")
	DirAccess.make_dir_recursive_absolute(batch_dir)

	_write_png(batch_dir.path_join("tex_a.png"), 8, 8)
	_write_png(batch_dir.path_join("tex_b.png"), 4, 4)

	var batch := TpcBatchConverter.batch_directory(batch_dir)
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 2)
	assert(FileAccess.file_exists(batch_dir.path_join("tex_a.tpc")))
	assert(FileAccess.file_exists(batch_dir.path_join("tex_b.tpc")))

	var reskip := TpcBatchConverter.batch_directory(batch_dir, {"skip_existing": true})
	var skipped: Array = reskip.get("skipped", [])
	assert(skipped.size() == 2)
	print("✓ TPC batch directory passed")


func _test_tpc_editor_batch_buttons() -> bool:
	var editor := KotorTPCWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	assert(_find_button(editor, "Batch Convert TGA/PNG→TPC...") != null)
	assert(_find_button(editor, "Batch Convert DXT1...") != null)
	assert(_find_button(editor, "Batch Convert DXT3...") != null)
	assert(_find_button(editor, "Batch Convert DXT5...") != null)
	holder.queue_free()
	await process_frame
	print("✓ TPC editor batch convert buttons passed")
	return true


func _write_png(path: String, width: int, height: int) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.8, 1.0))
	var save_error := image.save_png(path)
	assert(save_error == OK)


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
