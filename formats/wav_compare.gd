## Semantic WAV difference summaries for install compare reports.
class_name WavCompare

const WavMetadata := preload("wav_metadata.gd")

const SAMPLE_LIMIT := 5


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	if base_bytes == mod_bytes:
		return ""

	var base := WavMetadata.parse_bytes(base_bytes)
	var mod := WavMetadata.parse_bytes(mod_bytes)
	if not base.get("ok", false) or not mod.get("ok", false):
		return ""

	var change_count := 0
	var samples: Array[String] = []

	var base_format := String(base.get("format_label", ""))
	var mod_format := String(mod.get("format_label", ""))
	if base_format != mod_format:
		change_count += 1
		_append_sample(samples, "format: %s -> %s" % [base_format, mod_format])

	if int(base.get("channels", 0)) != int(mod.get("channels", 0)):
		change_count += 1
		_append_sample(
			samples,
			"channels: %d -> %d" % [int(base.get("channels", 0)), int(mod.get("channels", 0))]
		)

	if int(base.get("sample_rate", 0)) != int(mod.get("sample_rate", 0)):
		change_count += 1
		_append_sample(
			samples,
			"sample rate: %d -> %d Hz" % [
				int(base.get("sample_rate", 0)),
				int(mod.get("sample_rate", 0)),
			]
		)

	if int(base.get("bits_per_sample", 0)) != int(mod.get("bits_per_sample", 0)):
		change_count += 1
		_append_sample(
			samples,
			"bits per sample: %d -> %d" % [
				int(base.get("bits_per_sample", 0)),
				int(mod.get("bits_per_sample", 0)),
			]
		)

	var base_duration := float(base.get("duration_seconds", 0.0))
	var mod_duration := float(mod.get("duration_seconds", 0.0))
	if not is_equal_approx(base_duration, mod_duration):
		change_count += 1
		_append_sample(samples, "duration: %.3fs -> %.3fs" % [base_duration, mod_duration])

	if int(base.get("data_size", 0)) != int(mod.get("data_size", 0)):
		change_count += 1
		_append_sample(
			samples,
			"data size: %d -> %d B" % [int(base.get("data_size", 0)), int(mod.get("data_size", 0))]
		)

	if change_count == 0:
		change_count += 1
		_append_sample(
			samples,
			"audio payload differs (core %d B, override %d B)" % [
				int(base.get("data_size", 0)),
				int(mod.get("data_size", 0)),
			]
		)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["WAV differs", "%d changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _append_sample(samples: Array[String], line: String) -> void:
	if samples.size() < SAMPLE_LIMIT and not samples.has(line):
		samples.append(line)
