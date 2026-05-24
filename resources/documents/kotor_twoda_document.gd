@tool
extends RefCounted
class_name KotorTwoDaDocument

signal changed

const TwoDaResource := preload("../twoda_resource.gd")

var _resource: TwoDaResource


func setup(resource: TwoDaResource) -> KotorTwoDaDocument:
	_resource = resource
	return self


func get_resource() -> TwoDaResource:
	return _resource


func get_columns() -> PackedStringArray:
	return _resource.columns if _resource != null else PackedStringArray()


func row_count() -> int:
	return _resource.row_count() if _resource != null else 0


func get_rows() -> Array[Dictionary]:
	if _resource == null:
		return []
	var rows: Array[Dictionary] = []
	for row: Dictionary in _resource.rows:
		rows.append(row.duplicate(true))
	return rows


func get_cell(row: int, column_name: String) -> Variant:
	if _resource == null:
		return null
	return _resource.get_cell(row, column_name)


func set_cell(row: int, column_name: String, value: Variant) -> bool:
	if _resource == null:
		return false
	if not _resource.set_cell(row, column_name, value):
		return false
	changed.emit()
	return true


func build_summary_text() -> String:
	if _resource == null:
		return "No 2DA loaded."
	var lines: Array[String] = []
	lines.append("2DA Table")
	lines.append("Columns: %d" % _resource.columns.size())
	lines.append("Rows: %d" % _resource.row_count())
	if not _resource.default_val.is_empty():
		lines.append("Default: %s" % _resource.default_val)
	return "\n".join(lines)


func validate() -> Array[String]:
	var issues: Array[String] = []
	if _resource == null:
		issues.append("No 2DA resource is loaded.")
		return issues
	if _resource.columns.is_empty():
		issues.append("2DA table has no columns.")
	var seen := {}
	for column in _resource.columns:
		var column_name := String(column).strip_edges()
		if column_name.is_empty():
			issues.append("2DA table contains an empty column name.")
			continue
		if seen.has(column_name):
			issues.append("2DA table contains duplicate column %s." % column_name)
			continue
		seen[column_name] = true
	for row_index in range(_resource.rows.size()):
		var row: Dictionary = _resource.rows[row_index]
		for key in row.keys():
			var column_name := str(key)
			if not seen.has(column_name):
				issues.append("Row %d contains unknown column %s." % [row_index, column_name])
	return issues


func build_validation_report() -> String:
	var issues := validate()
	if issues.is_empty():
		return "2DA validation passed.\n- Table columns are defined.\n- Rows only reference known columns."
	return "2DA validation issues:\n- %s" % "\n- ".join(issues)
