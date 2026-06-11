@tool
extends RefCounted
class_name KotorModdingPipeline

const KotorGameFS := preload("../../gamefs/kotor_gamefs.gd")
const ERFParser := preload("../../formats/erf_parser.gd")
const ERFWriter := preload("../../formats/erf_writer.gd")
const TwoDaParser := preload("../../formats/twoda_parser.gd")
const TLKParser := preload("../../formats/tlk_parser.gd")
const TwoDaWriter := preload("../../formats/twoda_writer.gd")
const TLKWriter := preload("../../formats/tlk_writer.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const TwoDaResource := preload("../../resources/twoda_resource.gd")
const TLKResource := preload("../../resources/tlk_resource.gd")
const GFFResource := preload("../../resources/gff_resource.gd")
const SSFWriter := preload("../../formats/ssf_writer.gd")
const SSFResource := preload("../../resources/ssf_resource.gd")
const LIPWriter := preload("../../formats/lip_writer.gd")
const LIPResource := preload("../../resources/lip_resource.gd")
const LTRWriter := preload("../../formats/ltr_writer.gd")
const LTRResource := preload("../../resources/ltr_resource.gd")
const TPCWriter := preload("../../formats/tpc_writer.gd")
const GFFCompare := preload("../../formats/gff_compare.gd")
const SSFCompare := preload("../../formats/ssf_compare.gd")
const LIPCompare := preload("../../formats/lip_compare.gd")
const TPCCompare := preload("../../formats/tpc_compare.gd")
const MdlCompare := preload("../../formats/mdl_compare.gd")
const BwmCompare := preload("../../formats/bwm_compare.gd")
const WavCompare := preload("../../formats/wav_compare.gd")

const SOURCE_OVERRIDE := "override"
const DETAIL_SAMPLE_LIMIT := 5


static func export_gamefs_entry(gamefs: RefCounted, entry: Dictionary, target_path: String) -> Dictionary:
	if gamefs == null or entry.is_empty():
		return _result(false, "invalid", "No GameFS resource is selected")
	return export_payload_to_path(target_path, gamefs.load_resource_entry_bytes(entry), _entry_file_name(entry))


static func export_erf_entry(entry: ERFParser.ERFEntry, target_path: String) -> Dictionary:
	if entry == null:
		return _result(false, "invalid", "No archive entry is selected")
	return export_payload_to_path(target_path, entry.read_data(), "%s.%s" % [entry.resref, entry.extension])


static func export_payload_to_path(target_path: String, payload: Variant, fallback_name: String = "") -> Dictionary:
	if target_path.is_empty():
		return _result(false, "invalid", "Choose a destination file path")
	var serialized := _serialize_payload(target_path if not target_path.is_empty() else fallback_name, payload)
	if not serialized.get("ok", false):
		return serialized
	return _write_serialized_payload(target_path, serialized, false)


static func write_payload_to_path_with_backup(
	target_path: String,
	payload: Variant,
	fallback_name: String = ""
) -> Dictionary:
	if target_path.is_empty():
		return _result(false, "invalid", "Choose a destination file path")
	var serialized := _serialize_payload(target_path if not target_path.is_empty() else fallback_name, payload)
	if not serialized.get("ok", false):
		return serialized
	return _write_serialized_payload(target_path, serialized, true)


static func serialize_payload(file_name: String, payload: Variant) -> Dictionary:
	return _serialize_payload(file_name, payload)


static func install_gamefs_entry_to_override(gamefs: RefCounted, entry: Dictionary) -> Dictionary:
	if gamefs == null or entry.is_empty():
		return _result(false, "invalid", "No GameFS resource is selected")
	return install_payload_to_override(gamefs, _entry_file_name(entry), gamefs.load_resource_entry_bytes(entry))


static func install_erf_entry_to_override(gamefs: RefCounted, entry: ERFParser.ERFEntry) -> Dictionary:
	if entry == null:
		return _result(false, "invalid", "No archive entry is selected")
	return install_payload_to_override(gamefs, "%s.%s" % [entry.resref, entry.extension], entry.read_data())


static func install_payload_to_override(gamefs: RefCounted, file_name: String, payload: Variant) -> Dictionary:
	if gamefs == null:
		return _result(false, "invalid", "Game install is not available")
	file_name = file_name.get_file()
	if file_name.is_empty():
		return _result(false, "invalid", "A target file name is required")
	var serialized := _serialize_payload(file_name, payload)
	if not serialized.get("ok", false):
		return serialized
	var override_dir: String = gamefs.ensure_override_path()
	if override_dir.is_empty():
		return _result(false, "invalid", "Could not create the override directory")
	return _write_serialized_payload(override_dir.path_join(file_name), serialized, true)


static func compare_gamefs_resource(gamefs: RefCounted, resref: String, resource_type: Variant) -> Dictionary:
	if gamefs == null:
		return _result(false, "invalid", "Game install is not available")
	var override_entry: Dictionary = gamefs.resolve_resource_from_source(resref, resource_type, SOURCE_OVERRIDE)
	var core_entry: Dictionary = _first_non_override_variant(gamefs.list_resource_variants(resref, resource_type))
	if override_entry.is_empty() and core_entry.is_empty():
		return _result(false, "missing", "No matching install resource was found")
	if override_entry.is_empty():
		return _result(true, "no_override", "No override copy exists for %s.%s" % [
			resref,
			core_entry.get("extension", ""),
		], {
			"resref": resref,
			"extension": core_entry.get("extension", ""),
			"core_entry": core_entry,
		})
	if core_entry.is_empty():
		return _result(true, "override_only", "Override exists for %s.%s but no core source was indexed" % [
			resref,
			override_entry.get("extension", ""),
		], {
			"resref": resref,
			"extension": override_entry.get("extension", ""),
			"override_entry": override_entry,
		})

	var override_bytes: PackedByteArray = gamefs.load_resource_entry_bytes(override_entry)
	var core_bytes: PackedByteArray = gamefs.load_resource_entry_bytes(core_entry)
	var extension := str(override_entry.get("extension", core_entry.get("extension", ""))).to_lower()
	if _packed_bytes_equal(core_bytes, override_bytes) and not _mdl_sidecar_differs(
		extension,
		gamefs,
		resref,
		core_entry,
		override_entry
	):
		return _result(true, "identical", "Override matches core for %s.%s" % [
			resref,
			override_entry.get("extension", ""),
		], {
			"resref": resref,
			"extension": override_entry.get("extension", ""),
			"core_entry": core_entry,
			"override_entry": override_entry,
			"core_size": core_bytes.size(),
			"override_size": override_bytes.size(),
			"details": "Binary-identical (%d bytes)." % core_bytes.size(),
		})
	var detail_report := _build_difference_report(
		extension,
		core_bytes,
		override_bytes,
		gamefs,
		resref,
		core_entry,
		override_entry
	)
	return _result(true, "different", "Override differs from core for %s.%s" % [resref, extension], {
		"resref": resref,
		"extension": extension,
		"core_entry": core_entry,
		"override_entry": override_entry,
		"core_size": core_bytes.size(),
		"override_size": override_bytes.size(),
		"details": detail_report,
	})


static func compare_all_overrides(gamefs: RefCounted) -> Dictionary:
	if gamefs == null:
		return _result(false, "invalid", "Game install is not available")
	if not gamefs.has_method("list_core_resources"):
		return _result(false, "invalid", "Game install index is unavailable")

	var override_entries: Array = gamefs.list_core_resources("", null, SOURCE_OVERRIDE, 0)
	if override_entries.is_empty():
		var empty_counts := {
			"total": 0,
			"identical": 0,
			"different": 0,
			"override_only": 0,
		}
		return _result(true, "empty", "No override resources found.", {
			"counts": empty_counts,
			"entries": [],
			"details": "No override resources found.",
		})

	var counts := {
		"total": override_entries.size(),
		"identical": 0,
		"different": 0,
		"override_only": 0,
	}
	var entry_results: Array = []
	for entry: Dictionary in override_entries:
		var resref := str(entry.get("resref", ""))
		var resource_type := int(entry.get("resource_type", -1))
		var extension := str(entry.get("extension", ""))
		var compare := compare_gamefs_resource(gamefs, resref, resource_type)
		var status := str(compare.get("status", "unknown"))
		match status:
			"identical":
				counts["identical"] = int(counts.get("identical", 0)) + 1
			"different":
				counts["different"] = int(counts.get("different", 0)) + 1
			"override_only":
				counts["override_only"] = int(counts.get("override_only", 0)) + 1
		entry_results.append({
			"label": "%s.%s" % [resref, extension],
			"status": status,
			"message": str(compare.get("message", "")),
			"details": str(compare.get("details", "")),
			"core_entry": compare.get("core_entry", {}),
			"override_entry": compare.get("override_entry", {}),
		})

	var report := build_override_compare_report(counts, entry_results)
	var summary := (
		"Override scan: %d total, %d different, %d identical, %d override-only."
		% [
			int(counts.get("total", 0)),
			int(counts.get("different", 0)),
			int(counts.get("identical", 0)),
			int(counts.get("override_only", 0)),
		]
	)
	return _result(true, "scanned", summary, {
		"counts": counts,
		"entries": entry_results,
		"details": report,
	})


static func build_override_compare_report(counts: Dictionary, entry_results: Array) -> String:
	var lines: Array[String] = []
	lines.append("Override compare scan (%d resources)" % int(counts.get("total", 0)))
	lines.append(
		"  Identical: %d | Different: %d | Override-only: %d"
		% [
			int(counts.get("identical", 0)),
			int(counts.get("different", 0)),
			int(counts.get("override_only", 0)),
		]
	)
	lines.append("")

	for raw_entry in entry_results:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw_entry
		var status := str(item.get("status", ""))
		if status == "identical":
			continue
		lines.append("[%s] %s" % [status.to_upper(), str(item.get("label", ""))])
		var message := str(item.get("message", "")).strip_edges()
		if not message.is_empty():
			lines.append(message)
		var details := str(item.get("details", "")).strip_edges()
		if status == "different" and not details.is_empty():
			lines.append(details)
		lines.append("")

	return "\n".join(lines).strip_edges()


static func format_compare_result_text(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var lines: Array[String] = []
	var message := str(result.get("message", "")).strip_edges()
	if not message.is_empty():
		lines.append(message)
	if result.has("core_entry"):
		var core_entry: Dictionary = result.get("core_entry", {})
		lines.append("Core: %s" % str(core_entry.get("location", "")))
	if result.has("override_entry"):
		var override_entry: Dictionary = result.get("override_entry", {})
		lines.append("Override: %s" % str(override_entry.get("location", "")))
	var details := str(result.get("details", "")).strip_edges()
	if not details.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append(details)
	return "\n".join(lines).strip_edges()


static func export_text_report_to_path(target_path: String, text: String) -> Dictionary:
	var path := target_path.strip_edges()
	if path.is_empty():
		return _result(false, "invalid", "Choose a report file path.")
	var body := text.strip_edges()
	if body.is_empty():
		return _result(false, "invalid", "No compare report text to write.")
	var bytes := body.to_utf8_buffer()
	if write_bytes(path, bytes) != OK:
		return _result(false, "write_failed", "Could not write compare report: %s" % path)
	return _result(true, "exported", "Compare report saved to %s" % path, {
		"path": path,
		"size": bytes.size(),
	})


static func export_compare_result_to_path(target_path: String, result: Dictionary) -> Dictionary:
	return export_text_report_to_path(target_path, format_compare_result_text(result))


static func _entry_file_name(entry: Dictionary) -> String:
	return "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]


static func _serialize_payload(file_name: String, payload: Variant) -> Dictionary:
	if payload is PackedByteArray:
		return {
			"ok": true,
			"type": "bytes",
			"payload": payload,
			"size": (payload as PackedByteArray).size(),
			"file_name": file_name.get_file(),
		}
	if payload is String:
		var text_bytes := String(payload).to_ascii_buffer()
		return {
			"ok": true,
			"type": "bytes",
			"payload": text_bytes,
			"size": text_bytes.size(),
			"file_name": file_name.get_file(),
		}

	var extension := file_name.get_extension().to_lower()
	match extension:
		"2da":
			if payload is TwoDaResource:
				var twoda_bytes := TwoDaWriter.serialize(payload as TwoDaResource).to_ascii_buffer()
				return {
					"ok": true,
					"type": "bytes",
					"payload": twoda_bytes,
					"size": twoda_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"tlk":
			if payload is TLKResource:
				var tlk_bytes := TLKWriter.serialize(payload as TLKResource)
				return {
					"ok": true,
					"type": "bytes",
					"payload": tlk_bytes,
					"size": tlk_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"ssf":
			if payload is SSFResource:
				var ssf_bytes := SSFWriter.serialize(payload as SSFResource)
				if ssf_bytes.is_empty():
					return _result(false, "invalid", "Failed to serialize %s" % file_name.get_file())
				return {
					"ok": true,
					"type": "bytes",
					"payload": ssf_bytes,
					"size": ssf_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"lip":
			if payload is LIPResource:
				var lip_bytes := LIPWriter.serialize(payload as LIPResource)
				if lip_bytes.is_empty():
					return _result(false, "invalid", "Failed to serialize %s" % file_name.get_file())
				return {
					"ok": true,
					"type": "bytes",
					"payload": lip_bytes,
					"size": lip_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"ltr":
			if payload is LTRResource:
				var ltr_bytes := LTRWriter.serialize(payload as LTRResource)
				if ltr_bytes.is_empty():
					return _result(false, "invalid", "Failed to serialize %s" % file_name.get_file())
				return {
					"ok": true,
					"type": "bytes",
					"payload": ltr_bytes,
					"size": ltr_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"tpc":
			if payload is PackedByteArray:
				var tpc_bytes := TPCWriter.serialize_passthrough(payload as PackedByteArray)
				if tpc_bytes.is_empty():
					return _result(false, "invalid", "Failed to serialize %s" % file_name.get_file())
				return {
					"ok": true,
					"type": "bytes",
					"payload": tpc_bytes,
					"size": tpc_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"are", "dlg", "gff", "git", "ifo", "jrl", "pth", "utc", "utd", "ute", "uti", "utm", "utp", "uts", "utt", "utw":
			if payload is GFFResource:
				var gff_bytes := GFFWriter.serialize(payload as GFFResource)
				if gff_bytes.is_empty():
					return _result(false, "invalid", "Failed to serialize %s" % file_name.get_file())
				return {
					"ok": true,
					"type": "bytes",
					"payload": gff_bytes,
					"size": gff_bytes.size(),
					"file_name": file_name.get_file(),
				}
		"erf", "rim", "mod", "sav":
			if payload is Dictionary and payload.has("entries") and payload.has("file_type"):
				var file_type := str(payload.get("file_type", "ERF "))
				var entries: Array = payload.get("entries", [])
				var erf_bytes := ERFWriter.repack(file_type, entries)
				if erf_bytes.is_empty():
					return _result(false, "invalid", "Failed to serialize %s" % file_name.get_file())
				return {
					"ok": true,
					"type": "bytes",
					"payload": erf_bytes,
					"size": erf_bytes.size(),
					"file_name": file_name.get_file(),
				}
	return _result(false, "invalid", "Unsupported payload for %s" % file_name.get_file())


static func _write_serialized_payload(target_path: String, serialized: Dictionary, create_backup: bool) -> Dictionary:
	var absolute_target := target_path
	if absolute_target.is_empty() or not absolute_target.is_absolute_path():
		return _result(false, "invalid", "Target path must be absolute")
	var parent_dir := absolute_target.get_base_dir()
	var dir_err := DirAccess.make_dir_recursive_absolute(parent_dir)
	if dir_err != OK and not DirAccess.dir_exists_absolute(parent_dir):
		return _result(false, "io_error", "Could not create %s" % parent_dir, {
			"error": dir_err,
			"target_path": absolute_target,
		})

	var payload: PackedByteArray = serialized.get("payload", PackedByteArray())
	var backup_path := ""
	if FileAccess.file_exists(absolute_target):
		var existing := _read_file_bytes(absolute_target)
		if _packed_bytes_equal(existing, payload):
			return _result(true, "unchanged", "%s is already up to date" % absolute_target.get_file(), {
				"target_path": absolute_target,
				"backup_path": "",
				"written_bytes": payload.size(),
			})
		if create_backup:
			backup_path = absolute_target + ".bak"
			var backup_err := _store_bytes(backup_path, existing)
			if backup_err != OK:
				return _result(false, "io_error", "Failed to back up %s" % absolute_target.get_file(), {
					"error": backup_err,
					"target_path": absolute_target,
					"backup_path": backup_path,
				})

	var write_err := _store_bytes(absolute_target, payload)
	if write_err != OK:
		return _result(false, "io_error", "Failed to write %s" % absolute_target.get_file(), {
			"error": write_err,
			"target_path": absolute_target,
			"backup_path": backup_path,
		})
	return _result(true, "written", "Wrote %s" % absolute_target.get_file(), {
		"target_path": absolute_target,
		"backup_path": backup_path,
		"written_bytes": payload.size(),
	})


static func _store_bytes(path: String, bytes: PackedByteArray) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	var err := file.get_error()
	file.close()
	return OK if err == OK or err == ERR_FILE_EOF else err


static func _read_file_bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return bytes


static func read_file_bytes(path: String) -> PackedByteArray:
	return _read_file_bytes(path)


static func _packed_bytes_equal(a: PackedByteArray, b: PackedByteArray) -> bool:
	if a.size() != b.size():
		return false
	for index in a.size():
		if a[index] != b[index]:
			return false
	return true


static func bytes_equal(a: PackedByteArray, b: PackedByteArray) -> bool:
	return _packed_bytes_equal(a, b)


static func write_bytes(path: String, bytes: PackedByteArray) -> Error:
	return _store_bytes(path, bytes)


static func _first_non_override_variant(variants: Array[Dictionary]) -> Dictionary:
	for entry: Dictionary in variants:
		if str(entry.get("source", "")).to_lower() != SOURCE_OVERRIDE:
			return entry.duplicate(true)
	return {}


static func _build_difference_report(
		extension: String,
		base_bytes: PackedByteArray,
		mod_bytes: PackedByteArray,
		gamefs: RefCounted = null,
		resref: String = "",
		base_entry: Dictionary = {},
		mod_entry: Dictionary = {}
) -> String:
	match extension:
		"2da":
			return _build_2da_difference_report(base_bytes, mod_bytes)
		"tlk":
			return _build_tlk_difference_report(base_bytes, mod_bytes)
		"ssf":
			var ssf_report := SSFCompare.build_difference_report(base_bytes, mod_bytes)
			if not ssf_report.is_empty():
				return ssf_report
			return _build_binary_difference_report(base_bytes, mod_bytes)
		"lip":
			var lip_report := LIPCompare.build_difference_report(base_bytes, mod_bytes)
			if not lip_report.is_empty():
				return lip_report
			return _build_binary_difference_report(base_bytes, mod_bytes)
		"tpc":
			var tpc_report := TPCCompare.build_difference_report(base_bytes, mod_bytes)
			if not tpc_report.is_empty():
				return tpc_report
			return _build_binary_difference_report(base_bytes, mod_bytes)
		"wav":
			var wav_report := WavCompare.build_difference_report(base_bytes, mod_bytes)
			if not wav_report.is_empty():
				return wav_report
			return _build_binary_difference_report(base_bytes, mod_bytes)
		"mdl":
			var base_mdx := _load_paired_mdx_bytes(gamefs, resref, base_entry)
			var mod_mdx := _load_paired_mdx_bytes(gamefs, resref, mod_entry)
			var mdl_report := MdlCompare.build_difference_report(base_bytes, mod_bytes, base_mdx, mod_mdx)
			if not mdl_report.is_empty():
				return mdl_report
			return _build_binary_difference_report(base_bytes, mod_bytes)
		"wok":
			var wok_report := BwmCompare.build_difference_report(base_bytes, mod_bytes)
			if not wok_report.is_empty():
				return wok_report
			return _build_binary_difference_report(base_bytes, mod_bytes)
		_:
			if GFFCompare.is_gff_extension(extension):
				var gff_report := GFFCompare.build_difference_report(base_bytes, mod_bytes)
				if not gff_report.is_empty():
					return gff_report
			return _build_binary_difference_report(base_bytes, mod_bytes)


static func _mdl_sidecar_differs(
		extension: String,
		gamefs: RefCounted,
		resref: String,
		base_entry: Dictionary,
		mod_entry: Dictionary
) -> bool:
	if extension != "mdl":
		return false
	var base_mdx := _load_paired_mdx_bytes(gamefs, resref, base_entry)
	var mod_mdx := _load_paired_mdx_bytes(gamefs, resref, mod_entry)
	return not _packed_bytes_equal(base_mdx, mod_mdx)


static func _load_paired_mdx_bytes(gamefs: RefCounted, resref: String, entry: Dictionary) -> PackedByteArray:
	if gamefs == null or entry.is_empty() or resref.is_empty():
		return PackedByteArray()
	if not gamefs.has_method("resolve_resource_from_source") or not gamefs.has_method("load_resource_entry_bytes"):
		return PackedByteArray()
	var source := str(entry.get("source", "")).strip_edges()
	if source.is_empty():
		return PackedByteArray()
	var mdx_entry: Dictionary = gamefs.resolve_resource_from_source(resref, "mdx", source)
	if mdx_entry.is_empty():
		return PackedByteArray()
	return gamefs.load_resource_entry_bytes(mdx_entry)


static func _build_binary_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	var first_diff := -1
	var limit := mini(base_bytes.size(), mod_bytes.size())
	for index in range(limit):
		if base_bytes[index] != mod_bytes[index]:
			first_diff = index
			break
	if first_diff < 0 and base_bytes.size() != mod_bytes.size():
		first_diff = limit
	return "Binary differs: core %d B, override %d B, first differing byte @ 0x%X." % [
		base_bytes.size(),
		mod_bytes.size(),
		maxi(first_diff, 0),
	]


static func _build_2da_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	var base := TwoDaParser.parse_bytes(base_bytes)
	var mod := TwoDaParser.parse_bytes(mod_bytes)
	if base.is_empty() or mod.is_empty():
		return _build_binary_difference_report(base_bytes, mod_bytes)

	var base_columns: Array = []
	for column in base.get("columns", PackedStringArray()):
		base_columns.append(str(column))
	var mod_columns: Array = []
	for column in mod.get("columns", PackedStringArray()):
		mod_columns.append(str(column))
	var added_columns := _string_difference(mod_columns, base_columns)
	var removed_columns := _string_difference(base_columns, mod_columns)
	var union_columns := _merge_strings(base_columns, mod_columns)
	var base_rows: Array = base.get("rows", [])
	var mod_rows: Array = mod.get("rows", [])
	var added_rows := 0
	var removed_rows := 0
	var changed_cells := 0
	var samples: Array[String] = []

	for row_index in range(maxi(base_rows.size(), mod_rows.size())):
		if row_index >= base_rows.size():
			added_rows += 1
			if samples.size() < DETAIL_SAMPLE_LIMIT:
				samples.append("row %d added" % row_index)
			continue
		if row_index >= mod_rows.size():
			removed_rows += 1
			if samples.size() < DETAIL_SAMPLE_LIMIT:
				samples.append("row %d removed" % row_index)
			continue

		var base_row: Dictionary = base_rows[row_index]
		var mod_row: Dictionary = mod_rows[row_index]
		for column in union_columns:
			var base_value := _value_text(base_row.get(column, null))
			var mod_value := _value_text(mod_row.get(column, null))
			if base_value == mod_value:
				continue
			changed_cells += 1
			if samples.size() < DETAIL_SAMPLE_LIMIT:
				samples.append("row %d %s: %s -> %s" % [row_index, column, base_value, mod_value])

	var parts: Array[String] = []
	parts.append("2DA differs")
	parts.append("%d changed cells" % changed_cells)
	if added_rows > 0:
		parts.append("%d added rows" % added_rows)
	if removed_rows > 0:
		parts.append("%d removed rows" % removed_rows)
	if not added_columns.is_empty():
		parts.append("added cols: %s" % ", ".join(added_columns))
	if not removed_columns.is_empty():
		parts.append("removed cols: %s" % ", ".join(removed_columns))
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _build_tlk_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	var base := TLKParser.parse_bytes(base_bytes)
	var mod := TLKParser.parse_bytes(mod_bytes)
	if base.is_empty() or mod.is_empty():
		return _build_binary_difference_report(base_bytes, mod_bytes)

	var base_entries: Array = base.get("entries", [])
	var mod_entries: Array = mod.get("entries", [])
	var added_entries := maxi(mod_entries.size() - base_entries.size(), 0)
	var removed_entries := maxi(base_entries.size() - mod_entries.size(), 0)
	var changed_text := 0
	var changed_meta := 0
	var samples: Array[String] = []

	for strref in range(mini(base_entries.size(), mod_entries.size())):
		var base_entry = base_entries[strref]
		var mod_entry = mod_entries[strref]
		var base_text := String(base_entry.text)
		var mod_text := String(mod_entry.text)
		if base_text != mod_text:
			changed_text += 1
			if samples.size() < DETAIL_SAMPLE_LIMIT:
				samples.append("StrRef %d text changed" % strref)
		elif int(base_entry.flags) != int(mod_entry.flags) or String(base_entry.sound_resref) != String(mod_entry.sound_resref):
			changed_meta += 1
			if samples.size() < DETAIL_SAMPLE_LIMIT:
				samples.append("StrRef %d metadata changed" % strref)

	var parts: Array[String] = []
	parts.append("TLK differs")
	parts.append("%d changed strings" % changed_text)
	if changed_meta > 0:
		parts.append("%d metadata-only changes" % changed_meta)
	if added_entries > 0:
		parts.append("%d added entries" % added_entries)
	if removed_entries > 0:
		parts.append("%d removed entries" % removed_entries)
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _string_difference(left: Array, right: Array) -> Array[String]:
	var right_lookup := {}
	for value in right:
		right_lookup[str(value)] = true
	var results: Array[String] = []
	for value in left:
		var text := str(value)
		if not right_lookup.has(text):
			results.append(text)
	return results


static func _merge_strings(first: Array, second: Array) -> Array[String]:
	var lookup := {}
	var merged: Array[String] = []
	for values in [first, second]:
		for value in values:
			var text := str(value)
			if lookup.has(text):
				continue
			lookup[text] = true
			merged.append(text)
	return merged


static func _value_text(value: Variant) -> String:
	return "****" if value == null else str(value)


static func _result(ok: bool, status: String, message: String, extra: Dictionary = {}) -> Dictionary:
	var result := {
		"ok": ok,
		"status": status,
		"message": message,
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result
