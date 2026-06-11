## Generate KotOR `.vis` ASCII from indoor hook connections (native build slice).
class_name KotorIndoorVisBuilder

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const VISParser := preload("../../formats/vis_parser.gd")
const VISWriter := preload("../../formats/vis_writer.gd")


static func build_from_document(document: KotorIndoorDocument) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}
	if document.get_room_count() <= 0:
		return {"ok": false, "errors": ["Indoor map has no rooms for VIS export."]}

	var visibility := _build_visibility_map(document)
	if visibility.is_empty():
		return {"ok": false, "errors": ["No room visibility entries could be built."]}

	var text := build_text(visibility)
	var bytes := text.to_utf8_buffer()
	return {
		"ok": true,
		"text": text,
		"bytes": bytes,
		"room_count": visibility.size(),
	}


static func build_text(visibility: Dictionary) -> String:
	return VISWriter.write_visibility_map(visibility)


static func _build_visibility_map(document: KotorIndoorDocument) -> Dictionary:
	var visibility: Dictionary = {}
	for index in document.get_room_count():
		var parent_name := _room_component_name(document, index)
		if parent_name.is_empty():
			continue
		var child_names: Array[String] = []
		var child_lookup := {}
		for visible_index in document.get_visible_room_indices(index):
			var child_name := _room_component_name(document, visible_index)
			if child_name.is_empty() or child_lookup.has(child_name):
				continue
			child_lookup[child_name] = true
			child_names.append(child_name)
		child_names.sort()
		visibility[parent_name] = child_names
	return visibility


static func _room_component_name(document: KotorIndoorDocument, index: int) -> String:
	var room := document.get_room_dictionary(index)
	return str(room.get("component", "")).strip_edges()


static func parse_built_text(text: String) -> Dictionary:
	return VISParser.parse_text(text)
