@tool
extends SceneTree

const WavMetadata := preload("../../formats/wav_metadata.gd")
const WavCompare := preload("../../formats/wav_compare.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_sample_rate_diff()
	_test_payload_diff_same_metadata()
	_test_invalid_bytes_fallback()
	_test_identical_no_report()
	_test_pipeline_wiring()
	print("✓ WAV compare tests passed")
	quit()


func _test_sample_rate_diff() -> void:
	var base := _build_pcm_wav(8000, 1, 800)
	var mod := _build_pcm_wav(16000, 1, 1600)
	var report := WavCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("WAV differs") >= 0)
	assert(report.find("sample rate: 8000 -> 16000 Hz") >= 0)
	print("✓ WAV sample rate diff passed")


func _test_payload_diff_same_metadata() -> void:
	var base := _build_pcm_wav(8000, 1, 800)
	var mod := base.duplicate()
	var meta := WavMetadata.parse_bytes(base)
	var data_offset := int(meta.get("data_offset", 44))
	mod[data_offset + 2] = 0xFF
	var report := WavCompare.build_difference_report(base, mod)
	assert(report.find("audio payload differs") >= 0)
	print("✓ WAV payload diff passed")


func _test_invalid_bytes_fallback() -> void:
	assert(WavCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(8)
	assert(WavCompare.build_difference_report(short, short).is_empty())
	print("✓ WAV invalid bytes fallback passed")


func _test_identical_no_report() -> void:
	var bytes := _build_pcm_wav(44100, 2, 4410)
	assert(WavCompare.build_difference_report(bytes, bytes).is_empty())
	print("✓ WAV identical no report passed")


func _test_pipeline_wiring() -> void:
	var base := _build_pcm_wav(8000, 1, 800)
	var mod := _build_pcm_wav(8000, 2, 800)
	var report := KotorModdingPipeline._build_difference_report("wav", base, mod)
	assert(not report.is_empty())
	assert(report.find("WAV differs") >= 0)
	assert(report.find("channels: 1 -> 2") >= 0)
	print("✓ WAV pipeline wiring passed")


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
