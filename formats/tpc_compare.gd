## Semantic TPC difference summaries for install compare reports.
class_name TPCCompare

const TPCReader := preload("tpc_reader.gd")

const SAMPLE_LIMIT := 5


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	if base_bytes == mod_bytes:
		return ""

	var base := TPCReader.read_metadata(base_bytes)
	var mod := TPCReader.read_metadata(mod_bytes)
	if not base.get("ok", false) or not mod.get("ok", false):
		return ""

	var change_count := 0
	var samples: Array[String] = []

	if int(base.get("width", 0)) != int(mod.get("width", 0)):
		change_count += 1
		_append_sample(
			samples,
			"width: %d -> %d" % [int(base.get("width", 0)), int(mod.get("width", 0))]
		)

	if int(base.get("height", 0)) != int(mod.get("height", 0)):
		change_count += 1
		_append_sample(
			samples,
			"height: %d -> %d" % [int(base.get("height", 0)), int(mod.get("height", 0))]
		)

	var base_encoding := int(base.get("encoding", 0))
	var mod_encoding := int(mod.get("encoding", 0))
	if base_encoding != mod_encoding:
		change_count += 1
		_append_sample(
			samples,
			"encoding: %s -> %s" % [
				String(base.get("encoding_name", "")),
				String(mod.get("encoding_name", "")),
			]
		)

	if int(base.get("num_mips", 0)) != int(mod.get("num_mips", 0)):
		change_count += 1
		_append_sample(
			samples,
			"mip levels: %d -> %d" % [int(base.get("num_mips", 0)), int(mod.get("num_mips", 0))]
		)

	if int(base.get("data_size", 0)) != int(mod.get("data_size", 0)):
		change_count += 1
		_append_sample(
			samples,
			"data size: %d -> %d B" % [int(base.get("data_size", 0)), int(mod.get("data_size", 0))]
		)

	var base_alpha := float(base.get("alpha_test", 0.0))
	var mod_alpha := float(mod.get("alpha_test", 0.0))
	if not is_equal_approx(base_alpha, mod_alpha):
		change_count += 1
		_append_sample(samples, "alpha_test: %.3f -> %.3f" % [base_alpha, mod_alpha])

	if change_count == 0:
		change_count += 1
		_append_sample(
			samples,
			"pixel payload differs (core %d B, override %d B)" % [
				int(base.get("data_size", 0)),
				int(mod.get("data_size", 0)),
			]
		)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["TPC differs", "%d changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _append_sample(samples: Array[String], line: String) -> void:
	if samples.size() < SAMPLE_LIMIT and not samples.has(line):
		samples.append(line)
