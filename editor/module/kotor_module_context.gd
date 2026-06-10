@tool
extends RefCounted
class_name KotorModuleContext

const LYTParser := preload("../../formats/lyt_parser.gd")
const BWMParser := preload("../../formats/bwm_parser.gd")
const VISParser := preload("../../formats/vis_parser.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const MDLParser := preload("../../formats/mdl_parser.gd")
const PTHResource := preload("../../resources/typed/pth_resource.gd")

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


static func load_parsed_visibility(gamefs: RefCounted, bundle: Dictionary) -> Dictionary:
	if gamefs == null or bundle.is_empty():
		return {}
	var vis_entry: Dictionary = bundle.get("vis", {})
	if vis_entry.is_empty():
		return {}
	if not gamefs.has_method("load_resource_entry_bytes"):
		return {}
	var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(vis_entry)
	if bytes.is_empty():
		return {}
	return VISParser.parse_bytes(bytes)


static func load_path_resource(gamefs: RefCounted, bundle: Dictionary) -> PTHResource:
	if gamefs == null or bundle.is_empty():
		return null
	var pth_entry: Dictionary = bundle.get("pth", {})
	if pth_entry.is_empty():
		return null
	if not gamefs.has_method("load_resource_entry_bytes"):
		return null
	var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(pth_entry)
	if bytes.is_empty():
		return null
	var parsed := GFFParser.parse_bytes(bytes)
	if parsed.is_empty():
		return null
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	return resource as PTHResource


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


static func format_layout_summary(parsed: Dictionary) -> String:
	if parsed.is_empty():
		return "LYT: not loaded"
	var rooms: Array = parsed.get("rooms", [])
	var tracks: Array = parsed.get("tracks", [])
	var obstacles: Array = parsed.get("obstacles", [])
	var doorhooks: Array = parsed.get("doorhooks", [])
	return "LYT: %d room(s), %d track(s), %d obstacle(s), %d doorhook(s)" % [
		rooms.size(),
		tracks.size(),
		obstacles.size(),
		doorhooks.size(),
	]


static func format_visibility_summary(parsed: Dictionary) -> String:
	if parsed.is_empty():
		return "VIS: not loaded"
	return "VIS: %d room visibility group(s)" % VISParser.room_count(parsed)


static func format_path_summary(resource: PTHResource) -> String:
	if resource == null:
		return "PTH: not loaded"
	var field_name := resource.get_point_field_name()
	var connection_count := resource.get_connection_count()
	var connection_field := resource.get_connection_field_name()
	if not field_name.is_empty() and connection_count > 0 and not connection_field.is_empty():
		return "PTH: %d point(s), %d connection(s) via %s/%s" % [
			resource.get_point_count(),
			connection_count,
			field_name,
			connection_field,
		]
	if field_name.is_empty():
		return "PTH: %d point(s)" % resource.get_point_count()
	return "PTH: %d point(s) via %s" % [resource.get_point_count(), field_name]


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


static func get_room_model_entries(parsed_layout: Dictionary, gamefs: RefCounted) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if parsed_layout.is_empty():
		return records
	var rooms: Array = parsed_layout.get("rooms", [])
	var seen: Dictionary = {}
	for raw_room in rooms:
		if typeof(raw_room) != TYPE_DICTIONARY:
			continue
		var room: Dictionary = raw_room
		var model_name := str(room.get("model", "")).strip_edges().to_lower()
		if model_name.is_empty() or seen.has(model_name):
			continue
		seen[model_name] = true
		var position: Vector3 = room.get("position", Vector3.ZERO)
		var mdl_entry := _resolve_model_asset_entry(gamefs, model_name, "mdl")
		var mdx_entry := _resolve_model_asset_entry(gamefs, model_name, "mdx")
		var wok_entry := _resolve_model_asset_entry(gamefs, model_name, "wok")
		records.append({
			"model": model_name,
			"position": position,
			"mdl_entry": mdl_entry,
			"mdx_entry": mdx_entry,
			"wok_entry": wok_entry,
			"has_mdl": not mdl_entry.is_empty(),
			"has_mdx": not mdx_entry.is_empty(),
			"has_wok": not wok_entry.is_empty(),
			"open_entry": mdl_entry if not mdl_entry.is_empty() else {},
		})
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("model", "")) < str(b.get("model", ""))
	)
	return records


static func format_room_model_presence(record: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append("MDL ✓" if record.get("has_mdl", false) else "MDL missing")
	parts.append("MDX ✓" if record.get("has_mdx", false) else "MDX missing")
	parts.append("WOK ✓" if record.get("has_wok", false) else "WOK missing")
	return ", ".join(parts)


static func get_bundle_resource_entries(bundle: Dictionary) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if bundle.is_empty():
		return records
	for extension in MODULE_EXTENSIONS:
		var entry: Dictionary = bundle.get(extension, {})
		var description := ""
		if entry.is_empty():
			description = "missing" if extension in CORE_MODULE_EXTENSIONS else "not indexed"
		else:
			description = str(entry.get("source", "indexed"))
		records.append({
			"extension": extension,
			"label": extension.to_upper(),
			"description": description,
			"entry": entry.duplicate(true) if not entry.is_empty() else {},
			"available": not entry.is_empty(),
		})
	return records


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


static func _resolve_model_asset_entry(gamefs: RefCounted, model_name: String, extension: String) -> Dictionary:
	if gamefs == null or model_name.is_empty():
		return {}
	if gamefs.has_method("resolve_resource"):
		var resolved: Dictionary = gamefs.resolve_resource(model_name, extension)
		if not resolved.is_empty():
			return resolved.duplicate(true)
	return {}
