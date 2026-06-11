@tool
extends SceneTree

const TPCReader := preload("../../formats/tpc_reader.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_dxt1_round_trip()
	_test_dxt5_round_trip()
	_test_dxt1_solid_block()
	_test_invalid_inputs()
	print("✓ TPC DXT encoder tests passed")
	quit()


func _test_dxt1_round_trip() -> void:
	var image := _make_checker_image(8, 8)
	var bytes := TPCWriter.serialize_dxt1(image, 0.1)
	assert(not bytes.is_empty())

	var metadata := TPCReader.read_metadata(bytes)
	assert(metadata.get("ok", false))
	assert(metadata.get("width", 0) == 8)
	assert(metadata.get("height", 0) == 8)
	assert(metadata.get("encoding", 0) == TPCReader.ENC_DXT1)

	var decoded := TPCReader.read_image(bytes)
	assert(decoded != null)
	assert(decoded.get_width() == 8)
	assert(decoded.get_height() == 8)
	assert(_color_close(decoded.get_pixel(0, 0), image.get_pixel(0, 0), 0.35))
	assert(_color_close(decoded.get_pixel(7, 7), image.get_pixel(7, 7), 0.35))
	print("✓ TPC DXT1 round-trip passed")


func _test_dxt5_round_trip() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			image.set_pixel(x, y, Color(0.2, 0.5, 0.9, float(x) / 3.0))

	var bytes := TPCWriter.serialize_dxt5(image)
	assert(not bytes.is_empty())

	var metadata := TPCReader.read_metadata(bytes)
	assert(metadata.get("ok", false))
	assert(metadata.get("encoding", 0) == TPCReader.ENC_DXT5)

	var decoded := TPCReader.read_image(bytes)
	assert(decoded != null)
	assert(decoded.get_width() == 4)
	assert(decoded.get_height() == 4)
	assert(_color_close(decoded.get_pixel(0, 0), image.get_pixel(0, 0), 0.4))
	assert(_color_close(decoded.get_pixel(3, 0), image.get_pixel(3, 0), 0.4))
	print("✓ TPC DXT5 round-trip passed")


func _test_dxt1_solid_block() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.6, 0.2, 1.0))
	var bytes := TPCWriter.serialize_dxt1(image)
	var decoded := TPCReader.read_image(bytes)
	assert(decoded != null)
	assert(_color_close(decoded.get_pixel(1, 1), image.get_pixel(1, 1), 0.2))
	print("✓ TPC DXT1 solid block passed")


func _test_invalid_inputs() -> void:
	assert(TPCWriter.serialize_dxt1(null).is_empty())
	assert(TPCWriter.serialize_dxt5(null).is_empty())
	var tiny := Image.create(0, 4, false, Image.FORMAT_RGBA8)
	assert(TPCWriter.serialize_dxt1(tiny).is_empty())
	print("✓ TPC DXT invalid inputs passed")


func _make_checker_image(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var red := 1.0 if (x + y) % 2 == 0 else 0.0
			image.set_pixel(x, y, Color(red, 0.25, 0.5, 1.0))
	return image


func _color_close(actual: Color, expected: Color, tolerance: float) -> bool:
	return (
		absf(actual.r - expected.r) <= tolerance
		and absf(actual.g - expected.g) <= tolerance
		and absf(actual.b - expected.b) <= tolerance
	)
