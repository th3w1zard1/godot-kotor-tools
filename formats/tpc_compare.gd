## Semantic TPC difference summaries for install compare reports.
class_name TPCCompare

const TPCReader := preload("tpc_reader.gd")
const TPCWriter := preload("tpc_writer.gd")

const HEADER_SIZE := TPCReader.HEADER_SIZE
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

	var base_data_size := int(base.get("data_size", 0))
	var mod_data_size := int(mod.get("data_size", 0))
	if _mip_payload(base_bytes, base_data_size) != _mip_payload(mod_bytes, mod_data_size):
		change_count += 1
		_append_sample(
			samples,
			"pixel payload differs (core %d B, override %d B)" % [
				base_data_size,
				mod_data_size,
			]
		)

	change_count += _append_txi_samples(samples, base_bytes, mod_bytes)

	if change_count == 0:
		return ""

	var parts: Array[String] = ["TPC differs", "%d changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _mip_payload(tpc_bytes: PackedByteArray, data_size: int) -> PackedByteArray:
	if data_size <= 0:
		return PackedByteArray()
	var end := mini(HEADER_SIZE + data_size, tpc_bytes.size())
	if end <= HEADER_SIZE:
		return PackedByteArray()
	return tpc_bytes.slice(HEADER_SIZE, end)


static func _append_txi_samples(
		samples: Array[String],
		base_bytes: PackedByteArray,
		mod_bytes: PackedByteArray
) -> int:
	var base_txi := TPCWriter.read_txi_bytes(base_bytes)
	var mod_txi := TPCWriter.read_txi_bytes(mod_bytes)
	if base_txi == mod_txi:
		return 0

	var change_count := 0
	var base_present := not base_txi.is_empty()
	var mod_present := not mod_txi.is_empty()
	if base_present != mod_present:
		change_count += 1
		_append_sample(
			samples,
			"TXI sidecar: %s -> %s" % [
				"present" if base_present else "absent",
				"present" if mod_present else "absent",
			]
		)
		return change_count

	if base_txi.size() != mod_txi.size():
		change_count += 1
		_append_sample(
			samples,
			"TXI size: %d -> %d B" % [base_txi.size(), mod_txi.size()]
		)

	change_count += _append_txi_line_samples(samples, base_txi, mod_txi)
	if change_count == 0:
		change_count += 1
		_append_sample(
			samples,
			"TXI payload differs (%d B core, %d B override)" % [
				base_txi.size(),
				mod_txi.size(),
			]
		)
	return change_count


static func _append_txi_line_samples(
		samples: Array[String],
		base_txi: PackedByteArray,
		mod_txi: PackedByteArray
) -> int:
	var base_text := _txi_text(base_txi)
	var mod_text := _txi_text(mod_txi)
	if base_text == mod_text:
		return 0

	var base_lines := base_text.split("\n", false)
	var mod_lines := mod_text.split("\n", false)
	var max_lines := maxi(base_lines.size(), mod_lines.size())
	var change_count := 0

	for line_index in max_lines:
		var base_line := base_lines[line_index] if line_index < base_lines.size() else ""
		var mod_line := mod_lines[line_index] if line_index < mod_lines.size() else ""
		if base_line == mod_line:
			continue
		change_count += 1
		if base_line.is_empty():
			_append_sample(samples, "TXI line %d: (added) %s" % [line_index + 1, mod_line])
		elif mod_line.is_empty():
			_append_sample(samples, "TXI line %d: (removed) %s" % [line_index + 1, base_line])
		else:
			_append_sample(
				samples,
				"TXI line %d: %s -> %s" % [line_index + 1, base_line, mod_line]
			)

	return change_count


static func _txi_text(txi_bytes: PackedByteArray) -> String:
	if txi_bytes.is_empty():
		return ""
	return txi_bytes.get_string_from_utf8().strip_edges()


static func _append_sample(samples: Array[String], line: String) -> void:
	if samples.size() < SAMPLE_LIMIT and not samples.has(line):
		samples.append(line)
