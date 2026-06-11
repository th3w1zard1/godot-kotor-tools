## Summarize KotOR BWM/WOK walkmesh metadata for batch export workflows.
class_name BwmMetadataHelper

const BWMParser := preload("../../formats/bwm_parser.gd")


static func summarize_bytes(wok_bytes: PackedByteArray) -> Dictionary:
	if wok_bytes.is_empty():
		return {"ok": false, "message": "WOK payload is empty."}

	var parsed := BWMParser.parse_bytes(wok_bytes)
	if parsed.is_empty():
		return {"ok": false, "message": "Failed to parse WOK walkmesh metadata."}

	return {
		"ok": true,
		"walkmesh_type": int(parsed.get("walkmesh_type", 0)),
		"vertex_count": int(parsed.get("vertex_count", 0)),
		"face_count": int(parsed.get("face_count", 0)),
		"walkable_face_count": _count_walkable_faces(parsed),
		"bounds": BWMParser.compute_bounds(parsed),
	}


static func format_summary(metadata: Dictionary) -> String:
	if not metadata.get("ok", false):
		return str(metadata.get("message", "WOK metadata unavailable."))
	var bounds: AABB = metadata.get("bounds", AABB())
	return "WOK: %d vertices, %d faces (%d walkable), bounds size %s" % [
		int(metadata.get("vertex_count", 0)),
		int(metadata.get("face_count", 0)),
		int(metadata.get("walkable_face_count", 0)),
		bounds.size,
	]


static func _count_walkable_faces(parsed: Dictionary) -> int:
	var walkable := 0
	for raw_face in parsed.get("faces", []):
		if typeof(raw_face) != TYPE_DICTIONARY:
			continue
		var face: Dictionary = raw_face
		if BWMParser.is_walkable_material(int(face.get("material", 0))):
			walkable += 1
	return walkable
