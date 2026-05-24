@tool
extends RefCounted
class_name KotorResourceLocator


static func build_entry_label(entry: Dictionary) -> String:
	return "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]


static func build_entry_details(entry: Dictionary, variants: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	lines.append(build_entry_label(entry))
	lines.append("Primary source: %s" % _format_source_label(str(entry.get("source", ""))))
	lines.append("Location: %s" % str(entry.get("location", "")))
	lines.append("Size: %s" % _format_size(int(entry.get("size", -1))))
	lines.append("")
	lines.append("Variants:")
	for variant in variants:
		lines.append("- %s - %s" % [
			_format_source_label(str(variant.get("source", ""))),
			str(variant.get("location", "")),
		])
	return "\n".join(lines)


static func build_entry_open_label(entry: Dictionary) -> String:
	return "%s [%s]" % [build_entry_label(entry), str(entry.get("source", ""))]


static func _format_source_label(source: String) -> String:
	match source.to_lower():
		"chitin.key":
			return "Chitin"
		"dialog.tlk":
			return "dialog.tlk"
		"modules":
			return "Modules"
		"override":
			return "Override"
		_:
			return source


static func _format_size(size: int) -> String:
	if size < 0:
		return "-"
	if size < 1024:
		return "%d B" % size
	if size < 1024 * 1024:
		return "%.1f KiB" % (float(size) / 1024.0)
	return "%.1f MiB" % (float(size) / (1024.0 * 1024.0))
