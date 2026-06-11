## Typed archive document for ERF/RIM/MOD/SAV workspace browsing.
class_name KotorErfDocument
extends RefCounted

const ERFParser := preload("../../formats/erf_parser.gd")
const ERFWriter := preload("../../formats/erf_writer.gd")

var file_type: String = ""
var version: String = ""
var source_path: String = ""
var _raw_bytes: PackedByteArray = PackedByteArray()
var _entries: Array = []
var _members: Array = []
var _dirty: bool = false


static func from_bytes(source_path: String, bytes: PackedByteArray) -> KotorErfDocument:
	var parsed := ERFParser.parse_bytes(bytes)
	if parsed.is_empty():
		return null
	var document = load("res://resources/documents/kotor_erf_document.gd").new()
	document.source_path = source_path
	document.file_type = str(parsed.get("file_type", ""))
	document.version = str(parsed.get("version", ""))
	document._raw_bytes = bytes
	document._entries = parsed.get("entries", [])
	document._members = []
	for entry in document._entries:
		var erf_entry := entry as ERFParser.ERFEntry
		if erf_entry == null:
			continue
		document._members.append({
			"resref": erf_entry.resref,
			"extension": erf_entry.extension,
			"bytes": erf_entry.read_data(),
		})
	document._dirty = false
	return document


func is_empty() -> bool:
	return _entries.is_empty()


func get_entry_count() -> int:
	return _entries.size()


func get_entry(index: int) -> ERFParser.ERFEntry:
	if index < 0 or index >= _entries.size():
		return null
	return _entries[index] as ERFParser.ERFEntry


func get_entry_payload(index: int) -> PackedByteArray:
	var entry := get_entry(index)
	if entry == null:
		return PackedByteArray()
	return entry.read_data()


func entry_file_name(index: int) -> String:
	var entry := get_entry(index)
	if entry == null:
		return ""
	return "%s.%s" % [entry.resref, entry.extension]


func find_entry_index(resref: String, extension: String) -> int:
	var normalized_resref := resref.strip_edges().to_lower()
	var normalized_extension := extension.strip_edges().to_lower()
	for index in range(_entries.size()):
		var entry := get_entry(index)
		if entry == null:
			continue
		if entry.resref.to_lower() == normalized_resref and entry.extension.to_lower() == normalized_extension:
			return index
	return -1


func remove_member_at(index: int) -> Dictionary:
	if index < 0 or index >= _members.size():
		return {"ok": false, "message": "Invalid archive member index."}
	var removed: Dictionary = _members[index].duplicate(true)
	_members.remove_at(index)
	_rebuild_from_members()
	_dirty = true
	return {
		"ok": true,
		"message": "Removed %s.%s." % [removed.get("resref", ""), removed.get("extension", "")],
		"removed": removed,
	}


func replace_member_at(index: int, bytes: PackedByteArray) -> Dictionary:
	if index < 0 or index >= _members.size():
		return {"ok": false, "message": "Invalid archive member index."}
	var member: Dictionary = _members[index]
	var previous_bytes: PackedByteArray = member.get("bytes", PackedByteArray())
	_members[index] = {
		"resref": member.get("resref", ""),
		"extension": member.get("extension", ""),
		"bytes": bytes,
	}
	_rebuild_from_members()
	_dirty = true
	return {
		"ok": true,
		"message": "Replaced %s.%s." % [member.get("resref", ""), member.get("extension", "")],
		"previous_bytes": previous_bytes,
	}


func restore_members(entries: Array) -> void:
	_members = []
	for entry in entries:
		if entry is Dictionary:
			_members.append({
				"resref": str(entry.get("resref", "")),
				"extension": str(entry.get("extension", "")),
				"bytes": entry.get("bytes", PackedByteArray()),
			})
	_rebuild_from_members()
	_dirty = true


func add_member(resref: String, extension: String, bytes: PackedByteArray) -> Dictionary:
	var normalized_resref := resref.strip_edges().to_lower()
	var normalized_extension := extension.strip_edges().to_lower()
	if normalized_resref.is_empty():
		return {"ok": false, "message": "ResRef cannot be empty."}
	if normalized_resref.length() > 16:
		return {"ok": false, "message": "ResRef must be at most 16 characters."}
	if not ERFWriter.EXT_TO_RES_TYPE.has(normalized_extension):
		return {"ok": false, "message": "Unknown resource extension '%s'." % normalized_extension}
	if find_entry_index(normalized_resref, normalized_extension) >= 0:
		return {
			"ok": false,
			"message": "Archive already contains %s.%s." % [normalized_resref, normalized_extension],
		}
	_members.append({
		"resref": normalized_resref,
		"extension": normalized_extension,
		"bytes": bytes,
	})
	_rebuild_from_members()
	_dirty = true
	return {"ok": true, "message": "Added %s.%s." % [normalized_resref, normalized_extension]}


func serialize_for_pipeline() -> Dictionary:
	return {
		"file_type": file_type,
		"entries": _members.duplicate(true),
	}


func get_repacked_bytes() -> PackedByteArray:
	return _raw_bytes


func is_dirty() -> bool:
	return _dirty


func mark_clean() -> void:
	_dirty = false


func _rebuild_from_members() -> void:
	_raw_bytes = ERFWriter.repack(file_type, _members)
	if _raw_bytes.is_empty():
		push_error("KotorErfDocument: repack failed")
		return
	var parsed := ERFParser.parse_bytes(_raw_bytes)
	if parsed.is_empty():
		push_error("KotorErfDocument: repack produced invalid archive")
		return
	_entries = parsed.get("entries", [])
