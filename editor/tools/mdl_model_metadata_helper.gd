## Summarize KotOR MDL trimesh metadata for install model helper workflows.
class_name MdlModelMetadataHelper

const MDLParser := preload("../../formats/mdl_parser.gd")


static func summarize_bytes(
		mdl_bytes: PackedByteArray,
		mdx_bytes: PackedByteArray = PackedByteArray()
) -> Dictionary:
	if mdl_bytes.is_empty():
		return {"ok": false, "message": "MDL payload is empty."}

	var parsed := MDLParser.parse_bytes(mdl_bytes, mdx_bytes)
	if parsed.is_empty():
		return {"ok": false, "message": "Failed to parse MDL trimesh metadata."}

	var bounds := MDLParser.compute_bounds(parsed)
	return {
		"ok": true,
		"model_name": str(parsed.get("model_name", "")),
		"vertex_count": int(parsed.get("vertex_count", 0)),
		"face_count": int(parsed.get("face_count", 0)),
		"bounds": bounds,
	}


static func format_summary(metadata: Dictionary) -> String:
	if not metadata.get("ok", false):
		return str(metadata.get("message", "MDL metadata unavailable."))
	var bounds: AABB = metadata.get("bounds", AABB())
	return "MDL %s: %d vertices, %d faces, bounds size %s" % [
		str(metadata.get("model_name", "")),
		int(metadata.get("vertex_count", 0)),
		int(metadata.get("face_count", 0)),
		bounds.size,
	]
