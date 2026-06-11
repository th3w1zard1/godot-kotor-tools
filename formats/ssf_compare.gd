## Semantic SSF difference summaries for install compare reports.
class_name SSFCompare

const SSFParser := preload("ssf_parser.gd")

const SAMPLE_LIMIT := 5


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	var base := SSFParser.parse_bytes(base_bytes)
	var mod := SSFParser.parse_bytes(mod_bytes)
	if base.is_empty() or mod.is_empty():
		return ""

	var base_refs: Array = base.get("strrefs", [])
	var mod_refs: Array = mod.get("strrefs", [])
	var change_count := 0
	var samples: Array[String] = []

	for slot_index in SSFParser.SLOT_COUNT:
		var base_value := _strref_at(base_refs, slot_index)
		var mod_value := _strref_at(mod_refs, slot_index)
		if base_value == mod_value:
			continue
		change_count += 1
		if samples.size() < SAMPLE_LIMIT:
			var label := SSFParser.slot_label(slot_index)
			samples.append(
				"%s: %s -> %s" % [label, _strref_text(base_value), _strref_text(mod_value)]
			)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["SSF differs", "%d slot changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _strref_at(strrefs: Array, slot_index: int) -> int:
	if slot_index < 0 or slot_index >= strrefs.size():
		return -1
	return int(strrefs[slot_index])


static func _strref_text(value: int) -> String:
	if value < 0:
		return "(none)"
	return str(value)
