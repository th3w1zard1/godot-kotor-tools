## editor/module/kotor_template_model_resolver.gd
## Resolves GIT instance template resrefs to MDL model names via blueprint GFF + 2DA tables.
class_name KotorTemplateModelResolver

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const TwoDaParser := preload("../../formats/twoda_parser.gd")

const EXT_BY_CATEGORY := {
	"Creatures": "utc",
	"Placeables": "utp",
	"Doors": "utd",
}

static var _twoda_cache: Dictionary = {}


static func clear_cache() -> void:
	_twoda_cache.clear()


static func supports_mesh_category(category: String) -> bool:
	return EXT_BY_CATEGORY.has(category)


static func resolve_model_resref(gamefs, category: String, template_resref: String) -> String:
	if gamefs == null or not supports_mesh_category(category):
		return ""
	var template := _normalize_resref(template_resref)
	if template.is_empty():
		return ""
	var ext: String = EXT_BY_CATEGORY.get(category, "")
	var document = _load_blueprint_document(gamefs, template, ext)
	if document == null:
		return ""
	match category:
		"Creatures":
			return _resolve_creature_model(gamefs, document)
		"Placeables":
			return _resolve_placeable_model(gamefs, document)
		"Doors":
			return _resolve_door_model(gamefs, document)
	return ""


static func _load_blueprint_document(gamefs, template: String, ext: String):
	var bytes: PackedByteArray = gamefs.load_resource_bytes(template, ext)
	if bytes.is_empty():
		return null
	var parsed: Dictionary = GFFParser.parse_bytes(bytes)
	if parsed.is_empty():
		return null
	var resource = GFFResourceFactory.create_from_parser_result(parsed)
	if resource == null:
		return null
	return resource.create_document()


static func _resolve_creature_model(gamefs, document) -> String:
	var appearance_type: int = document.get_int("Appearance_Type", -1)
	if appearance_type < 0:
		return ""
	var twoda := _load_twoda_table(gamefs, "appearance")
	var row := _get_twoda_row_by_index(twoda, appearance_type)
	if row.is_empty():
		return ""
	var modeltype := str(row.get("modeltype", "B")).strip_edges()
	var model_token := ""
	if modeltype == "B":
		model_token = str(row.get("modela", ""))
	else:
		model_token = str(row.get("race", ""))
	return _normalize_model_token(model_token)


static func _resolve_placeable_model(gamefs, document) -> String:
	var appearance_type := _read_appearance_index(document)
	if appearance_type < 0:
		return ""
	var twoda := _load_twoda_table(gamefs, "placeables")
	var row := _get_twoda_row_by_index(twoda, appearance_type)
	if row.is_empty():
		return ""
	return _normalize_model_token(str(row.get("modelname", "")))


static func _resolve_door_model(gamefs, document) -> String:
	var generic_type: int = document.get_int("GenericType", -1)
	if generic_type < 0:
		generic_type = document.get_int("Appearance_Type", -1)
	if generic_type < 0:
		return ""
	var twoda := _load_twoda_table(gamefs, "genericdoors")
	var row := _get_twoda_row_by_index(twoda, generic_type)
	if row.is_empty():
		return ""
	return _normalize_model_token(str(row.get("modelname", "")))


static func _read_appearance_index(document) -> int:
	var appearance_type: int = document.get_int("Appearance_Type", -1)
	if appearance_type >= 0:
		return appearance_type
	return document.get_int("GenericType", -1)


static func _load_twoda_table(gamefs, resref: String) -> Dictionary:
	var cache_key := _twoda_cache_key(gamefs, resref)
	if _twoda_cache.has(cache_key):
		return _twoda_cache[cache_key]
	var bytes: PackedByteArray = gamefs.load_resource_bytes(resref, "2da")
	var parsed := TwoDaParser.parse_bytes(bytes) if not bytes.is_empty() else {}
	_twoda_cache[cache_key] = parsed
	return parsed


static func _twoda_cache_key(gamefs, resref: String) -> String:
	var game_path := ""
	if gamefs != null and "game_path" in gamefs:
		game_path = str(gamefs.game_path)
	return "%s:%s" % [game_path, resref.to_lower()]


static func _get_twoda_row_by_index(twoda: Dictionary, row_index: int) -> Dictionary:
	for raw_row in twoda.get("rows", []):
		if typeof(raw_row) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = raw_row
		if int(row.get("__row_index", -1)) == row_index:
			return row
	return {}


static func _normalize_resref(value: String) -> String:
	return value.strip_edges().to_lower()


static func _normalize_model_token(value: String) -> String:
	var token := value.strip_edges().to_lower()
	if token.is_empty() or token == "****" or token == "*":
		return ""
	return token
