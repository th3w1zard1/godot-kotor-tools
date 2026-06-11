## Headless validation for `.indoor` layouts before mod export.
class_name KotorIndoorLayoutValidator

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("./kotor_indoor_map_io.gd")


static func validate(document: KotorIndoorDocument, kit_library: RefCounted = null) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	if document == null:
		errors.append("No indoor map is loaded.")
		return {"ok": false, "errors": errors, "warnings": warnings}

	var data := document.get_data()
	var warp := str(data.get("warp", "")).strip_edges()
	var module_id := str(data.get("module_id", "")).strip_edges()
	if warp.is_empty() and module_id.is_empty():
		errors.append("Indoor layout has no module ID or warp point.")

	var room_count := document.get_room_count()
	if room_count <= 0:
		errors.append("Indoor map has no rooms; add at least one kit room before export.")

	if kit_library == null:
		kit_library = document.get_kit_library()

	for index in room_count:
		var room := document.get_room_dictionary(index)
		var kit_id := str(room.get("kit", "")).strip_edges()
		var component_id := str(room.get("component", "")).strip_edges()
		if kit_id.is_empty() or component_id.is_empty():
			errors.append("Room %d is missing kit or component." % index)
			continue
		if kit_id == KotorIndoorMapIO.EMBEDDED_KIT_ID:
			if not document.has_embedded_component(component_id):
				errors.append(
					"Room %d references missing embedded component '%s'." % [index, component_id]
				)
		elif kit_library == null:
			errors.append("Room %d uses kit '%s' but no kit library is loaded." % [index, kit_id])
		elif not kit_library.has_method("has_component"):
			errors.append("Room %d uses kit '%s' but the kit library cannot resolve components." % [index, kit_id])
		elif not bool(kit_library.call("has_component", kit_id, component_id)):
			errors.append(
				"Room %d references unknown kit component '%s/%s'." % [index, kit_id, component_id]
			)

	var hook_counts := document.get_hook_connection_counts()
	var open_hooks := int(hook_counts.get("open", 0))
	if open_hooks > 0:
		warnings.append("Layout has %d open door hook(s)." % open_hooks)

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}
