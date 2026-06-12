## KotOR letter probability table resource.
@tool
extends Resource
class_name LTRResource

const LTRParser := preload("../formats/ltr_parser.gd")

@export var letter_count: int = LTRParser.KOTOR_LETTER_COUNT
@export var alphabet: String = LTRParser.KOTOR_ALPHABET
@export var singles: Dictionary = {}
@export var doubles: Array = []
@export var triples: Array = []


func _init() -> void:
	reset_to_defaults()


func reset_to_defaults() -> void:
	letter_count = LTRParser.KOTOR_LETTER_COUNT
	alphabet = LTRParser.KOTOR_ALPHABET
	singles = _default_block(letter_count)
	doubles = _default_blocks(letter_count)
	triples = _default_triple_blocks(letter_count)


func apply_parser_result(parsed: Dictionary) -> void:
	if parsed.is_empty():
		return
	letter_count = int(parsed.get("letter_count", LTRParser.KOTOR_LETTER_COUNT))
	alphabet = str(parsed.get("alphabet", LTRParser.alphabet_for_count(letter_count)))
	singles = _copy_block(parsed.get("singles", {}), letter_count)
	doubles = _copy_blocks(parsed.get("doubles", []), letter_count)
	triples = _copy_triple_blocks(parsed.get("triples", []), letter_count)


func to_parser_result() -> Dictionary:
	return {
		"letter_count": letter_count,
		"alphabet": alphabet,
		"singles": _copy_block(singles, letter_count),
		"doubles": _copy_blocks(doubles, letter_count),
		"triples": _copy_triple_blocks(triples, letter_count),
	}


func get_single_probability(position: String, letter_index: int) -> float:
	if letter_index < 0 or letter_index >= letter_count:
		return 0.0
	var block := _copy_block(singles, letter_count)
	var values: Array = block.get(position, [])
	if typeof(values) != TYPE_ARRAY or letter_index >= values.size():
		return 0.0
	return float(values[letter_index])


func set_single_probability(position: String, letter_index: int, value: float) -> bool:
	if letter_index < 0 or letter_index >= letter_count:
		return false
	if position != "start" and position != "middle" and position != "end":
		return false
	var block := _copy_block(singles, letter_count)
	var array: Array = block.get(position, [])
	if typeof(array) != TYPE_ARRAY:
		array = _default_float_array(letter_count)
	var normalized := float(value)
	if float(array[letter_index]) == normalized:
		return false
	array[letter_index] = normalized
	block[position] = array
	singles = block
	emit_changed()
	return true


func get_double_probability(context_index: int, position: String, letter_index: int) -> float:
	return _get_block_probability(doubles, context_index, position, letter_index)


func set_double_probability(context_index: int, position: String, letter_index: int, value: float) -> bool:
	return _set_block_probability("doubles", context_index, position, letter_index, value)


func get_triple_probability(row_index: int, column_index: int, position: String, letter_index: int) -> float:
	if row_index < 0 or row_index >= letter_count:
		return 0.0
	if column_index < 0 or column_index >= letter_count:
		return 0.0
	var rows := _copy_triple_blocks(triples, letter_count)
	var row: Array = rows[row_index]
	var block := _copy_block(row[column_index], letter_count)
	return _probability_from_block(block, position, letter_index)


func set_triple_probability(row_index: int, column_index: int, position: String, letter_index: int, value: float) -> bool:
	if row_index < 0 or row_index >= letter_count:
		return false
	if column_index < 0 or column_index >= letter_count:
		return false
	if position != "start" and position != "middle" and position != "end":
		return false
	if letter_index < 0 or letter_index >= letter_count:
		return false
	var rows := _copy_triple_blocks(triples, letter_count)
	var row: Array = rows[row_index]
	var block := _copy_block(row[column_index], letter_count)
	var array: Array = block.get(position, [])
	if typeof(array) != TYPE_ARRAY:
		array = _default_float_array(letter_count)
	var normalized := float(value)
	if float(array[letter_index]) == normalized:
		return false
	array[letter_index] = normalized
	block[position] = array
	row[column_index] = block
	rows[row_index] = row
	triples = rows
	emit_changed()
	return true


