## resources/gff_resource.gd
## Resource container produced by the GFF importer.
@tool
extends Resource
class_name GFFResource

const KotorGFFDocument := preload("./kotor_gff_document.gd")

## Four-character GFF type tag (e.g. "UTC", "DLG", "GIT").
@export var file_type: String = ""

## Root struct as a recursive Dictionary — mirrors CResGFF::GetTopLevelStruct output.
@export var gff_data: Dictionary = {}
@export var schema_data: Dictionary = {}

var _document: KotorGFFDocument


func setup_from_parser_result(parsed: Dictionary) -> void:
	file_type = String(parsed.get("file_type", "")).strip_edges()
	var root = parsed.get("root", {})
	gff_data = root.duplicate(true) if typeof(root) == TYPE_DICTIONARY else {}
	var schema = parsed.get("schema", {})
	schema_data = schema.duplicate(true) if typeof(schema) == TYPE_DICTIONARY else {}
	_document = null


func create_document() -> KotorGFFDocument:
	if _document == null:
		_document = _create_document()
	return _document


func get_display_name() -> String:
	return create_document().get_display_name()


func get_type_label() -> String:
	return create_document().get_type_label()


func get_summary_lines() -> Array[String]:
	return create_document().get_summary_lines()


func build_summary_text() -> String:
	return create_document().build_summary_text()


func _create_document() -> KotorGFFDocument:
	return KotorGFFDocument.new().setup(file_type, gff_data, self)
