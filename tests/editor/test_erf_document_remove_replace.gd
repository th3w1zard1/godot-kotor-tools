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
	_test_remove_member_at()
	_test_replace_member_at()
	_test_restore_members_snapshot()
	print("✓ ERF document remove/replace tests passed")
	quit()


func _test_remove_member_at() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
		{"resref": "test_are", "extension": "are", "bytes": _build_empty_are_bytes()},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	assert(document.get_entry_count() == 2)
	var result := document.remove_member_at(1)
	assert(result.get("ok", false), str(result))
	assert(document.get_entry_count() == 1)
	assert(document.find_entry_index("tar_m02aa", "git") == 0)
	assert(document.is_dirty())
	print("✓ ERF document remove_member_at passed")


func _test_replace_member_at() -> void:
	var original_git := _build_empty_git_bytes()
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": original_git},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	var replacement := _build_empty_are_bytes()
	var result := document.replace_member_at(0, replacement)
	assert(result.get("ok", false), str(result))
	assert(document.get_entry_payload(0) == replacement)
	assert(document.entry_file_name(0) == "tar_m02aa.git")
	assert(document.is_dirty())
	print("✓ ERF document replace_member_at passed")


func _test_restore_members_snapshot() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var document := KotorErfDocument.from_bytes("", mod_bytes)
	var snapshot: Array = document.serialize_for_pipeline().get("entries", []).duplicate(true)
	document.add_member("extra_are", "are", _build_empty_are_bytes())
	assert(document.get_entry_count() == 2)
	document.restore_members(snapshot)
	assert(document.get_entry_count() == 1)
	assert(document.entry_file_name(0) == "tar_m02aa.git")
	var repacked := document.get_repacked_bytes()
	assert(not ERFParser.parse_bytes(repacked).is_empty())
	print("✓ ERF document restore_members snapshot passed")


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
