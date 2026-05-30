@tool
extends SceneTree

const LIPParser := preload("../../formats/lip_parser.gd")
const LIPWriter := preload("../../formats/lip_writer.gd")
const LIPResource := preload("../../resources/lip_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_round_trip_keyframes()
	_test_resource_serialize()
	_test_shape_token_parsing()
	_test_invalid_header()
	print("✓ LIP parser tests passed")
	quit()


func _test_round_trip_keyframes() -> void:
	var keyframes: Array = [
		{"time": 0.0, "shape": 0},
		{"time": 0.5, "shape": 3},
		{"time": 1.2, "shape": 11},
	]
	var length := 1.5
	var bytes := LIPWriter.serialize_keyframes(length, keyframes)
	assert(bytes.size() == LIPParser.HEADER_SIZE + keyframes.size() * 5)

	var parsed: Dictionary = LIPParser.parse_bytes(bytes)
	assert(not parsed.is_empty())
	assert(is_equal_approx(float(parsed.get("length", -1.0)), length))
	var parsed_frames: Array = parsed.get("keyframes", [])
	assert(parsed_frames.size() == keyframes.size())
	for index in keyframes.size():
		var expected: Dictionary = keyframes[index]
		var actual: Dictionary = parsed_frames[index]
		assert(is_equal_approx(float(actual.get("time", -1.0)), float(expected.get("time", 0.0))))
		assert(int(actual.get("shape", -1)) == int(expected.get("shape", 0)))
	print("✓ LIP round-trip keyframes passed")


func _test_resource_serialize() -> void:
	var resource := LIPResource.new()
	resource.set_length(2.0)
	resource.add_keyframe(0.0, 1)
	resource.add_keyframe(0.75, 9)
	resource.add_keyframe(1.5, 15)

	var bytes := LIPWriter.serialize(resource)
	var parsed: Dictionary = LIPParser.parse_bytes(bytes)
	assert(is_equal_approx(float(parsed.get("length", 0.0)), 2.0))
	var frames: Array = parsed.get("keyframes", [])
	assert(frames.size() == 3)
	assert(int(frames[1].get("shape", -1)) == 9)
	print("✓ LIP resource serialize passed")


func _test_shape_token_parsing() -> void:
	assert(LIPParser.parse_shape_token("EE") == 1)
	assert(LIPParser.parse_shape_token("11") == 11)
	assert(LIPParser.parse_shape_token("bad") == -1)
	assert(LIPParser.shape_name(4) == "OH")
	print("✓ LIP shape token parsing passed")


func _test_invalid_header() -> void:
	assert(LIPParser.parse_bytes(PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(8)
	short.fill(0)
	assert(LIPParser.parse_bytes(short).is_empty())
	print("✓ LIP invalid header passed")
