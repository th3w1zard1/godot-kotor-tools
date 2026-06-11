## CPU DXT1/DXT3/DXT5 block encoder for KotOR TPC write-back.
class_name TpcDxtEncoder

const TPCReader := preload("tpc_reader.gd")

const HEADER_SIZE := TPCReader.HEADER_SIZE
const ENC_DXT1 := TPCReader.ENC_DXT1
const ENC_DXT3 := TPCReader.ENC_DXT3
const ENC_DXT5 := TPCReader.ENC_DXT5


static func encode_dxt1_image(image: Image, alpha_test: float = 0.0) -> PackedByteArray:
	return _encode_image(image, ENC_DXT1, alpha_test)


static func encode_dxt3_image(image: Image, alpha_test: float = 0.0) -> PackedByteArray:
	return _encode_image(image, ENC_DXT3, alpha_test)


static func encode_dxt5_image(image: Image, alpha_test: float = 0.0) -> PackedByteArray:
	return _encode_image(image, ENC_DXT5, alpha_test)


static func _encode_image(image: Image, encoding: int, alpha_test: float) -> PackedByteArray:
	if image == null:
		return PackedByteArray()
	var rgba_image := image
	if rgba_image.get_format() != Image.FORMAT_RGBA8:
		rgba_image = rgba_image.duplicate()
		rgba_image.convert(Image.FORMAT_RGBA8)

	var width := rgba_image.get_width()
	var height := rgba_image.get_height()
	if width <= 0 or height <= 0:
		return PackedByteArray()

	var block_w := maxi(1, (width + 3) / 4)
	var block_h := maxi(1, (height + 3) / 4)
	var bytes_per_block := 8 if encoding == ENC_DXT1 else 16
	var data_size := block_w * block_h * bytes_per_block
	var out := PackedByteArray()
	out.resize(HEADER_SIZE + data_size)
	out.fill(0)
	_write_u32(out, 0x00, data_size)
	_write_f32(out, 0x04, alpha_test)
	_write_u16(out, 0x08, width)
	_write_u16(out, 0x0A, height)
	out[0x0C] = encoding
	out[0x0D] = 1

	var dst := HEADER_SIZE
	for by in block_h:
		for bx in block_w:
			var block_pixels := _sample_block(rgba_image, bx, by, width, height)
			var block_bytes: PackedByteArray
			match encoding:
				ENC_DXT5:
					block_bytes = _encode_dxt5_block(block_pixels)
				ENC_DXT3:
					block_bytes = _encode_dxt3_block(block_pixels)
				_:
					block_bytes = _encode_dxt1_block(block_pixels)
			for index in block_bytes.size():
				out[dst + index] = block_bytes[index]
			dst += block_bytes.size()
	return out


static func _sample_block(image: Image, bx: int, by: int, width: int, height: int) -> Array[Color]:
	var pixels: Array[Color] = []
	pixels.resize(16)
	for ry in 4:
		for rx in 4:
			var px := mini(bx * 4 + rx, width - 1)
			var py := mini(by * 4 + ry, height - 1)
			pixels[ry * 4 + rx] = image.get_pixel(px, py)
	return pixels


static func _encode_dxt1_block(pixels: Array[Color]) -> PackedByteArray:
	var has_transparency := false
	for pixel in pixels:
		if pixel.a < 0.5:
			has_transparency = true
			break

	var endpoints := _choose_color_endpoints(pixels, has_transparency)
	var c0: int = endpoints[0]
	var c1: int = endpoints[1]
	if has_transparency:
		if c0 > c1:
			var swap := c0
			c0 = c1
			c1 = swap
	elif c0 <= c1:
		c0 = c1
		c1 = endpoints[0]

	var colors := _color_table(c0, c1, has_transparency)
	var indices := _quantize_indices(pixels, colors, has_transparency)
	var bits := _pack_indices(indices)

	var block := PackedByteArray()
	block.resize(8)
	_write_u16(block, 0, c0)
	_write_u16(block, 2, c1)
	_write_u32(block, 4, bits)
	return block


static func _encode_dxt3_block(pixels: Array[Color]) -> PackedByteArray:
	var alpha_block := _encode_dxt3_alpha_block(pixels)
	var color_block := _encode_dxt1_block(_force_opaque(pixels))
	var block := PackedByteArray()
	block.resize(16)
	for index in 8:
		block[index] = alpha_block[index]
	for index in 8:
		block[8 + index] = color_block[index]
	return block


static func _encode_dxt3_alpha_block(pixels: Array[Color]) -> PackedByteArray:
	var packed := PackedByteArray()
	packed.resize(8)
	packed.fill(0)
	for index in 16:
		var alpha := int(clampi(roundi(pixels[index].a * 255.0), 0, 255))
		var nibble := clampi(int(roundi(float(alpha) / 17.0)), 0, 15)
		var byte_index := index / 2
		if index % 2 == 0:
			packed[byte_index] = nibble
		else:
			packed[byte_index] |= (nibble << 4)
	return packed


static func _encode_dxt5_block(pixels: Array[Color]) -> PackedByteArray:
	var alpha_block := _encode_dxt5_alpha_block(pixels)
	var color_block := _encode_dxt1_block(_force_opaque(pixels))
	var block := PackedByteArray()
	block.resize(16)
	for index in 8:
		block[index] = alpha_block[index]
	for index in 8:
		block[8 + index] = color_block[index]
	return block


