## Generate KotOR `.vis` ASCII from indoor hook connections (native build slice).
class_name KotorIndoorVisBuilder

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const VISParser := preload("../../formats/vis_parser.gd")


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
	var parent_names: Array[String] = []
	for parent_name in visibility.keys():
		parent_names.append(str(parent_name))
	parent_names.sort()

	var lines: Array[String] = []
	for parent_name in parent_names:
		var children: Array = visibility.get(parent_name, [])
		var child_names: Array[String] = []
		for raw_child in children:
			child_names.append(str(raw_child))
		child_names.sort()
		lines.append("%s %d" % [parent_name, child_names.size()])
		for child_name in child_names:
			lines.append("  %s" % child_name)
	return "\n".join(lines).strip_edges()


static func _build_visibility_map(document: KotorIndoorDocument) -> Dictionary:
	var visibility: Dictionary = {}
	for index in document.get_room_count():
		var parent_name := _room_component_name(document, index)
		if parent_name.is_empty():
			continue
		var child_lookup := {}
		var merged: Array[String] = []
		if visibility.has(parent_name):
			for raw_child in visibility[parent_name]:
				var existing_child := str(raw_child)
				if child_lookup.has(existing_child):
					continue
				child_lookup[existing_child] = true
				merged.append(existing_child)
		for visible_index in document.get_visible_room_indices(index):
			var child_name := _room_component_name(document, visible_index)
			if child_name.is_empty() or child_lookup.has(child_name):
				continue
			child_lookup[child_name] = true
			merged.append(child_name)
		merged.sort()
		visibility[parent_name] = merged
	return visibility


static func _room_component_name(document: KotorIndoorDocument, index: int) -> String:
	var room := document.get_room_dictionary(index)
	return str(room.get("component", "")).strip_edges()


static func parse_built_text(text: String) -> Dictionary:
	return VISParser.parse_text(text)
