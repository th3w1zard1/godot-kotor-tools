## Generate minimal module `.are` GFF from `.indoor` layouts (native build slice).
class_name KotorIndoorAreBuilder

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const AREResource := preload("../typed/are_resource.gd")
const KotorIndoorBuildManifest := preload("./kotor_indoor_build_manifest.gd")
const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")


static func build_from_document(document: KotorIndoorDocument) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}
	if document.get_room_count() <= 0:
		return {"ok": false, "errors": ["Indoor map has no rooms for ARE export."]}

	var module_id := KotorIndoorBuildManifest.normalize_module_id(document.get_module_id())
	var area_name := _area_display_name(document, module_id)
	var resource := _make_are_resource(document, module_id, area_name)
	var bytes := GFFWriter.serialize(resource)
	if bytes.is_empty():
		return {"ok": false, "errors": ["Failed to serialize ARE."]}

	return {
		"ok": true,
		"bytes": bytes,
		"tag": module_id,
		"area_name": area_name,
		"interior": 1,
	}


static func _make_are_resource(
	document: KotorIndoorDocument,
	module_id: String,
	area_name: String
) -> AREResource:
	var ambient := _ambient_color(document)
	var skybox := _skybox_resref(document)
	var resource := AREResource.new()
	resource.file_type = "ARE"
	resource.gff_data = {
		"Tag": module_id,
		"Name": {"strref": 0xFFFFFFFF, "strings": {0: area_name}},
		"Interior": 1,
		"DynAmbientColor": ambient,
		"SunAmbientColor": ambient,
		"SkyBox": skybox,
		"OnEnter": "",
		"OnExit": "",
		"OnHeartbeat": "",
	}
	resource.schema_data = _are_schema()
	return resource


static func _are_schema() -> Dictionary:
	return {
		"struct_type": 0xFFFFFFFF,
		"fields": [
			{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
			{"name": "Name", "type": GFFParser.FIELD_CEXOLOCSTR},
			{"name": "Interior", "type": GFFParser.FIELD_BYTE},
			{"name": "DynAmbientColor", "type": GFFParser.FIELD_VECTOR},
			{"name": "SunAmbientColor", "type": GFFParser.FIELD_VECTOR},
			{"name": "SkyBox", "type": GFFParser.FIELD_CRESREF},
			{"name": "OnEnter", "type": GFFParser.FIELD_CRESREF},
			{"name": "OnExit", "type": GFFParser.FIELD_CRESREF},
			{"name": "OnHeartbeat", "type": GFFParser.FIELD_CRESREF},
		],
	}


static func _ambient_color(document: KotorIndoorDocument) -> Vector3:
	var lighting: Variant = document.get_data().get("lighting", [0.5, 0.5, 0.5])
	if typeof(lighting) != TYPE_ARRAY or (lighting as Array).size() < 3:
		return Vector3(0.5, 0.5, 0.5)
	var values := lighting as Array
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


static func _skybox_resref(document: KotorIndoorDocument) -> String:
	return str(document.get_data().get("skybox", "")).strip_edges()


static func _area_display_name(document: KotorIndoorDocument, module_id: String) -> String:
	var display_name := document.get_display_name()
	if display_name.begins_with("Indoor map ("):
		return module_id
	return display_name
