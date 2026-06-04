## formats/tpc_writer.gd
## KotOR TPC (BioWare Texture) writer — passthrough and RGBA mip-0 encode.
##
## Header layout matches formats/tpc_reader.gd (128 bytes).
class_name TPCWriter

const TPCReader := preload("tpc_reader.gd")

const HEADER_SIZE := TPCReader.HEADER_SIZE
const ENC_RGBA := TPCReader.ENC_RGBA


## Return a byte-identical copy when input is a valid TPC; empty on failure.
static func serialize_passthrough(data: PackedByteArray) -> PackedByteArray:
	var metadata := TPCReader.read_metadata(data)
	if not metadata.get("ok", false):
		push_error("TPCWriter: passthrough rejected invalid TPC")
		return PackedByteArray()
	return data.duplicate()


## Encode mip 0 as uncompressed RGBA TPC bytes.
static func serialize_rgba(image: Image, alpha_test: float = 0.0) -> PackedByteArray:
	if image == null:
		push_error("TPCWriter: null image")
		return PackedByteArray()

	var rgba_image := image
	if rgba_image.get_format() != Image.FORMAT_RGBA8:
		rgba_image = rgba_image.duplicate()
		rgba_image.convert(Image.FORMAT_RGBA8)

	var width := rgba_image.get_width()
	var height := rgba_image.get_height()
	if width <= 0 or height <= 0:
		push_error("TPCWriter: zero-size image")
		return PackedByteArray()

	var pixels := rgba_image.get_data()
	var data_size := pixels.size()
	var out := PackedByteArray()
	out.resize(HEADER_SIZE + data_size)
	out.fill(0)

	_write_u32(out, 0x00, data_size)
	_write_f32(out, 0x04, alpha_test)
	_write_u16(out, 0x08, width)
	_write_u16(out, 0x0A, height)
	out[0x0C] = ENC_RGBA
	out[0x0D] = 1  # num_mips

	for index in data_size:
		out[HEADER_SIZE + index] = pixels[index]

	return out


static func _write_u16(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF


static func _write_u32(buffer: PackedByteArray, offset: int, value: int) -> void:
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF
	buffer[offset + 2] = (value >> 16) & 0xFF
	buffer[offset + 3] = (value >> 24) & 0xFF


static func _write_f32(buffer: PackedByteArray, offset: int, value: float) -> void:
	buffer.encode_float(offset, value)
