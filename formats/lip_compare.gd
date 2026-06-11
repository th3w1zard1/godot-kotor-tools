## Semantic LIP difference summaries for install compare reports.
class_name LIPCompare

const LIPParser := preload("lip_parser.gd")

const SAMPLE_LIMIT := 5


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	var base := LIPParser.parse_bytes(base_bytes)
	var mod := LIPParser.parse_bytes(mod_bytes)
	if base.is_empty() or mod.is_empty():
		return ""

	var change_count := 0
	var samples: Array[String] = []

	var base_length := float(base.get("length", 0.0))
	var mod_length := float(mod.get("length", 0.0))
	if not is_equal_approx(base_length, mod_length):
		change_count += 1
		_append_sample(samples, "length: %.3fs -> %.3fs" % [base_length, mod_length])

	var base_keyframes: Array = base.get("keyframes", [])
	var mod_keyframes: Array = mod.get("keyframes", [])
	if base_keyframes.size() != mod_keyframes.size():
		change_count += 1
		_append_sample(
			samples,
			"keyframe count: %d -> %d" % [base_keyframes.size(), mod_keyframes.size()]
		)

	var pair_limit := mini(base_keyframes.size(), mod_keyframes.size())
	for index in pair_limit:
		var base_entry: Dictionary = base_keyframes[index]
		var mod_entry: Dictionary = mod_keyframes[index]
		var base_time := float(base_entry.get("time", 0.0))
		var mod_time := float(mod_entry.get("time", 0.0))
		var base_shape := int(base_entry.get("shape", 0))
		var mod_shape := int(mod_entry.get("shape", 0))
		if is_equal_approx(base_time, mod_time) and base_shape == mod_shape:
			continue
		change_count += 1
		_append_sample(
			samples,
			"keyframe %d: %.3fs %s -> %.3fs %s" % [
				index,
				base_time,
				LIPParser.shape_name(base_shape),
				mod_time,
				LIPParser.shape_name(mod_shape),
			]
		)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["LIP differs", "%d changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _append_sample(samples: Array[String], line: String) -> void:
	if samples.size() < SAMPLE_LIMIT and not samples.has(line):
		samples.append(line)
