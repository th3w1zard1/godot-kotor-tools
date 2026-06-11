## Semantic BWM/WOK walkmesh difference summaries for install compare reports.
class_name BwmCompare

const BWMParser := preload("bwm_parser.gd")

const SAMPLE_LIMIT := 5


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	if base_bytes == mod_bytes:
		return ""

	var base := BWMParser.parse_bytes(base_bytes)
	var mod := BWMParser.parse_bytes(mod_bytes)
	if base.is_empty() or mod.is_empty():
		return ""

	var change_count := 0
	var samples: Array[String] = []

	var base_vertices := int(base.get("vertex_count", 0))
	var mod_vertices := int(mod.get("vertex_count", 0))
	if base_vertices != mod_vertices:
		change_count += 1
		_append_sample(samples, "vertices: %d -> %d" % [base_vertices, mod_vertices])

	var base_faces := int(base.get("face_count", 0))
	var mod_faces := int(mod.get("face_count", 0))
	if base_faces != mod_faces:
		change_count += 1
		_append_sample(samples, "faces: %d -> %d" % [base_faces, mod_faces])

	var base_walkable := _count_walkable_faces(base)
	var mod_walkable := _count_walkable_faces(mod)
	if base_walkable != mod_walkable:
		change_count += 1
		_append_sample(
			samples,
			"walkable faces: %d -> %d" % [base_walkable, mod_walkable]
		)

	var base_type := int(base.get("walkmesh_type", 0))
	var mod_type := int(mod.get("walkmesh_type", 0))
	if base_type != mod_type:
		change_count += 1
		_append_sample(samples, "walkmesh type: %d -> %d" % [base_type, mod_type])

	var base_position: Vector3 = base.get("position", Vector3.ZERO)
	var mod_position: Vector3 = mod.get("position", Vector3.ZERO)
	if not base_position.is_equal_approx(mod_position):
		change_count += 1
		_append_sample(
			samples,
			"position: %s -> %s" % [base_position, mod_position]
		)

	var base_bounds := BWMParser.compute_bounds(base)
	var mod_bounds := BWMParser.compute_bounds(mod)
	if base_bounds.size != mod_bounds.size:
		change_count += 1
		_append_sample(
			samples,
			"bounds size: %s -> %s" % [base_bounds.size, mod_bounds.size]
		)
	elif base_bounds.position != mod_bounds.position:
		change_count += 1
		_append_sample(
			samples,
			"bounds origin: %s -> %s" % [base_bounds.position, mod_bounds.position]
		)

	if base_bytes.size() != mod_bytes.size():
		change_count += 1
		_append_sample(
			samples,
			"file size: %d -> %d B" % [base_bytes.size(), mod_bytes.size()]
		)

	if change_count == 0:
		change_count += 1
		_append_sample(
			samples,
			"walkmesh payload differs (%d B core, %d B override)" % [
				base_bytes.size(),
				mod_bytes.size(),
			]
		)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["WOK differs", "%d changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _count_walkable_faces(parsed: Dictionary) -> int:
	var walkable := 0
	for raw_face in parsed.get("faces", []):
		if typeof(raw_face) != TYPE_DICTIONARY:
			continue
		var face: Dictionary = raw_face
		if BWMParser.is_walkable_material(int(face.get("material", 0))):
			walkable += 1
	return walkable


static func _append_sample(samples: Array[String], line: String) -> void:
	if samples.size() < SAMPLE_LIMIT and not samples.has(line):
		samples.append(line)
