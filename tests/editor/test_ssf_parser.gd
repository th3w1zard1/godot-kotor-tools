@tool
extends SceneTree

const SSFParser := preload("../../formats/ssf_parser.gd")
const SSFWriter := preload("../../formats/ssf_writer.gd")
const SSFResource := preload("../../resources/ssf_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_round_trip_strrefs()
	_test_resource_serialize()
	_test_invalid_header()
	print("✓ SSF parser tests passed")
	quit()


func _test_round_trip_strrefs() -> void:
	var strrefs: Array[int] = []
	strrefs.resize(SSFParser.SLOT_COUNT)
	for index in SSFParser.SLOT_COUNT:
		strrefs[index] = index * 10 if index % 3 != 0 else -1
	strrefs[0] = 12345
	strrefs[15] = 67890

	var bytes := SSFWriter.serialize_strrefs(strrefs)
	assert(bytes.size() == SSFParser.HEADER_SIZE + SSFParser.SLOT_COUNT * 4 + SSFWriter.PADDING_SLOTS * 4)

	var parsed: Dictionary = SSFParser.parse_bytes(bytes)
	assert(not parsed.is_empty())
	var parsed_refs: Array = parsed.get("strrefs", [])
	assert(parsed_refs.size() == SSFParser.SLOT_COUNT)
	for index in SSFParser.SLOT_COUNT:
		assert(int(parsed_refs[index]) == strrefs[index])
	print("✓ SSF round-trip strrefs passed")


func _test_resource_serialize() -> void:
	var resource := SSFResource.new()
	resource.set_strref(0, 42)
	resource.set_strref(6, 100)
	resource.set_strref(15, -1)

	var bytes := SSFWriter.serialize(resource)
	var parsed: Dictionary = SSFParser.parse_bytes(bytes)
	assert(int(parsed.get("strrefs", [])[0]) == 42)
	assert(int(parsed.get("strrefs", [])[6]) == 100)
	assert(int(parsed.get("strrefs", [])[15]) == -1)
	print("✓ SSF resource serialize passed")


func _test_invalid_header() -> void:
	assert(SSFParser.parse_bytes(PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(8)
	short.fill(0)
	assert(SSFParser.parse_bytes(short).is_empty())
	print("✓ SSF invalid header passed")