static func _force_opaque(pixels: Array[Color]) -> Array[Color]:
	var opaque: Array[Color] = []
	opaque.resize(16)
	for index in 16:
		var pixel := pixels[index]
		opaque[index] = Color(pixel.r, pixel.g, pixel.b, 1.0)
	return opaque


static func _encode_dxt5_alpha_block(pixels: Array[Color]) -> PackedByteArray:
	var alphas: Array[int] = []
	for pixel in pixels:
		alphas.append(int(clampi(roundi(pixel.a * 255.0), 0, 255)))

	var a0 := alphas[0]
	var a1 := alphas[0]
	for alpha in alphas:
		a0 = maxi(a0, alpha)
		a1 = mini(a1, alpha)
	if a0 == a1:
		a1 = maxi(0, a0 - 1)

	var table := _alpha_table(a0, a1)
	var indices: Array[int] = []
	for alpha in alphas:
		indices.append(_nearest_alpha_index(alpha, table))

	var packed := PackedByteArray()
	packed.resize(8)
	packed[0] = a0
	packed[1] = a1
	var bits: int = 0
	for index in 16:
		bits |= (indices[index] & 0x7) << (index * 3)
	for byte_index in 6:
		packed[2 + byte_index] = (bits >> (byte_index * 8)) & 0xFF
	return packed


static func _alpha_table(a0: int, a1: int) -> Array[int]:
	var table: Array[int] = [a0, a1]
	if a0 > a1:
		for k in range(1, 7):
			table.append((a0 * (7 - k) + a1 * k) / 7)
	else:
		for k in range(1, 5):
			table.append((a0 * (5 - k) + a1 * k) / 5)
		table.append(0)
		table.append(255)
	return table


static func _nearest_alpha_index(alpha: int, table: Array[int]) -> int:
	var best_index := 0
	var best_distance := 1_000_000
	for index in table.size():
		var distance := absi(alpha - int(table[index]))
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


static func _choose_color_endpoints(pixels: Array[Color], allow_transparency: bool) -> Array:
	var samples: Array[Color] = []
	for pixel in pixels:
		if allow_transparency and pixel.a < 0.5:
			continue
		samples.append(pixel)

	if samples.is_empty():
		return [_pack_rgb565(Color.BLACK), _pack_rgb565(Color.WHITE)]

	var min_color := samples[0]
	var max_color := samples[0]
	var min_luma := _luma(samples[0])
	var max_luma := min_luma
	for sample in samples:
		var luma := _luma(sample)
		if luma < min_luma:
			min_luma = luma
			min_color = sample
		if luma > max_luma:
			max_luma = luma
			max_color = sample
	return [_pack_rgb565(max_color), _pack_rgb565(min_color)]


static func _quantize_indices(pixels: Array[Color], colors: Array[Color], has_transparency: bool) -> Array[int]:
	var indices: Array[int] = []
	for pixel in pixels:
		if has_transparency and pixel.a < 0.5:
			indices.append(3)
			continue
		var best_index := 0
		var best_distance := 1_000_000.0
		for index in 4:
			if has_transparency and index == 3:
				continue
			var color := colors[index]
			var dr := pixel.r - color.r
			var dg := pixel.g - color.g
			var db := pixel.b - color.b
			var distance := dr * dr + dg * dg + db * db
			if distance < best_distance:
				best_distance = distance
				best_index = index
		indices.append(best_index)
	return indices


static func _pack_indices(indices: Array[int]) -> int:
	var bits := 0
	for index in 16:
		bits |= (indices[index] & 0x3) << (index * 2)
	return bits


static func _color_table(c0: int, c1: int, use_dxt1_alpha: bool) -> Array[Color]:
	var rgb0 := _unpack_rgb565(c0)
	var rgb1 := _unpack_rgb565(c1)
	var table: Array[Color] = [rgb0, rgb1]
	if (not use_dxt1_alpha) or c0 > c1:
		table.append(Color(
			(rgb0.r * 2.0 + rgb1.r) / 3.0,
			(rgb0.g * 2.0 + rgb1.g) / 3.0,
			(rgb0.b * 2.0 + rgb1.b) / 3.0,
			1.0
		))
		table.append(Color(
			(rgb0.r + rgb1.r * 2.0) / 3.0,
			(rgb0.g + rgb1.g * 2.0) / 3.0,
			(rgb0.b + rgb1.b * 2.0) / 3.0,
			1.0
		))
	else:
		table.append(Color(
			(rgb0.r + rgb1.r) * 0.5,
			(rgb0.g + rgb1.g) * 0.5,
			(rgb0.b + rgb1.b) * 0.5,
			1.0
		))
		table.append(Color(0.0, 0.0, 0.0, 0.0))
	return table


static func _pack_rgb565(color: Color) -> int:
	var r := (int(color.r * 255.0) >> 3) & 0x1F
	var g := (int(color.g * 255.0) >> 2) & 0x3F
	var b := (int(color.b * 255.0) >> 3) & 0x1F
	return (r << 11) | (g << 5) | b


static func _unpack_rgb565(value: int) -> Color:
	var r := float(((value >> 11) & 0x1F) * 8) / 255.0
	var g := float(((value >> 5) & 0x3F) * 4) / 255.0
	var b := float((value & 0x1F) * 8) / 255.0
	return Color(r, g, b, 1.0)


static func _luma(color: Color) -> float:
	return color.r * 0.299 + color.g * 0.587 + color.b * 0.114


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
