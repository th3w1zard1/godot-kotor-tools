@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_passthrough_round_trip()
	_test_rgba_encode_round_trip()
	_test_append_txi_bytes()
	_test_invalid_passthrough()
	_test_null_image()
	print("✓ TPC writer tests passed")
	quit()


func _test_passthrough_round_trip() -> void:
	var original := _make_rgba_tpc(4, 4, _checker_pixels(4, 4))
	var copied := TPCWriter.serialize_passthrough(original)
	assert(copied.size() == original.size())
	for index in original.size():
		assert(copied[index] == original[index])

	var metadata := TPCReader.read_metadata(copied)
	assert(metadata.get("ok", false))
	assert(metadata.get("width", 0) == 4)
	assert(metadata.get("height", 0) == 4)
	print("✓ TPC passthrough round-trip passed")


func _test_rgba_encode_round_trip() -> void:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var red := 255 if (x + y) % 2 == 0 else 0
			image.set_pixel(x, y, Color8(red, 64, 128, 200))

	var bytes := TPCWriter.serialize_rgba(image, 0.25)
	assert(not bytes.is_empty())

	var metadata := TPCReader.read_metadata(bytes)
	assert(metadata.get("ok", false))
	assert(metadata.get("width", 0) == 8)
	assert(metadata.get("height", 0) == 8)
	assert(metadata.get("encoding", 0) == TPCReader.ENC_RGBA)
	assert(is_equal_approx(float(metadata.get("alpha_test", 0.0)), 0.25))

	var decoded := TPCReader.read_image(bytes)
	assert(decoded != null)
	assert(decoded.get_width() == 8)
	assert(decoded.get_height() == 8)
	assert(decoded.get_pixel(0, 0) == image.get_pixel(0, 0))
	assert(decoded.get_pixel(7, 7) == image.get_pixel(7, 7))
	print("✓ TPC RGBA encode round-trip passed")


func _test_append_txi_bytes() -> void:
	var original := _make_rgba_tpc(4, 4, _checker_pixels(4, 4))
	var txi := "envmap\nproceduretype cycle\n".to_utf8_buffer()

	var with_txi := TPCWriter.append_txi_bytes(original, txi)
	assert(not with_txi.is_empty())
	assert(with_txi.size() == original.size() + txi.size())

	var metadata := TPCReader.read_metadata(with_txi)
	assert(metadata.get("ok", false))
	assert(int(metadata.get("txi_length", 0)) == txi.size())

	var read_txi := TPCWriter.read_txi_bytes(with_txi)
	assert(read_txi.size() == txi.size())
	for index in txi.size():
		assert(read_txi[index] == txi[index])

	var decoded := TPCReader.read_image(with_txi)
	assert(decoded != null)
	assert(decoded.get_width() == 4)
	print("✓ TPC append TXI bytes passed")


func _test_invalid_passthrough() -> void:
	assert(TPCWriter.serialize_passthrough(PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(64)
	short.fill(0)
	assert(TPCWriter.serialize_passthrough(short).is_empty())
	print("✓ TPC invalid passthrough passed")


func _test_null_image() -> void:
	assert(TPCWriter.serialize_rgba(null).is_empty())
	print("✓ TPC null image passed")


func _make_rgba_tpc(width: int, height: int, pixels: PackedByteArray) -> PackedByteArray:
	var data_size := width * height * 4
	assert(pixels.size() == data_size)
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


func _checker_pixels(width: int, height: int) -> PackedByteArray:
	var pixels := PackedByteArray()
	pixels.resize(width * height * 4)
	for y in height:
		for x in width:
			var base := (y * width + x) * 4
			var value := 255 if (x + y) % 2 == 0 else 0
			pixels[base + 0] = value
			pixels[base + 1] = value
			pixels[base + 2] = value
			pixels[base + 3] = 255
	return pixels


const HEADER_SIZE := 128


func _write_u16(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF


func _write_u32(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF
	buffer[offset + 2] = (value >> 16) & 0xFF
	buffer[offset + 3] = (value >> 24) & 0xFF


func _write_f32(buffer: PackedByteArray, offset: int, value: float) -> void:
	buffer.encode_float(offset, value)
