## 2DA V2.0 serializer for writing TwoDaResource data back to disk.
@tool
extends RefCounted
class_name TwoDaWriter

const TwoDaResource := preload("../resources/twoda_resource.gd")
const EMPTY_VALUE := "****"
const HEADER := "2DA V2.0"


static func save_resource(resource: Resource, path: String) -> Error:
	if resource == null:
		return ERR_INVALID_PARAMETER

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_string(serialize(resource))
	var err := file.get_error()
	file.close()
	if err == OK or err == ERR_FILE_EOF:
		return OK
	return err


static func serialize(resource: Resource) -> String:
	if not resource is TwoDaResource:
		return ""

	var data: Dictionary = (resource as TwoDaResource).to_parser_result()
	var columns: PackedStringArray = data.get("columns", PackedStringArray())
	var rows: Array = data.get("rows", [])
	var lines: Array[String] = [HEADER]
	var default_val := String(data.get("default", ""))

	if default_val.is_empty():
		lines.append("")
	else:
		lines.append("DEFAULT: %s" % _format_token(default_val))

	lines.append("\t".join(Array(columns)))
	for row_index in rows.size():
		var row: Dictionary = rows[row_index]
		var tokens: Array[String] = [str(row_index)]
		for column in columns:
			tokens.append(_format_token(row.get(column, null)))
		lines.append("\t".join(tokens))

	return "\n".join(lines) + "\n"


static func _format_token(value: Variant) -> String:
	if value == null:
		return EMPTY_VALUE

	var text := str(value).replace("\r\n", "\n").replace("\r", "\n").replace("\n", " ")
	if text.contains("\""):
		text = text.replace("\"", "'")

	if text.is_empty() or text.contains(" ") or text.contains("\t"):
		return "\"%s\"" % text
	return text
