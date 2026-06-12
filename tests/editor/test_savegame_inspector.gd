@tool
extends SceneTree

const ERFWriter := preload("../../formats/erf_writer.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const SavegameInspector := preload("../../formats/savegame_inspector.gd")
const KotorErfWorkspaceEditor := preload("../../ui/workspace/editors/erf_workspace_editor.gd")
const KotorSavegameWorkspaceEditor := preload("../../ui/workspace/editors/savegame_workspace_editor.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_inspect_save_metadata()
	_test_reject_non_sav_archive()
	_test_extension_routing_helpers()
	_test_format_play_time()
	print("✓ Savegame inspector tests passed")
	quit()


func _test_inspect_save_metadata() -> void:
	var sav_bytes := _build_test_sav_bytes()
	var inspection := SavegameInspector.inspect_bytes(sav_bytes)
	assert(inspection.get("ok", false))
	assert(int(inspection.get("entry_count", 0)) == 3)
	var metadata: Dictionary = inspection.get("metadata", {})
	assert(str(metadata.get("save_name", "")) == "Test Save")
	assert(str(metadata.get("last_module", "")) == "tar_m02aa")
	assert(str(metadata.get("area_name", "")) == "Apartment")
	assert(int(metadata.get("time_played_seconds", 0)) == 3661)
	assert(str(metadata.get("time_played_label", "")) == "1h 1m 1s")
	assert(str(metadata.get("pc_name", "")) == "Revan")
	assert(int(metadata.get("party_member_count", 0)) == 2)
	assert(int(metadata.get("global_variable_count", 0)) == 5)
	print("✓ Savegame metadata extraction passed")


func _test_reject_non_sav_archive() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "test", "extension": "git", "bytes": _build_gff_bytes(_build_git_parsed())},
	])
	var inspection := SavegameInspector.inspect_bytes(mod_bytes)
	assert(not inspection.get("ok", true))
	print("✓ Non-SAV archive rejection passed")


func _test_extension_routing_helpers() -> void:
	assert(KotorSavegameWorkspaceEditor.savegame_extension_allowed("sav"))
	assert(not KotorSavegameWorkspaceEditor.savegame_extension_allowed("mod"))
	assert(KotorErfWorkspaceEditor.archive_extension_allowed("mod"))
	assert(not KotorErfWorkspaceEditor.archive_extension_allowed("sav"))
	print("✓ Savegame routing helpers passed")


func _test_format_play_time() -> void:
	assert(SavegameInspector.format_play_time(45) == "45s")
	assert(SavegameInspector.format_play_time(125) == "2m 5s")
	assert(SavegameInspector.format_play_time(3661) == "1h 1m 1s")
	print("✓ Savegame play-time formatting passed")


func _build_test_sav_bytes() -> PackedByteArray:
	return ERFWriter.build("SAV ", [
		{"resref": "savenfo", "extension": "res", "bytes": _build_gff_bytes(_build_savenfo_parsed())},
		{"resref": "partytable", "extension": "res", "bytes": _build_gff_bytes(_build_partytable_parsed())},
		{"resref": "globalvars", "extension": "res", "bytes": _build_gff_bytes(_build_globalvars_parsed())},
	])


func _build_gff_bytes(parsed: Dictionary) -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(parsed))


func _build_savenfo_parsed() -> Dictionary:
	return {
		"file_type": "GFF ",
		"root": {
			"SAVEGAMENAME": "Test Save",
			"LASTMODULE": "tar_m02aa",
			"AREANAME": "Apartment",
			"TIMEPLAYED": 3661,
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "SAVEGAMENAME", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "LASTMODULE", "type": GFFParser.FIELD_CRESREF},
				{"name": "AREANAME", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "TIMEPLAYED", "type": GFFParser.FIELD_DWORD},
			],
		},
	}


func _build_partytable_parsed() -> Dictionary:
	return {
		"file_type": "GFF ",
		"root": {
			"PT_PCNAME": "Revan",
			"PT_MEMBERS": [{}, {}],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "PT_PCNAME", "type": GFFParser.FIELD_CEXOSTRING},
				{
					"name": "PT_MEMBERS",
					"type": GFFParser.FIELD_LIST,
					"items": [{"struct_type": 1, "fields": []}],
				},
			],
		},
	}


func _build_globalvars_parsed() -> Dictionary:
	return {
		"file_type": "GFF ",
		"root": {
			"ValNumber": [{}, {}, {}],
			"ValBoolean": [{}, {}],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{
					"name": "ValNumber",
					"type": GFFParser.FIELD_LIST,
					"items": [{"struct_type": 1, "fields": []}],
				},
				{
					"name": "ValBoolean",
					"type": GFFParser.FIELD_LIST,
					"items": [{"struct_type": 1, "fields": []}],
				},
			],
		},
	}


func _build_git_parsed() -> Dictionary:
	return {
		"file_type": "GIT",
		"root": {"Creature List": []},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{
					"name": "Creature List",
					"type": GFFParser.FIELD_LIST,
					"items": [{"struct_type": 1, "fields": []}],
				},
			],
		},
	}
