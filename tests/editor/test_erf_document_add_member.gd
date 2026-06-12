@tool
extends SceneTree

const ERFParser := preload("../../formats/erf_parser.gd")
const ERFWriter := preload("../../formats/erf_writer.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const KotorErfDocument := preload("../../resources/documents/kotor_erf_document.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_add_member_repack_round_trip()
	_test_duplicate_member_rejected()
	_test_serialize_for_pipeline()
	_test_add_member_validation_rejects()
	print("✓ ERF document add member tests passed")
	quit()


func _test_add_member_repack_round_trip() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	assert(document != null)
	assert(not document.is_dirty())
	var result := document.add_member("test_are", "are", _build_empty_are_bytes())
	assert(result.get("ok", false), str(result))
	assert(document.is_dirty())
	assert(document.get_entry_count() == 2)
	assert(document.find_entry_index("test_are", "are") == 1)
	var repacked := document.get_repacked_bytes()
	var parsed := ERFParser.parse_bytes(repacked)
	assert(parsed.get("entries", []).size() == 2)
	print("✓ ERF document add member repack round-trip passed")


func _test_duplicate_member_rejected() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	var result := document.add_member("tar_m02aa", "git", _build_empty_git_bytes())
	assert(not result.get("ok", true))
	assert(document.get_entry_count() == 1)
	print("✓ ERF document duplicate member rejected passed")


func _test_serialize_for_pipeline() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	document.add_member("test_are", "are", _build_empty_are_bytes())
	var payload := document.serialize_for_pipeline()
	assert(payload.get("file_type", "") == "MOD ")
	assert(payload.get("entries", []).size() == 2)
	var serialized := ERFWriter.repack(str(payload.get("file_type", "")), payload.get("entries", []))
	assert(serialized.size() > 0)
	print("✓ ERF document serialize_for_pipeline passed")


func _test_add_member_validation_rejects() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	var empty_result := document.add_member("", "are", _build_empty_are_bytes())
	assert(not empty_result.get("ok", true))
	var long_result := document.add_member("a".repeat(17), "are", _build_empty_are_bytes())
	assert(not long_result.get("ok", true))
	var unknown_result := document.add_member("test_xyz", "zzz", _build_empty_are_bytes())
	assert(not unknown_result.get("ok", true))
	assert(document.get_entry_count() == 1)
	print("✓ ERF document add member validation rejects passed")


func _build_empty_git_bytes() -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(_build_git_parsed()))


func _build_empty_are_bytes() -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result({
		"file_type": "ARE ",
		"root": {},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	}))


func _build_git_parsed() -> Dictionary:
	var instance_fields: Array = [
		{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
		{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
		{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
	]
	var schema_fields: Array = []
	var root := {}
	for list_field in [
		"Creature List",
		"Door List",
		"Encounter List",
		"Placeable List",
		"SoundList",
		"StoreList",
		"TriggerList",
		"WaypointList",
	]:
		root[list_field] = []
		schema_fields.append({
			"name": list_field,
			"type": GFFParser.FIELD_LIST,
			"items": [
				{
					"struct_type": 1,
					"fields": instance_fields,
				},
			],
		})
	return {
		"file_type": "GIT ",
		"root": root,
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": schema_fields,
		},
	}
