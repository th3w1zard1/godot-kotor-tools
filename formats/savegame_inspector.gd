## formats/savegame_inspector.gd
## Read-only KotOR savegame (.sav SAV ERF) metadata inspector.
##
## Extracts summary fields from embedded savenfo, partytable, and globalvars GFF members.
@tool
class_name SavegameInspector

const ERFParser := preload("./erf_parser.gd")
const GFFParser := preload("./gff_parser.gd")

const KNOWN_GFF_MEMBERS := ["savenfo", "partytable", "globalvars"]
const GLOBALVAR_LIST_FIELDS := ["ValNumber", "ValBoolean", "ValString"]


## Inspect a `.sav` archive from raw bytes.
## Returns a Dictionary with `ok` bool and metadata on success.
static func inspect_bytes(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty():
		return _failure("Save data is empty.")
	var parsed := ERFParser.parse_bytes(bytes)
	if parsed.is_empty():
		return _failure("Failed to parse save archive.")
	var file_type := str(parsed.get("file_type", "")).strip_edges()
	if file_type != "SAV":
		return _failure("Expected a SAV archive, got '%s'." % file_type)

	var entries: Array = parsed.get("entries", [])
	var extension_counts := {}
	var entry_summaries: Array[Dictionary] = []
	for entry in entries:
		if entry == null:
			continue
		var erf_entry := entry as ERFParser.ERFEntry
		if erf_entry == null:
			continue
		var extension := erf_entry.extension.strip_edges().to_lower()
		extension_counts[extension] = int(extension_counts.get(extension, 0)) + 1
		entry_summaries.append({
			"resref": erf_entry.resref,
			"extension": erf_entry.extension,
			"size": erf_entry.size,
		})

	var inspection := {
		"ok": true,
		"file_type": file_type,
		"version": str(parsed.get("version", "")),
		"entry_count": entries.size(),
		"extension_counts": extension_counts,
		"entries": entry_summaries,
		"savenfo": {},
		"partytable": {},
		"globalvars": {},
		"metadata": {},
	}
	inspection["savenfo"] = _inspect_gff_member(parsed, "savenfo", _extract_savenfo)
	inspection["partytable"] = _inspect_gff_member(parsed, "partytable", _extract_partytable)
	inspection["globalvars"] = _inspect_gff_member(parsed, "globalvars", _extract_globalvars)
	inspection["metadata"] = _compose_metadata(inspection)
	return inspection


static func _inspect_gff_member(
	parsed: Dictionary,
	resref: String,
	extractor: Callable
) -> Dictionary:
	var entry := ERFParser.find_entry(parsed, resref)
	if entry == null:
		return {"present": false}
	var payload := entry.read_data()
	if payload.is_empty():
		return {"present": true, "parse_ok": false, "error": "Member payload is empty."}
	var gff := GFFParser.parse_bytes(payload)
	if gff.is_empty():
		return {"present": true, "parse_ok": false, "error": "Failed to parse %s GFF." % resref}
	var root = gff.get("root", {})
	if typeof(root) != TYPE_DICTIONARY:
		return {"present": true, "parse_ok": false, "error": "%s root is not a dictionary." % resref}
	var extracted: Dictionary = extractor.call(root)
	extracted["present"] = true
	extracted["parse_ok"] = true
	extracted["file_type"] = str(gff.get("file_type", "")).strip_edges()
	return extracted


static func _extract_savenfo(root: Dictionary) -> Dictionary:
	var time_played := _coerce_int(root.get("TIMEPLAYED", 0))
	return {
		"save_name": str(root.get("SAVEGAMENAME", "")),
		"last_module": str(root.get("LASTMODULE", "")),
		"area_name": str(root.get("AREANAME", "")),
		"time_played_seconds": time_played,
		"time_played_label": format_play_time(time_played),
	}


static func _extract_partytable(root: Dictionary) -> Dictionary:
	var members = root.get("PT_MEMBERS", [])
	var member_count := 0
	if typeof(members) == TYPE_ARRAY:
		member_count = members.size()
	return {
		"pc_name": str(root.get("PT_PCNAME", "")),
		"member_count": member_count,
	}


static func _extract_globalvars(root: Dictionary) -> Dictionary:
	var variable_counts := {}
	var total := 0
	for field_name in GLOBALVAR_LIST_FIELDS:
		var values = root.get(field_name, [])
		var count := 0
		if typeof(values) == TYPE_ARRAY:
			count = values.size()
		variable_counts[field_name] = count
		total += count
	return {
		"variable_counts": variable_counts,
		"total_variables": total,
	}


static func _compose_metadata(inspection: Dictionary) -> Dictionary:
	var savenfo: Dictionary = inspection.get("savenfo", {})
	var partytable: Dictionary = inspection.get("partytable", {})
	var globalvars: Dictionary = inspection.get("globalvars", {})
	return {
		"save_name": str(savenfo.get("save_name", "")),
		"last_module": str(savenfo.get("last_module", "")),
		"area_name": str(savenfo.get("area_name", "")),
		"time_played_seconds": int(savenfo.get("time_played_seconds", 0)),
		"time_played_label": str(savenfo.get("time_played_label", "")),
		"pc_name": str(partytable.get("pc_name", "")),
		"party_member_count": int(partytable.get("member_count", 0)),
		"global_variable_count": int(globalvars.get("total_variables", 0)),
	}


static func format_play_time(total_seconds: int) -> String:
	var seconds := maxi(total_seconds, 0)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var remainder := seconds % 60
	if hours > 0:
		return "%dh %dm %ds" % [hours, minutes, remainder]
	if minutes > 0:
		return "%dm %ds" % [minutes, remainder]
	return "%ds" % remainder


static func _coerce_int(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			return int(value) if value.is_valid_int() else 0
		_:
			return 0


static func _failure(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
	}
