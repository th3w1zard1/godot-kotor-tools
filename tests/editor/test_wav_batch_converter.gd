@tool
extends SceneTree

const KotorWAVWorkspaceEditor := preload("../../ui/workspace/editors/wav_workspace_editor.gd")
const WavBatchConverter := preload("../../formats/wav_batch_converter.gd")

var _test_root := ""


func _initialize() -> void:
	_test_root = ProjectSettings.globalize_path("user://wav_batch_converter_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_test_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_directory_dry_run()
	_test_batch_directory_to_output_dry_run()
	_test_skip_existing()
	_test_skip_clean_sources()
	_test_batch_directory_recursive_in_place()
	_test_batch_directory_to_output_recursive()
	var button_ok := await _test_wav_editor_batch_convert_button()
	_cleanup()
	if not button_ok:
		push_error("WAV editor batch convert button test failed")
		quit(1)
	print("✓ WAV batch converter tests passed")
	quit()


func _test_batch_directory_dry_run() -> void:
	var batch_dir := _test_root.path_join("batch")
	DirAccess.make_dir_recursive_absolute(batch_dir)
	_write_file(batch_dir.path_join("line01.wav"), _build_pcm_wav(8000, 1, 400))
	_write_file(batch_dir.path_join("line02.wav"), _build_pcm_wav(8000, 1, 800))

	var batch := WavBatchConverter.batch_directory(batch_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"sound_type": "VO",
	})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 2)
	var first: Dictionary = generated[0]
	assert(str(first.get("output_path", "")).ends_with("_clean.wav"))
	print("✓ WAV batch directory dry-run passed")


func _test_batch_directory_to_output_dry_run() -> void:
	var source_dir := _test_root.path_join("source")
	var output_dir := _test_root.path_join("output")
	DirAccess.make_dir_recursive_absolute(source_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	_write_file(source_dir.path_join("line01.wav"), _build_pcm_wav(8000, 1, 400))

	var batch := WavBatchConverter.batch_directory_to_output(source_dir, output_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"sound_type": "SFX",
	})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 1)
	var first: Dictionary = generated[0]
	var output_path := str(first.get("output_path", ""))
	assert(output_path.begins_with(output_dir))
	assert(output_path.ends_with("line01_clean.wav"))
	assert(not FileAccess.file_exists(output_path))
	print("✓ WAV batch directory-to-output dry-run passed")


func _test_skip_existing() -> void:
	var batch_dir := _test_root.path_join("skip")
	DirAccess.make_dir_recursive_absolute(batch_dir)
	_write_file(batch_dir.path_join("line01.wav"), _build_pcm_wav(8000, 1, 400))
	_write_file(batch_dir.path_join("line01_clean.wav"), PackedByteArray([0x00]))

	var batch := WavBatchConverter.batch_directory(batch_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"skip_existing": true,
	})
	var skipped: Array = batch.get("skipped", [])
	assert(skipped.size() == 1)
	assert((batch.get("generated", []) as Array).is_empty())
	print("✓ WAV batch skip-existing passed")


func _test_skip_clean_sources() -> void:
	var batch_dir := _test_root.path_join("clean_only")
	DirAccess.make_dir_recursive_absolute(batch_dir)
	_write_file(batch_dir.path_join("line01_clean.wav"), _build_pcm_wav(8000, 1, 400))

	var batch := WavBatchConverter.batch_directory(batch_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
	})
	assert((batch.get("generated", []) as Array).is_empty())
	assert((batch.get("skipped", []) as Array).is_empty())
	print("✓ WAV batch skip clean sources passed")


func _test_batch_directory_recursive_in_place() -> void:
	var batch_dir := _test_root.path_join("recursive_inplace")
	var nested := batch_dir.path_join("nested")
	DirAccess.make_dir_recursive_absolute(nested)
	_write_file(batch_dir.path_join("root.wav"), _build_pcm_wav(8000, 1, 400))
	_write_file(nested.path_join("nested.wav"), _build_pcm_wav(8000, 1, 800))

	var batch := WavBatchConverter.batch_directory(batch_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"recursive": true,
	})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 2)
	var paths: Array[String] = []
	for raw_record in generated:
		paths.append(str((raw_record as Dictionary).get("output_path", "")))
	assert(paths.has(batch_dir.path_join("root_clean.wav")))
	assert(paths.has(nested.path_join("nested_clean.wav")))
	print("✓ WAV batch directory recursive in-place passed")


func _test_batch_directory_to_output_recursive() -> void:
	var source_dir := _test_root.path_join("recursive_source")
	var output_dir := _test_root.path_join("recursive_output")
	var nested := source_dir.path_join("child")
	DirAccess.make_dir_recursive_absolute(nested)
	DirAccess.make_dir_recursive_absolute(output_dir)
	_write_file(source_dir.path_join("flat.wav"), _build_pcm_wav(8000, 1, 400))
	_write_file(nested.path_join("nested.wav"), _build_pcm_wav(8000, 1, 800))

	var batch := WavBatchConverter.batch_directory_to_output(source_dir, output_dir, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"recursive": true,
	})
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 2)
	var first: Dictionary = generated[0]
	assert(str(first.get("output_path", "")).begins_with(output_dir))
	print("✓ WAV batch directory-to-output recursive passed")


func _test_wav_editor_batch_convert_button() -> bool:
	var editor := KotorWAVWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	assert(_find_button(editor, "Batch Convert WAV...") != null)
	holder.queue_free()
	await process_frame
	print("✓ WAV editor batch convert button passed")
	return true


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


func _build_pcm_wav(sample_rate: int, channels: int, sample_count: int) -> PackedByteArray:
	var bits_per_sample := 16
	var block_align := channels * bits_per_sample / 8
	var data_size := sample_count * block_align
	var fmt_size := 16
	var riff_size := 4 + 8 + fmt_size + 8 + data_size
	var buffer := PackedByteArray()
	buffer.resize(44 + data_size)
	var offset := 0
	offset = _write_ascii(buffer, offset, "RIFF")
	buffer.encode_u32(offset, riff_size)
	offset += 4
	offset = _write_ascii(buffer, offset, "WAVE")
	offset = _write_ascii(buffer, offset, "fmt ")
	buffer.encode_u32(offset, fmt_size)
	offset += 4
	buffer.encode_u16(offset, 1)
	offset += 2
	buffer.encode_u16(offset, channels)
	offset += 2
	buffer.encode_u32(offset, sample_rate)
	offset += 4
	buffer.encode_u32(offset, sample_rate * block_align)
	offset += 4
	buffer.encode_u16(offset, block_align)
	offset += 2
	buffer.encode_u16(offset, bits_per_sample)
	offset += 2
	offset = _write_ascii(buffer, offset, "data")
	buffer.encode_u32(offset, data_size)
	offset += 4
	for index in data_size:
		buffer[offset + index] = 0
	return buffer


func _write_ascii(buffer: PackedByteArray, offset: int, text: String) -> int:
	var bytes := text.to_utf8_buffer()
	for index in bytes.size():
		buffer[offset + index] = bytes[index]
	return offset + bytes.size()


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
