## Generate module `.git` GFF from `.indoor` hook connections (native build slice).
class_name KotorIndoorGitBuilder

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GITResource := preload("../typed/git_resource.gd")
const KotorGITDocument := preload("../documents/kotor_git_document.gd")
const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")


static func build_from_document(document: KotorIndoorDocument) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}
	if document.get_room_count() <= 0:
		return {"ok": false, "errors": ["Indoor map has no rooms for GIT export."]}

	var door_list := _build_door_list(document)
	var resource := _make_git_resource(door_list)
	var bytes := GFFWriter.serialize(resource)
	if bytes.is_empty():
		return {"ok": false, "errors": ["Failed to serialize GIT."]}

	return {
		"ok": true,
		"bytes": bytes,
		"door_count": door_list.size(),
		"instance_count": door_list.size(),
	}


static func _build_door_list(document: KotorIndoorDocument) -> Array:
	var doors: Array = []
	for record in document.get_room_records():
		var room_index := int(record.get("index", -1))
		if room_index < 0:
			continue
		for marker in record.get("hook_markers", []):
			if typeof(marker) != TYPE_DICTIONARY:
				continue
			var hook_marker: Dictionary = marker
			var connected_room := int(hook_marker.get("connected_room", -1))
			if connected_room < 0 or room_index >= connected_room:
				continue
			doors.append({
				"TemplateResRef": "",
				"Tag": "indoor_door_%d_%d" % [room_index, int(hook_marker.get("hook_index", 0))],
				"XPosition": float(hook_marker.get("x", 0.0)),
				"YPosition": float(hook_marker.get("y", 0.0)),
				"ZPosition": float(hook_marker.get("z", 0.0)),
				"Bearing": 0.0,
			})
	return doors


static func _make_git_resource(door_list: Array) -> GITResource:
	var gff_data := {}
	var schema_fields: Array = []
	for category in KotorGITDocument.LIST_FIELDS:
		var list_field := String(KotorGITDocument.LIST_FIELDS[category])
		var instances: Array = door_list if list_field == "Door List" else []
		gff_data[list_field] = instances
		schema_fields.append({
			"name": list_field,
			"type": GFFParser.FIELD_LIST,
			"items": [
				{
					"struct_type": 1 if list_field == "Creature List" else 2,
					"fields": _door_instance_fields() if list_field == "Door List" else _generic_instance_fields(),
				},
			],
		})

	var resource := GITResource.new()
	resource.file_type = "GIT"
	resource.gff_data = gff_data
	resource.schema_data = {
		"struct_type": 0xFFFFFFFF,
		"fields": schema_fields,
	}
	return resource


static func _generic_instance_fields() -> Array:
	return [
		{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
		{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
		{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
	]


static func _door_instance_fields() -> Array:
	return [
		{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
		{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
		{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
	]
