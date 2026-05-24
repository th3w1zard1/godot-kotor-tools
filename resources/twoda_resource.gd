## resources/twoda_resource.gd
## Resource produced by the 2DA importer.
@tool
extends Resource
class_name TwoDaResource

## Ordered column headers matching the 2DA file.
@export var columns: PackedStringArray = PackedStringArray()

## Row data — Array of Dictionary keyed by column name.
## null values indicate "****" (undefined/empty) cells.
@export var rows: Array[Dictionary] = []

## DEFAULT value declared at the top of the 2DA (or "" if absent).
@export var default_val: String = ""


func apply_parser_result(parsed: Dictionary) -> void:
	columns = parsed.get("columns", PackedStringArray())
	rows.clear()
	for row: Dictionary in parsed.get("rows", []):
		rows.append(row.duplicate(true))
	default_val = parsed.get("default", "")


func to_parser_result() -> Dictionary:
	return {
		"columns": columns,
		"rows": rows.duplicate(true),
		"default": default_val,
	}


## Get a cell by row index and column name.  Returns null for empty cells.
func get_cell(row: int, col: String) -> Variant:
	if row < 0 or row >= rows.size():
		return null
	return rows[row].get(col, null)


## Count of data rows.
func row_count() -> int:
	return rows.size()


func has_column(col: String) -> bool:
	return columns.has(col)


func set_cell(row: int, col: String, value: Variant) -> bool:
	if row < 0 or row >= rows.size():
		return false
	if not has_column(col):
		return false

	var normalized = null if value == null or String(value).is_empty() else str(value)
	if rows[row].get(col, null) == normalized:
		return false

	rows[row][col] = normalized
	emit_changed()
	return true
