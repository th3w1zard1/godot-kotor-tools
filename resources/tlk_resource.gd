## Resource produced by the TLK importer.
@tool
extends Resource
class_name TLKResource

const TLKParser := preload("../formats/tlk_parser.gd")
const FLAG_TEXT_PRESENT := 0x1

## TLK file format version string, usually "V3.0".
@export var version: String = ""

## Aurora language ID stored in the TLK header.
@export var language_id: int = 0

## Flattened talk table entries keyed by StrRef metadata.
@export var entries: Array[Dictionary] = []


func apply_parser_result(parsed: Dictionary) -> void:
	version = parsed.get("version", "")
	language_id = parsed.get("language_id", 0)
	entries.clear()
	for entry: TLKParser.TLKEntry in parsed.get("entries", []):
		entries.append({
			"strref": entry.strref,
			"flags": entry.flags,
			"sound_resref": entry.sound_resref,
			"offset": entry.offset,
			"size": entry.size,
			"sound_length": entry.sound_length,
			"text": entry.text,
		})


func to_writer_data() -> Dictionary:
	return {
		"version": version,
		"language_id": language_id,
		"entries": entries.duplicate(true),
	}


## Get a string by StrRef. Returns an empty string if missing.
func get_string(strref: int) -> String:
	if strref < 0 or strref >= entries.size():
		return ""
	return String(entries[strref].get("text", ""))


func get_entry(strref: int) -> Dictionary:
	if strref < 0 or strref >= entries.size():
		return {}
	return (entries[strref] as Dictionary).duplicate(true)


func set_entry_text(strref: int, text: String) -> bool:
	if strref < 0 or strref >= entries.size():
		return false

	var entry := entries[strref]
	if String(entry.get("text", "")) == text:
		return false

	entry["text"] = text
	entry["size"] = text.length()
	var flags := int(entry.get("flags", 0))
	if text.is_empty():
		flags &= ~FLAG_TEXT_PRESENT
	else:
		flags |= FLAG_TEXT_PRESENT
	entry["flags"] = flags
	entries[strref] = entry
	emit_changed()
	return true


## Build a compact string lookup suitable for editor tooling.
func build_lookup() -> Dictionary:
	var lookup := {}
	for entry: Dictionary in entries:
		var text := String(entry.get("text", ""))
		if text.is_empty():
			continue
		lookup[str(entry.get("strref", 0))] = text
	return lookup