func summary_text() -> String:
	return "LTR %d-letter alphabet; %d double contexts; %d triple contexts." % [
		letter_count,
		doubles.size(),
		triples.size() * (triples[0].size() if not triples.is_empty() else 0),
	]


static func _default_block(letter_count: int) -> Dictionary:
	return {
		"start": _default_float_array(letter_count),
		"middle": _default_float_array(letter_count),
		"end": _default_float_array(letter_count),
	}


static func _default_blocks(letter_count: int) -> Array:
	var blocks: Array = []
	blocks.resize(letter_count)
	for index in letter_count:
		blocks[index] = _default_block(letter_count)
	return blocks


static func _default_triple_blocks(letter_count: int) -> Array:
	var rows: Array = []
	rows.resize(letter_count)
	for row_index in letter_count:
		var row: Array = []
		row.resize(letter_count)
		for column_index in letter_count:
			row[column_index] = _default_block(letter_count)
		rows[row_index] = row
	return rows


static func _default_float_array(letter_count: int) -> Array:
	var values: Array = []
	values.resize(letter_count)
	for index in letter_count:
		values[index] = float(index + 1) / float(letter_count)
	return values


static func _copy_block(block: Variant, letter_count: int) -> Dictionary:
	var source: Dictionary = block if typeof(block) == TYPE_DICTIONARY else {}
	var copy := _default_block(letter_count)
	for position in ["start", "middle", "end"]:
		var values: Variant = source.get(position, [])
		if typeof(values) != TYPE_ARRAY:
			continue
		var target: Array = copy[position]
		for index in mini((values as Array).size(), letter_count):
			target[index] = float((values as Array)[index])
	return copy


static func _copy_blocks(blocks: Variant, letter_count: int) -> Array:
	var copy: Array = []
	copy.resize(letter_count)
	var source: Array = blocks if typeof(blocks) == TYPE_ARRAY else []
	for index in letter_count:
		var block: Dictionary = source[index] if index < source.size() else {}
		copy[index] = _copy_block(block, letter_count)
	return copy


static func _copy_triple_blocks(rows: Variant, letter_count: int) -> Array:
	var copy: Array = []
	copy.resize(letter_count)
	var source: Array = rows if typeof(rows) == TYPE_ARRAY else []
	for row_index in letter_count:
		var source_row: Array = source[row_index] if row_index < source.size() else []
		var row: Array = []
		row.resize(letter_count)
		for column_index in letter_count:
			var block: Dictionary = source_row[column_index] if column_index < source_row.size() else {}
			row[column_index] = _copy_block(block, letter_count)
		copy[row_index] = row
	return copy


func _get_block_probability(blocks: Variant, context_index: int, position: String, letter_index: int) -> float:
	if context_index < 0 or context_index >= letter_count:
		return 0.0
	var copied := _copy_blocks(blocks, letter_count)
	var block := _copy_block(copied[context_index], letter_count)
	return _probability_from_block(block, position, letter_index)


func _set_block_probability(
	property_name: String,
	context_index: int,
	position: String,
	letter_index: int,
	value: float
) -> bool:
	if context_index < 0 or context_index >= letter_count:
		return false
	if position != "start" and position != "middle" and position != "end":
		return false
	if letter_index < 0 or letter_index >= letter_count:
		return false
	var copied := _copy_blocks(get(property_name), letter_count)
	var block := _copy_block(copied[context_index], letter_count)
	var array: Array = block.get(position, [])
	if typeof(array) != TYPE_ARRAY:
		array = _default_float_array(letter_count)
	var normalized := float(value)
	if float(array[letter_index]) == normalized:
		return false
	array[letter_index] = normalized
	block[position] = array
	copied[context_index] = block
	set(property_name, copied)
	emit_changed()
	return true


static func _probability_from_block(block: Dictionary, position: String, letter_index: int) -> float:
	if letter_index < 0:
		return 0.0
	var values: Array = block.get(position, [])
	if typeof(values) != TYPE_ARRAY or letter_index >= values.size():
		return 0.0
	return float(values[letter_index])
