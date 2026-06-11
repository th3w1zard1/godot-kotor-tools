@tool
extends SceneTree

const LTRParser := preload("../../formats/ltr_parser.gd")
const LTRWriter := preload("../../formats/ltr_writer.gd")
const LTRResource := preload("../../resources/ltr_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_default_resource_round_trip()
	_test_expected_file_size()
	_test_invalid_header()
	print("✓ LTR parser tests passed")
	quit()


func _test_default_resource_round_trip() -> void:
	var resource := LTRResource.new()
	var original := LTRWriter.serialize(resource)
	assert(original.size() == LTRParser.expected_file_size(LTRParser.KOTOR_LETTER_COUNT))

	var parsed: Dictionary = LTRParser.parse_bytes(original)
	assert(not parsed.is_empty())
	assert(int(parsed.get("letter_count", 0)) == LTRParser.KOTOR_LETTER_COUNT)

	var round_trip := LTRWriter.serialize_parsed(parsed)
	assert(round_trip == original)

	resource.set_single_probability("start", 0, 0.25)
	resource.set_single_probability("end", 3, 0.75)
	var edited := LTRWriter.serialize(resource)
	var reparsed: Dictionary = LTRParser.parse_bytes(edited)
	var singles: Dictionary = reparsed.get("singles", {})
	var start_values: Array = singles.get("start", [])
	var end_values: Array = singles.get("end", [])
	assert(is_equal_approx(float(start_values[0]), 0.25))
	assert(is_equal_approx(float(end_values[3]), 0.75))
	print("✓ LTR default resource round-trip passed")


func _test_expected_file_size() -> void:
	assert(LTRParser.expected_file_size(28) == 273177)
	assert(LTRParser.letter_label(28, 0) == "a")
	assert(LTRParser.letter_label(28, 27) == "-")
	print("✓ LTR expected file size passed")


func _test_invalid_header() -> void:
	assert(LTRParser.parse_bytes(PackedByteArray()).is_empty())
	var bad_magic := PackedByteArray()
	bad_magic.resize(12)
	bad_magic.fill(0)
	assert(LTRParser.parse_bytes(bad_magic).is_empty())
	print("✓ LTR invalid header passed")
