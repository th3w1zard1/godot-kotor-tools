@tool
extends RefCounted
class_name KotorModuleContext

const LYTParser := preload("../../formats/lyt_parser.gd")
const BWMParser := preload("../../formats/bwm_parser.gd")

const MDLParser := preload("../../formats/mdl_parser.gd")

const MODULE_EXTENSIONS := ["git", "are", "ifo", "lyt", "vis", "pth", "wok"]
const CORE_MODULE_EXTENSIONS := ["git", "are", "ifo"]
const LAYOUT_EXTENSIONS := ["lyt", "vis", "pth"]

const SOURCE_RANK := {
	"override": 0,
	"modules": 1,
	"chitin.key": 2,
	"dialog.tlk": 3,
}


static func module_resref_from_file_name(file_name: String) -> String:
	var base := file_name.get_file().get_basename().strip_edges().to_lower()
	return base


static func find_module_bundle(gamefs: RefCounted, module_resref: String) -> Dictionary:
	var normalized := module_resref.strip_edges().to_lower()
	if normalized.is_empty():
		return {}
	var bundle := {
		"module_resref": normalized,
		"git": {},
		"are": {},
		"ifo": {},
		"lyt": {},
		"vis": {},
		"pth": {},
		"wok": {},
	}
	if gamefs == null:
		return bundle

	for extension in MODULE_EXTENSIONS:
		var entry := _resolve_best_entry(gamefs, normalized, extension)
		if not entry.is_empty():
			bundle[extension] = entry

	return bundle


static func load_parsed_layout(gamefs: RefCounted, bundle: Dictionary) -> Dictionary:
	if gamefs == null or bundle.is_empty():
		return {}
	var lyt_entry: Dictionary = bundle.get("lyt", {})
	if lyt_entry.is_empty():
		return {}
	if not gamefs.has_method("load_resource_entry_bytes"):
		return {}
	var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(lyt_entry)
	if bytes.is_empty():
		return {}
	return LYTParser.parse_bytes(bytes)


static func load_parsed_walkmesh(gamefs: RefCounted, bundle: Dictionary) -> Dictionary:
	if gamefs == null or bundle.is_empty():
		return {}
	var wok_entry: Dictionary = bundle.get("wok", {})
	if wok_entry.is_empty():
		return {}
	if not gamefs.has_method("load_resource_entry_bytes"):
		return {}
	var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(wok_entry)
	if bytes.is_empty():
		return {}
	return BWMParser.parse_bytes(bytes)


static func load_parsed_model_mesh(gamefs: RefCounted, model_resref: String) -> Dictionary:
	var normalized := model_resref.strip_edges().to_lower()
	if gamefs == null or normalized.is_empty():
		return {}
	if not gamefs.has_method("resolve_resource") or not gamefs.has_method("load_resource_entry_bytes"):
		return {}

	var mdl_entry: Dictionary = gamefs.resolve_resource(normalized, "mdl")
	if mdl_entry.is_empty():
		return {}
	var mdl_bytes: PackedByteArray = gamefs.load_resource_entry_bytes(mdl_entry)
	if mdl_bytes.is_empty():
		return {}

	var mdx_bytes := PackedByteArray()
	var mdx_entry: Dictionary = gamefs.resolve_resource(normalized, "mdx")
	if not mdx_entry.is_empty():
		mdx_bytes = gamefs.load_resource_entry_bytes(mdx_entry)

	return MDLParser.parse_bytes(mdl_bytes, mdx_bytes)


static func describe_bundle(bundle: Dictionary) -> String:
	if bundle.is_empty():
		return "No module bundle"
	var parts: Array[String] = []
	for extension in MODULE_EXTENSIONS:
		var entry: Dictionary = bundle.get(extension, {})
		if entry.is_empty():
			if extension in CORE_MODULE_EXTENSIONS:
				parts.append("%s: missing" % extension.to_upper())
			continue
		parts.append("%s: %s" % [extension.to_upper(), entry.get("source", "indexed")])
	return " · ".join(parts)


static func _resolve_best_entry(gamefs: RefCounted, module_resref: String, extension: String) -> Dictionary:
	if gamefs.has_method("resolve_resource"):
		var resolved: Dictionary = gamefs.resolve_resource(module_resref, extension)
		if not resolved.is_empty():
			return resolved.duplicate(true)
	if not gamefs.has_method("list_core_resources"):
		return {}
	var entries: Array = gamefs.list_core_resources(module_resref, extension, "", 64)
	var best := {}
	var best_rank := 999
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		if str(entry.get("resref", "")).strip_edges().to_lower() != module_resref:
			continue
		if str(entry.get("extension", "")).strip_edges().to_lower() != extension:
			continue
		var rank := _entry_source_rank(entry)
		if rank < best_rank:
			best_rank = rank
			best = entry.duplicate(true)
	return best


static func _entry_source_rank(entry: Dictionary) -> int:
	var source := str(entry.get("source", "")).strip_edges().to_lower()
	if SOURCE_RANK.has(source):
		return int(SOURCE_RANK[source])
	return 99
