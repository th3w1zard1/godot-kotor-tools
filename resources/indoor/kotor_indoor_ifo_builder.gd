## Generate minimal module `.ifo` GFF from `.indoor` layouts (native build slice).
class_name KotorIndoorIfoBuilder

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const IFOResource := preload("../typed/ifo_resource.gd")
const KotorIndoorBuildManifest := preload("./kotor_indoor_build_manifest.gd")
const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")


static func build_from_document(document: KotorIndoorDocument) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}
	if document.get_room_count() <= 0:
		return {"ok": false, "errors": ["Indoor map has no rooms for IFO export."]}

	var module_id := KotorIndoorBuildManifest.normalize_module_id(document.get_module_id())
	var module_name := _module_display_name(document, module_id)
	var resource := _make_ifo_resource(module_id, module_name)
	var bytes := GFFWriter.serialize(resource)
	if bytes.is_empty():
		return {"ok": false, "errors": ["Failed to serialize IFO."]}

	return {
		"ok": true,
		"bytes": bytes,
		"module_id": module_id,
		"module_name": module_name,
		"area_count": 1,
	}


static func _make_ifo_resource(module_id: String, module_name: String) -> IFOResource:
	var resource := IFOResource.new()
	resource.file_type = "IFO"
	resource.gff_data = {
		"Mod_Name": {"strref": 0xFFFFFFFF, "strings": {0: module_name}},
		"Mod_Tag": module_id,
		"Mod_ResRef": module_id,
		"OnModLoad": "",
		"Mod_OnHeartbeat": "",
		"Mod_Area_list": [{"Area_Name": module_id}],
	}
	resource.schema_data = _ifo_schema()
	return resource


static func _ifo_schema() -> Dictionary:
	return {
		"struct_type": 0xFFFFFFFF,
		"fields": [
			{"name": "Mod_Name", "type": GFFParser.FIELD_CEXOLOCSTR},
			{"name": "Mod_Tag", "type": GFFParser.FIELD_CEXOSTRING},
			{"name": "Mod_ResRef", "type": GFFParser.FIELD_CRESREF},
			{"name": "OnModLoad", "type": GFFParser.FIELD_CRESREF},
			{"name": "Mod_OnHeartbeat", "type": GFFParser.FIELD_CRESREF},
			{
				"name": "Mod_Area_list",
				"type": GFFParser.FIELD_LIST,
				"items": [
					{
						"struct_type": 0,
						"fields": [{"name": "Area_Name", "type": GFFParser.FIELD_CEXOSTRING}],
					},
				],
			},
		],
	}


static func _module_display_name(document: KotorIndoorDocument, module_id: String) -> String:
	var display_name := document.get_display_name()
	if display_name.begins_with("Indoor map ("):
		return module_id
	return display_name
