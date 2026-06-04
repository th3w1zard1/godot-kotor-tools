@tool
extends SceneTree

const WavMetadata := preload("../../formats/wav_metadata.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_invalid_bytes()
	_test_pcm_metadata()
	_test_pcm_peaks()
	print("✓ WAV metadata tests passed")
	quit()


func _test_invalid_bytes() -> void:
	var result := WavMetadata.parse_bytes(PackedByteArray())
	assert(not result.get("ok", true))
	assert(result.get("message", "") != "")
	print("✓ WAV invalid bytes passed")


func _test_pcm_metadata() -> void:
	var wav := _build_pcm_wav(8000, 1, 800)
	var meta := WavMetadata.parse_bytes(wav)
	assert(meta.get("ok", false))
	assert(int(meta.get("channels", 0)) == 1)
	assert(int(meta.get("sample_rate", 0)) == 8000)
	assert(meta.get("playable_pcm", false))
	assert(is_equal_approx(float(meta.get("duration_seconds", 0.0)), 0.1))
	print("✓ WAV PCM metadata passed")


func _test_pcm_peaks() -> void:
	var wav := _build_pcm_wav(1000, 1, 1000)
	var peaks_result := WavMetadata.build_pcm_peaks(wav, 64)
	assert(peaks_result.get("ok", false))
	var peaks: PackedFloat32Array = peaks_result.get("peaks", PackedFloat32Array())
	assert(peaks.size() == 64)
	for index in peaks.size():
		assert(peaks[index] >= 0.0 and peaks[index] <= 1.0)
	print("✓ WAV PCM peaks passed")


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
