@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const TPCCompare := preload("../../formats/tpc_compare.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")

const HEADER_SIZE := 128


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_dimension_diff()
	_test_payload_diff_same_header()
	_test_invalid_bytes_fallback()
	_test_identical_no_report()
	_test_pipeline_wiring()
	print("✓ TPC compare tests passed")
	quit()


func _test_dimension_diff() -> void:
	var base := _make_rgba_tpc(4, 4, _solid_pixels(4, 4, 255, 0, 0, 255))
	var mod := _make_rgba_tpc(8, 4, _solid_pixels(8, 4, 255, 0, 0, 255))
	var report := TPCCompare.build_difference_report(base, mod)
	assert(not report.is_empty())
	assert(report.find("TPC differs") >= 0)
	assert(report.find("width: 4 -> 8") >= 0)
	print("✓ TPC dimension diff passed")


func _test_payload_diff_same_header() -> void:
	var base := _make_rgba_tpc(4, 4, _solid_pixels(4, 4, 255, 0, 0, 255))
	var mod := base.duplicate()
	mod[HEADER_SIZE] = 0
	var report := TPCCompare.build_difference_report(base, mod)
	assert(report.find("pixel payload differs") >= 0)
	print("✓ TPC payload diff passed")


func _test_invalid_bytes_fallback() -> void:
	assert(TPCCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(64)
	assert(TPCCompare.build_difference_report(short, short).is_empty())
	print("✓ TPC invalid bytes fallback passed")


func _test_identical_no_report() -> void:
	var bytes := _make_rgba_tpc(2, 2, _solid_pixels(2, 2, 0, 128, 255, 255))
	assert(TPCCompare.build_difference_report(bytes, bytes).is_empty())
	print("✓ TPC identical no report passed")


func _test_pipeline_wiring() -> void:
	var base := _make_rgba_tpc(4, 4, _solid_pixels(4, 4, 10, 20, 30, 255))
	var mod := _make_rgba_tpc(4, 4, _solid_pixels(4, 4, 11, 20, 30, 255))
	var report := KotorModdingPipeline._build_difference_report("tpc", base, mod)
	assert(not report.is_empty())
	assert(report.find("TPC differs") >= 0)
	print("✓ TPC pipeline wiring passed")


func _make_rgba_tpc(width: int, height: int, pixels: PackedByteArray) -> PackedByteArray:
	var data_size := width * height * 4
	var out := PackedByteArray()
	out.resize(HEADER_SIZE + data_size)
	out.fill(0)
	_write_u32(out, 0x00, data_size)
	_write_f32(out, 0x04, 0.0)
	_write_u16(out, 0x08, width)
	_write_u16(out, 0x0A, height)
	out[0x0C] = TPCReader.ENC_RGBA
	out[0x0D] = 1
	for index in data_size:
		out[HEADER_SIZE + index] = pixels[index]
	return out


func _solid_pixels(width: int, height: int, r: int, g: int, b: int, a: int) -> PackedByteArray:
	var pixels := PackedByteArray()
	pixels.resize(width * height * 4)
	for y in height:
		for x in width:
			var base := (y * width + x) * 4
			pixels[base + 0] = r
			pixels[base + 1] = g
			pixels[base + 2] = b
			pixels[base + 3] = a
	return pixels


func _write_u32(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF
	buffer[offset + 2] = (value >> 16) & 0xFF
	buffer[offset + 3] = (value >> 24) & 0xFF


func _write_u16(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF


func _write_f32(buffer: PackedByteArray, offset: int, value: float) -> void:
	buffer.encode_float(offset, value)
