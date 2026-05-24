@tool
extends RefCounted
class_name KotorScriptDocument

signal changed

const SCRIPT_EXTENSIONS := {
	"nss": true,
	"ncs": true,
}

var _editor_state: RefCounted
var _source_path := ""
var _file_name := "script.nss"
var _extension := "nss"
var _bytes := PackedByteArray()
var _text := ""
var _editable := true


func setup(label: String, bytes: PackedByteArray, editor_state: RefCounted = null, extension_hint: String = "", source_path: String = "") -> KotorScriptDocument:
	_editor_state = editor_state
	_source_path = source_path if source_path.is_absolute_path() else ""
	_extension = extension_hint.to_lower() if not extension_hint.is_empty() else label.get_extension().to_lower()
	if not SCRIPT_EXTENSIONS.has(_extension):
		_extension = "nss"
	_file_name = _guess_loaded_file_name(label, "script.%s" % _extension)
	_bytes = bytes
	_editable = _extension == "nss"
	_text = bytes.get_string_from_utf8() if _editable else _build_hex_preview(bytes)
	return self


func get_source_path() -> String:
	return _source_path


func get_extension() -> String:
	return _extension


func get_file_name() -> String:
	return _ensure_extension(_file_name, _extension)


func get_text() -> String:
	return _text


func get_bytes() -> PackedByteArray:
	return _bytes


func is_editable() -> bool:
	return _editable


func set_text(text: String) -> bool:
	if not _editable:
		return false
	if _text == text:
		return false
	_text = text
	_bytes = text.to_ascii_buffer()
	changed.emit()
	return true


func build_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("NWScript source" if _extension == "nss" else "Compiled NWScript binary")
	lines.append("File: %s" % get_file_name())
	lines.append("Size: %s" % _format_size(_bytes.size()))
	lines.append("Counterpart: %s" % counterpart_label())
	return "\n".join(lines)


func validate() -> Array[String]:
	var issues: Array[String] = []
	if _extension == "ncs":
		return issues
	if _text.strip_edges().is_empty():
		issues.append("Script source is empty.")
	if get_file_name().get_basename().length() > 16:
		issues.append("File basename exceeds the 16-character resref limit.")
	if not _text.contains("void main") and not _text.contains("StartingConditional"):
		issues.append("No standard entry point detected (void main / StartingConditional).")
	var balance := _compute_delimiter_balance(_text)
	for key in balance.keys():
		var delta := int(balance.get(key, 0))
		if delta != 0:
			issues.append("Unbalanced %s delimiters (%d)." % [key, delta])
	for include_name in _extract_includes(_text):
		if not _include_exists(include_name):
			issues.append("Missing #include \"%s\" in the workspace or active install." % include_name)
	return issues


func build_validation_report() -> String:
	if _extension == "ncs":
		return "NCS binaries are view-only in this slice.\nMatching source: %s\nCompile/decompile support is not implemented yet." % counterpart_label()
	var issues := validate()
	if issues.is_empty():
		return "Source validation passed.\nMatching compiled script: %s" % counterpart_label()
	return "Source validation issues:\n- %s" % "\n- ".join(issues)


func find_counterpart() -> Dictionary:
	var counterpart_extension := "nss" if _extension == "ncs" else "ncs"
	var resref := get_file_name().get_basename().get_file()
	if _editor_state != null:
		var gamefs = _editor_state.get("gamefs")
		if gamefs != null and not resref.is_empty():
			var entry: Dictionary = gamefs.resolve_resource(resref, counterpart_extension)
			if not entry.is_empty():
				return {"entry": entry}
	if _source_path.is_absolute_path():
		var counterpart_path := _source_path.get_base_dir().path_join("%s.%s" % [resref, counterpart_extension])
		if FileAccess.file_exists(counterpart_path):
			return {"path": counterpart_path}
	return {}


func counterpart_label() -> String:
	var counterpart := find_counterpart()
	if counterpart.is_empty():
		return "not found"
	if counterpart.has("entry"):
		var entry: Dictionary = counterpart.get("entry", {})
		return "%s.%s [%s]" % [
			entry.get("resref", ""),
			entry.get("extension", ""),
			entry.get("source", ""),
		]
	return str(counterpart.get("path", "")).get_file()


func _include_exists(include_name: String) -> bool:
	var normalized := include_name.strip_edges()
	if normalized.is_empty():
		return true
	if _source_path.is_absolute_path():
		var local_path := _source_path.get_base_dir().path_join("%s.nss" % normalized)
		if FileAccess.file_exists(local_path):
			return true
	if _editor_state != null:
		var gamefs = _editor_state.get("gamefs")
		if gamefs != null:
			return not gamefs.resolve_resource(normalized, "nss").is_empty()
	return false


func _extract_includes(text: String) -> Array[String]:
	var includes: Array[String] = []
	var regex := RegEx.new()
	if regex.compile('#include\\s+"([^"]+)"') != OK:
		return includes
	for result in regex.search_all(text):
		includes.append(result.get_string(1))
	return includes


func _compute_delimiter_balance(text: String) -> Dictionary:
	return {
		"{}": text.count("{") - text.count("}"),
		"()": text.count("(") - text.count(")"),
		"[]": text.count("[") - text.count("]"),
	}


func _build_hex_preview(bytes: PackedByteArray, bytes_per_line: int = 16, line_limit: int = 128) -> String:
	var lines: Array[String] = []
	var visible_size := mini(bytes.size(), bytes_per_line * line_limit)
	for offset in range(0, visible_size, bytes_per_line):
		var hex_parts: Array[String] = []
		var ascii := ""
		for column in range(bytes_per_line):
			var index := offset + column
			if index >= visible_size:
				hex_parts.append("  ")
				continue
			var value := bytes[index]
			hex_parts.append("%02X" % value)
			ascii += char(value) if value >= 32 and value <= 126 else "."
		lines.append("%08X  %s  %s" % [offset, " ".join(hex_parts), ascii])
	if bytes.size() > visible_size:
		lines.append("")
		lines.append("... truncated after %d bytes of %d total." % [visible_size, bytes.size()])
	return "\n".join(lines)


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var file_name := label.strip_edges()
	if file_name.is_empty():
		return fallback
	var separator := file_name.find("  [")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	separator = file_name.find(" - ")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	separator = file_name.find(" [")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	file_name = file_name.get_file()
	return file_name if not file_name.is_empty() else fallback


func _ensure_extension(path: String, extension: String) -> String:
	if path.get_extension().to_lower() == extension.to_lower():
		return path
	return "%s.%s" % [path, extension]


func _format_size(size: int) -> String:
	if size < 0:
		return "-"
	if size < 1024:
		return "%d B" % size
	if size < 1024 * 1024:
		return "%.1f KiB" % (float(size) / 1024.0)
	return "%.1f MiB" % (float(size) / (1024.0 * 1024.0))
