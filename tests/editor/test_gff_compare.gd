@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GFFResource := preload("../../resources/gff_resource.gd")
const GFFCompare := preload("../../formats/gff_compare.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_scalar_field_diff()
	_test_dlg_list_count_diff()
	_test_invalid_bytes_fallback()
	_test_pipeline_wiring()
	print("✓ GFF compare tests passed")
	quit()


func _test_scalar_field_diff() -> void:
	var base := _make_utc_resource("base_creature")
	var mod := _make_utc_resource("mod_creature")
	var report := GFFCompare.build_difference_report(
		_serialize(base),
		_serialize(mod)
	)
	assert(not report.is_empty())
	assert(report.find("UTC differs") >= 0)
	assert(report.find("Tag") >= 0)
	print("✓ GFF scalar field diff passed")


func _test_dlg_list_count_diff() -> void:
	var base := _make_dlg_resource(1, 1)
	var mod := _make_dlg_resource(2, 1)
	var report := GFFCompare.build_difference_report(
		_serialize(base),
		_serialize(mod)
	)
	assert(not report.is_empty())
	assert(report.find("DLG differs") >= 0)
	assert(report.find("EntryList count: 1 -> 2") >= 0)
	print("✓ GFF DLG list count diff passed")


func _test_invalid_bytes_fallback() -> void:
	assert(GFFCompare.build_difference_report(PackedByteArray(), PackedByteArray()).is_empty())
	var short := PackedByteArray()
	short.resize(8)
	assert(GFFCompare.build_difference_report(short, short).is_empty())
	print("✓ GFF invalid bytes fallback passed")


func _test_pipeline_wiring() -> void:
	assert(GFFCompare.is_gff_extension("dlg"))
	assert(GFFCompare.is_gff_extension("UTC"))
	assert(not GFFCompare.is_gff_extension("nss"))
	print("✓ GFF pipeline wiring passed")


func _make_utc_resource(tag: String) -> GFFResource:
	var resource := GFFResource.new()
	resource.file_type = "UTC"
	resource.gff_data = {"Tag": tag}
	resource.schema_data = {
		"struct_type": 0xFFFFFFFF,
		"fields": [{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING}],
	}
	return resource


func _make_dlg_resource(entry_count: int, reply_count: int) -> GFFResource:
	var entries: Array = []
	for index in entry_count:
		entries.append({
			"Text": {"strref": 0xFFFFFFFF, "strings": {0: "Entry %d" % index}},
			"RepliesList": [],
		})
	var replies: Array = []
	for index in reply_count:
		replies.append({
			"Text": {"strref": 0xFFFFFFFF, "strings": {0: "Reply %d" % index}},
			"EntriesList": [],
		})

	var resource := GFFResource.new()
	resource.file_type = "DLG"
	resource.gff_data = {
		"Tag": "test_dlg",
		"StartingList": [{"Index": 0}],
		"EntryList": entries,
		"ReplyList": replies,
	}
	resource.schema_data = _dlg_schema()
	return resource


func _dlg_schema() -> Dictionary:
	return {
		"struct_type": 0xFFFFFFFF,
		"fields": [
			{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
			{
				"name": "StartingList",
				"type": GFFParser.FIELD_LIST,
				"items": [{
					"struct_type": 0,
					"fields": [{"name": "Index", "type": GFFParser.FIELD_INT}],
				}],
			},
			{
				"name": "EntryList",
				"type": GFFParser.FIELD_LIST,
				"items": [{
					"struct_type": 0,
					"fields": [
						{"name": "Text", "type": GFFParser.FIELD_CEXOLOCSTR},
						{"name": "RepliesList", "type": GFFParser.FIELD_LIST, "items": []},
					],
				}],
			},
			{
				"name": "ReplyList",
				"type": GFFParser.FIELD_LIST,
				"items": [{
					"struct_type": 0,
					"fields": [
						{"name": "Text", "type": GFFParser.FIELD_CEXOLOCSTR},
						{"name": "EntriesList", "type": GFFParser.FIELD_LIST, "items": []},
					],
				}],
			},
		],
	}


func _serialize(resource: GFFResource) -> PackedByteArray:
	var bytes := GFFWriter.serialize(resource)
	assert(not bytes.is_empty())
	return bytes
