## Semantic MDL difference summaries for install compare reports.
class_name MdlCompare

const MdlModelMetadataHelper := preload("../editor/tools/mdl_model_metadata_helper.gd")

const SAMPLE_LIMIT := 5


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(
		base_bytes: PackedByteArray,
		mod_bytes: PackedByteArray,
		base_mdx: PackedByteArray = PackedByteArray(),
		mod_mdx: PackedByteArray = PackedByteArray()
) -> String:
	if base_bytes == mod_bytes and base_mdx == mod_mdx:
		return ""

	var base := MdlModelMetadataHelper.summarize_bytes(base_bytes, base_mdx)
	var mod := MdlModelMetadataHelper.summarize_bytes(mod_bytes, mod_mdx)
	if not base.get("ok", false) or not mod.get("ok", false):
		return ""

	var change_count := 0
	var samples: Array[String] = []

	var base_name := str(base.get("model_name", ""))
	var mod_name := str(mod.get("model_name", ""))
	if base_name != mod_name:
		change_count += 1
		_append_sample(samples, "model name: %s -> %s" % [base_name, mod_name])

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

	var base_bounds: AABB = base.get("bounds", AABB())
	var mod_bounds: AABB = mod.get("bounds", AABB())
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

	change_count += _append_mdx_samples(samples, base_mdx, mod_mdx)

	if base_bytes.size() != mod_bytes.size():
		change_count += 1
		_append_sample(
			samples,
			"MDL size: %d -> %d B" % [base_bytes.size(), mod_bytes.size()]
		)

	if change_count == 0:
		change_count += 1
		_append_sample(
			samples,
			"mesh payload differs (%d B core, %d B override)" % [
				base_bytes.size(),
				mod_bytes.size(),
			]
		)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["MDL differs", "%d changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _append_mdx_samples(
		samples: Array[String],
		base_mdx: PackedByteArray,
		mod_mdx: PackedByteArray
) -> int:
	if base_mdx == mod_mdx:
		return 0

	var change_count := 0
	var base_present := not base_mdx.is_empty()
	var mod_present := not mod_mdx.is_empty()
	if base_present != mod_present:
		change_count += 1
		_append_sample(
			samples,
			"MDX sidecar: %s -> %s" % [
				"present" if base_present else "absent",
				"present" if mod_present else "absent",
			]
		)
	elif base_mdx.size() != mod_mdx.size():
		change_count += 1
		_append_sample(
			samples,
			"MDX size: %d -> %d B" % [base_mdx.size(), mod_mdx.size()]
		)
	else:
		change_count += 1
		_append_sample(
			samples,
			"MDX payload differs (%d B core, %d B override)" % [
				base_mdx.size(),
				mod_mdx.size(),
			]
		)
	return change_count


static func _append_sample(samples: Array[String], line: String) -> void:
	if samples.size() < SAMPLE_LIMIT and not samples.has(line):
		samples.append(line)
