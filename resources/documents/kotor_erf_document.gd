## Typed archive document for ERF/RIM/MOD/SAV workspace browsing.
class_name KotorErfDocument
extends RefCounted

const ERFParser := preload("../../formats/erf_parser.gd")

var file_type: String = ""
var version: String = ""
var source_path: String = ""
var _raw_bytes: PackedByteArray = PackedByteArray()
var _entries: Array = []


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
