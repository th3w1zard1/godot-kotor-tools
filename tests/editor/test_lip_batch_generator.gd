@tool
extends SceneTree

const LipBatchGenerator := preload("../../formats/lip_batch_generator.gd")
const LIPParser := preload("../../formats/lip_parser.gd")
const WavMetadata := preload("../../formats/wav_metadata.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_generate_from_wav_bytes()
	_test_invalid_wav()
	_test_adpcm_rejected()
	_test_batch_directory()
	print("✓ LIP batch generator tests passed")
	quit()


func _test_generate_from_wav_bytes() -> void:
	var wav := _build_pcm_wav(8000, 1, 8000)
	var result := LipBatchGenerator.generate_from_wav_bytes(wav)
	assert(result.get("ok", false))

	var lip_bytes: PackedByteArray = result.get("bytes", PackedByteArray())
	assert(not lip_bytes.is_empty())

	var parsed := LIPParser.parse_bytes(lip_bytes)
	assert(not parsed.is_empty())
	assert(is_equal_approx(float(parsed.get("length", 0.0)), 1.0))
	assert(is_equal_approx(float(result.get("duration", 0.0)), 1.0))

	var keyframes: Array = parsed.get("keyframes", [])
	assert(keyframes.size() >= 2)
	assert(int(keyframes[0].get("shape", -1)) == LipBatchGenerator.DEFAULT_SHAPE)
	print("✓ LIP generate from WAV bytes passed")


func _test_invalid_wav() -> void:
	var result := LipBatchGenerator.generate_from_wav_bytes(PackedByteArray())
	assert(not result.get("ok", true))
	assert(str(result.get("message", "")) != "")
	print("✓ LIP invalid WAV passed")


func _test_adpcm_rejected() -> void:
	var wav := _build_pcm_wav(8000, 1, 800)
	wav.encode_u16(20, 17)  # IMA ADPCM
	var meta := WavMetadata.parse_bytes(wav)
	assert(not meta.get("playable_pcm", true))

	var result := LipBatchGenerator.generate_from_wav_bytes(wav)
	assert(not result.get("ok", true))
	assert(str(result.get("message", "")).find("PCM") >= 0)
	print("✓ LIP ADPCM rejection passed")


func _test_batch_directory() -> void:
	var root := ProjectSettings.globalize_path(
		"user://lip_batch_generator_test_%d" % Time.get_ticks_usec()
	)
	DirAccess.make_dir_recursive_absolute(root)

	var wav_one := root.path_join("line01.wav")
	var wav_two := root.path_join("line02.wav")
	_write_file(wav_one, _build_pcm_wav(8000, 1, 4000))
	_write_file(wav_two, _build_pcm_wav(8000, 1, 8000))

	var batch := LipBatchGenerator.batch_directory(root)
	assert(batch.get("ok", false))
	var generated: Array = batch.get("generated", [])
	assert(generated.size() == 2)
	assert(FileAccess.file_exists(root.path_join("line01.lip")))
	assert(FileAccess.file_exists(root.path_join("line02.lip")))

	var reskip := LipBatchGenerator.batch_directory(root, {"skip_existing": true})
	var skipped: Array = reskip.get("skipped", [])
	assert(skipped.size() == 2)
	assert(reskip.get("generated", []).is_empty())

	_remove_tree(root)
	print("✓ LIP batch directory passed")


func _write_file(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_buffer(bytes)
	file.close()


func _remove_tree(path: String) -> void:
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
		if not dir.current_is_dir():
			DirAccess.remove_absolute(path.path_join(entry))
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

	for sample_index in sample_count:
		var amplitude := int(sin(float(sample_index) / 10.0) * 16000.0)
		for _channel in channels:
			buffer.encode_s16(offset, amplitude)
			offset += 2

	return buffer


func _write_ascii(buffer: PackedByteArray, offset: int, text: String) -> int:
	var bytes := text.to_utf8_buffer()
	for index in bytes.size():
		buffer[offset + index] = bytes[index]
	return offset + bytes.size()
