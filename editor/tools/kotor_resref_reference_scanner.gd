@tool
extends RefCounted
class_name KotorResRefReferenceScanner

const GFFParser := preload("../../formats/gff_parser.gd")

const SOURCE_OVERRIDE := "override"

const GFF_EXTENSIONS := [
	"utc", "utp", "utd", "uti", "utm", "uts", "utt", "utw",
	"are", "git", "ifo", "jrl", "pth", "fac", "dlg", "gff",
]

const TEXT_EXTENSIONS := ["nss"]


static func scan_install_references(
	gamefs: RefCounted,
	target_resref: String,
	source_filter: String = SOURCE_OVERRIDE,
	limit: int = 64
) -> Dictionary:
	var normalized_target := _normalize_resref(target_resref)
	if gamefs == null or normalized_target.is_empty():
		return _result(false, "missing_target", [], 0, normalized_target)
	if not gamefs.has_method("list_core_resources") or not gamefs.has_method("load_resource_entry_bytes"):
		return _result(false, "gamefs_unavailable", [], 0, normalized_target)

	var entries: Array = gamefs.list_core_resources("", null, source_filter, 0)
	var hits: Array[Dictionary] = []
	var scanned := 0
	for raw_entry in entries:
		if hits.size() >= limit:
			break
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var extension := str(entry.get("extension", "")).strip_edges().to_lower()
		if extension.is_empty():
			continue
		if not (extension in GFF_EXTENSIONS or extension in TEXT_EXTENSIONS):
			continue
		scanned += 1
		var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(entry)
		if bytes.is_empty():
			continue
		var matches: Array[Dictionary] = []
		if extension in GFF_EXTENSIONS:
			matches = _scan_gff_bytes(bytes, normalized_target)
		elif extension in TEXT_EXTENSIONS:
			matches = _scan_text_bytes(bytes, normalized_target)
		if matches.is_empty():
			continue
		hits.append({
			"resref": str(entry.get("resref", "")),
			"extension": extension,
			"source": str(entry.get("source", "")),
			"location": str(entry.get("location", "")),
			"matches": matches,
		})
	return _result(true, "scanned", hits, scanned, normalized_target)


static func format_report(result: Dictionary) -> String:
	if not result.get("ok", false):
		return str(result.get("message", "Reference scan failed."))
	var target := str(result.get("target", ""))
	var hits: Array = result.get("hits", [])
	var scanned := int(result.get("scanned", 0))
	if hits.is_empty():
		return "No references to '%s' found in %d scanned override resources." % [target, scanned]
	var lines: Array[String] = [
		"References to '%s' (%d file(s), %d scanned)" % [target, hits.size(), scanned],
	]
	for hit in hits:
		if typeof(hit) != TYPE_DICTIONARY:
			continue
		var hit_dict: Dictionary = hit
		lines.append(
			"- %s.%s [%s] %s"
			% [
				str(hit_dict.get("resref", "")),
				str(hit_dict.get("extension", "")),
				str(hit_dict.get("source", "")),
				str(hit_dict.get("location", "")),
			]
		)
		for match_record in hit_dict.get("matches", []):
			if typeof(match_record) != TYPE_DICTIONARY:
				continue
			var match_dict: Dictionary = match_record
			lines.append("    %s = %s" % [
				str(match_dict.get("field_path", "")),
				str(match_dict.get("value", "")),
			])
	return "\n".join(lines)


static func _scan_gff_bytes(bytes: PackedByteArray, target_resref: String) -> Array[Dictionary]:
	var parsed := GFFParser.parse_bytes(bytes)
	if parsed.is_empty():
		return []
	var root: Dictionary = parsed.get("root", {})
	var matches: Array[Dictionary] = []
	_collect_matches(root, "", target_resref, matches)
	return matches


static func _scan_text_bytes(bytes: PackedByteArray, target_resref: String) -> Array[Dictionary]:
	var text := bytes.get_string_from_utf8()
	if text.is_empty():
		text = bytes.get_string_from_ascii()
	if text.is_empty():
		return []
	if not text.to_lower().contains(target_resref):
		return []
	return [{"field_path": "text", "value": target_resref}]


static func _collect_matches(
	value: Variant,
	path: String,
	target_resref: String,
	matches: Array[Dictionary]
) -> void:
	match typeof(value):
		TYPE_STRING:
			if _normalize_resref(value) == target_resref:
				matches.append({
					"field_path": path if not path.is_empty() else "/",
					"value": value,
				})
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			for key in dict_value.keys():
				var child_path := "%s/%s" % [path, str(key)] if not path.is_empty() else str(key)
				_collect_matches(dict_value[key], child_path, target_resref, matches)
		TYPE_ARRAY:
			var array_value: Array = value
			for index in range(array_value.size()):
				var child_path := "%s[%d]" % [path, index] if not path.is_empty() else "[%d]" % index
				_collect_matches(array_value[index], child_path, target_resref, matches)


static func _normalize_resref(value: String) -> String:
	return value.strip_edges().to_lower()


static func _result(
	ok: bool,
	reason: String,
	hits: Array,
	scanned: int,
	target: String
) -> Dictionary:
	var message := ""
	match reason:
		"missing_target":
			message = "Select a resource with a resref before scanning references."
		"gamefs_unavailable":
			message = "GameFS index is unavailable for reference scan."
		"scanned":
			message = "Reference scan complete."
	return {
		"ok": ok,
		"reason": reason,
		"message": message,
		"target": target,
		"hits": hits,
		"scanned": scanned,
	}
