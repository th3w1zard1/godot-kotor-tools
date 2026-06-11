@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWAVWorkspaceEditor := preload("../../ui/workspace/editors/wav_workspace_editor.gd")
const WavGamefsBatchImporter := preload("../../formats/wav_gamefs_batch_importer.gd")

var _install_counter := 0
var _source_counter := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_batch_install_convert_dry_run()
	_test_batch_install_skip_existing()
	_test_batch_install_skip_clean_sources()
	_test_batch_folder_import_dry_run()
	_test_skip_existing()
	var button_ok := await _test_wav_editor_batch_buttons()
	if not button_ok:
		push_error("WAV GameFS batch importer toolbar test failed")
		quit(1)
	print("✓ WAV GameFS batch importer tests passed")
	quit()


func _test_batch_install_convert_dry_run() -> void:
	var install_root := _make_install_root()
	_seed_install_wavs(install_root)
	var gamefs := _build_gamefs(install_root)

	var result := WavGamefsBatchImporter.batch_install_to_override(gamefs, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"sound_type": "SFX",
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	assert(str(result.get("summary", "")).contains("Install batch WAV convert"))
	var first: Dictionary = generated[0]
	assert(str(first.get("output_path", "")).ends_with("_clean.wav"))
	_cleanup(install_root)
	print("✓ GameFS batch install WAV convert dry-run passed")


func _test_batch_install_skip_existing() -> void:
	var install_root := _make_install_root()
	_seed_install_wavs(install_root)
	_write_file(install_root.path_join("override").path_join("line01_clean.wav"), PackedByteArray([0x00]))
	var gamefs := _build_gamefs(install_root)

	var result := WavGamefsBatchImporter.batch_install_to_override(gamefs, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(install_root)
	print("✓ GameFS batch install WAV convert skip-existing passed")


func _test_batch_install_skip_clean_sources() -> void:
	var install_root := _make_install_root()
	_write_file(install_root.path_join("override").path_join("line01_clean.wav"), _build_pcm_wav(8000, 1, 400))
	var gamefs := _build_gamefs(install_root)

	var result := WavGamefsBatchImporter.batch_install_to_override(gamefs, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
	})
	assert((result.get("generated", []) as Array).is_empty())
	assert((result.get("skipped", []) as Array).is_empty())
	_cleanup(install_root)
	print("✓ GameFS batch install WAV convert skip clean sources passed")


func _test_batch_folder_import_dry_run() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_wavs(source_root)
	var gamefs := _build_gamefs(install_root)

	var result := WavGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"sound_type": "VO",
	})
	assert(result.get("ok", false))
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 2)
	assert(str(result.get("summary", "")).contains("Install batch WAV import"))
	var first: Dictionary = generated[0]
	var output_path := str(first.get("output_path", ""))
	assert(output_path.begins_with(install_root.path_join("override")))
	assert(output_path.ends_with("_clean.wav"))
	assert(not FileAccess.file_exists(output_path))
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch WAV import dry-run passed")


func _test_skip_existing() -> void:
	var install_root := _make_install_root()
	var source_root := _make_source_root()
	_seed_wavs(source_root)
	_write_file(install_root.path_join("override").path_join("line01_clean.wav"), PackedByteArray([0x00]))
	var gamefs := _build_gamefs(install_root)

	var result := WavGamefsBatchImporter.batch_folder_to_override(gamefs, source_root, {
		"dry_run": true,
		"pykotor_cli_path": "/bin/true",
		"skip_existing": true,
	})
	var skipped: Array = result.get("skipped", [])
	assert(skipped.size() == 1)
	var generated: Array = result.get("generated", [])
	assert(generated.size() == 1)
	_cleanup(install_root)
	_cleanup(source_root)
	print("✓ GameFS batch WAV import skip-existing passed")


func _test_wav_editor_batch_buttons() -> bool:
	var editor := KotorWAVWorkspaceEditor.new()
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame
	assert(_find_button(editor, "Batch Import WAV Folder to Override...") != null)
	assert(_find_button(editor, "Batch Convert Install WAV...") != null)
	holder.queue_free()
	await process_frame
	print("✓ WAV editor batch import/convert buttons passed")
	return true


func _make_install_root() -> String:
	_install_counter += 1
	var install_root := ProjectSettings.globalize_path(
		"user://wav_gamefs_batch_importer_install_%d_%d" % [_install_counter, Time.get_ticks_usec()]
	)
	DirAccess.make_dir_recursive_absolute(install_root.path_join("override"))
	return install_root


func _make_source_root() -> String:
	_source_counter += 1
	return ProjectSettings.globalize_path(
		"user://wav_gamefs_batch_importer_source_%d_%d" % [_source_counter, Time.get_ticks_usec()]
	)


func _build_gamefs(install_root: String) -> RefCounted:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = install_root
	editor_state.refresh_gamefs()
	return editor_state.gamefs


func _seed_install_wavs(install_root: String) -> void:
	var override_dir := install_root.path_join("override")
	_write_file(override_dir.path_join("line01.wav"), _build_pcm_wav(8000, 1, 400))
	_write_file(override_dir.path_join("line02.wav"), _build_pcm_wav(8000, 1, 800))


func _seed_wavs(source_root: String) -> void:
	DirAccess.make_dir_recursive_absolute(source_root)
	_write_file(source_root.path_join("line01.wav"), _build_pcm_wav(8000, 1, 400))
	_write_file(source_root.path_join("line02.wav"), _build_pcm_wav(8000, 1, 800))


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
