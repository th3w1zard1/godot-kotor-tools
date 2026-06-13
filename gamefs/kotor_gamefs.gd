@tool
extends RefCounted
class_name KotorGameFS

const ERFParser := preload("../formats/erf_parser.gd")
const KEYBIFParser := preload("../formats/key_bif_parser.gd")
const TLKParser := preload("../formats/tlk_parser.gd")
const KotorModdingPipeline := preload("../editor/modding/kotor_modding_pipeline.gd")

const CHITIN_KEY_NAME := "chitin.key"
const MODULES_DIR_NAME := "modules"
const OVERRIDE_DIR_NAME := "override"
const DIALOG_TLK_RESREF := "dialog"
const SOURCE_OVERRIDE := "override"
const SOURCE_MODULES := "modules"
const SOURCE_DIALOG_TLK := "dialog.tlk"
const SOURCE_CHITIN := "chitin.key"
const DIALOG_TLK_TYPE := 0x001C
const MODULE_INDEX_EXTENSIONS := {
	"are": true,
	"git": true,
	"ifo": true,
	"lyt": true,
	"mdl": true,
	"mdx": true,
	"pth": true,
	"set": true,
	"vis": true,
	"wok": true,
}

var game_path: String = ""
var dialog_tlk_path: String = ""
var chitin_key_path: String = ""
var modules_path: String = ""
var override_path: String = ""
var dialog_tlk: Dictionary = {}
var key_index: Dictionary = {}

var _resource_index: Dictionary = {}
var _resource_variants: Dictionary = {}
var _resource_list: Array[Dictionary] = []
var _bif_path_cache: Dictionary = {}
var _bif_bytes_cache: Dictionary = {}
var _bif_entries_cache: Dictionary = {}
var _override_count := 0
var _chitin_count := 0
var _dialog_count := 0
var _module_archive_count := 0
var _module_resource_count := 0
var _last_error := ""
var _extension_type_map: Dictionary = {}


func _init() -> void:
	_build_extension_type_map()


func clear() -> void:
	game_path = ""
	dialog_tlk_path = ""
	chitin_key_path = ""
	modules_path = ""
	override_path = ""
	dialog_tlk = {}
	key_index = {}
	_resource_index.clear()
	_resource_variants.clear()
	_resource_list.clear()
	_bif_path_cache.clear()
	_bif_bytes_cache.clear()
	_bif_entries_cache.clear()
	_override_count = 0
	_chitin_count = 0
	_dialog_count = 0
	_module_archive_count = 0
	_module_resource_count = 0
	_last_error = ""


func index_install(install_path: String) -> bool:
	clear()
	game_path = install_path.strip_edges()
	if game_path.is_empty():
		_last_error = "No game path configured"
		return false
	if not DirAccess.dir_exists_absolute(game_path):
		_last_error = "Game path does not exist"
		return false

	dialog_tlk_path = _find_dialog_tlk_path(game_path)
	chitin_key_path = _find_chitin_key_path(game_path)
	modules_path = _find_modules_path(game_path)
	override_path = _find_override_path(game_path)

	_index_chitin_key()
	_index_dialog_tlk()
	_index_module_archives()
	_index_override()
	_rebuild_resource_list()

	if _resource_list.is_empty():
		_last_error = "No core game resources indexed"
		return false
	_last_error = ""
	return true


func has_install() -> bool:
	return not game_path.is_empty() and not _resource_list.is_empty()


func has_indexed_resources() -> bool:
	return not _resource_list.is_empty()


func has_dialog_tlk() -> bool:
	return not dialog_tlk_path.is_empty() and not dialog_tlk.is_empty()


func has_chitin_key() -> bool:
	return not chitin_key_path.is_empty() and not key_index.is_empty()


func has_modules() -> bool:
	return not modules_path.is_empty() and _module_archive_count > 0


func has_override() -> bool:
	return not override_path.is_empty() and _override_count > 0


func get_last_error() -> String:
	return _last_error


func get_index_summary() -> Dictionary:
	return {
		"game_path": game_path,
		"dialog_tlk_path": dialog_tlk_path,
		"chitin_key_path": chitin_key_path,
		"modules_path": modules_path,
		"override_path": override_path,
		"resource_count": _resource_list.size(),
		"override_count": _override_count,
		"chitin_count": _chitin_count,
		"dialog_count": _dialog_count,
		"module_archive_count": _module_archive_count,
		"module_resource_count": _module_resource_count,
	}


func get_status_text() -> String:
	if game_path.is_empty():
		return "No game path configured"
	if not DirAccess.dir_exists_absolute(game_path):
		return "Invalid game path"

	var parts: Array[String] = []
	parts.append("dialog.tlk" if not dialog_tlk_path.is_empty() else "dialog.tlk missing")
	parts.append("chitin.key" if not chitin_key_path.is_empty() else "chitin.key missing")
	if modules_path.is_empty():
		parts.append("modules missing")
	elif _module_archive_count > 0:
		parts.append("modules x%d (%d area/model resources)" % [_module_archive_count, _module_resource_count])
	else:
		parts.append("modules empty")
	if override_path.is_empty():
		parts.append("override missing")
	elif _override_count > 0:
		parts.append("override x%d" % _override_count)
	else:
		parts.append("override empty")

	if not _resource_list.is_empty():
		parts.append("%d resources" % _resource_list.size())

	return "Ready: %s" % ", ".join(parts)


func get_dialog_string(strref: int) -> String:
	if dialog_tlk.is_empty():
		return ""
	return TLKParser.get_string(dialog_tlk, strref)


func resolve_resource(resref: String, resource_type: Variant) -> Dictionary:
	var normalized_type := _normalize_resource_type(resource_type)
	if normalized_type < 0:
		return {}
	return _resource_index.get(_resource_key(resref, normalized_type), {}).duplicate(true)


func resolve_resource_from_source(resref: String, resource_type: Variant, source: String) -> Dictionary:
	var normalized_type := _normalize_resource_type(resource_type)
	if normalized_type < 0:
		return {}
	var normalized_source := source.strip_edges().to_lower()
	for entry: Dictionary in list_resource_variants(resref, normalized_type):
		if str(entry.get("source", "")).to_lower() == normalized_source:
			return entry.duplicate(true)
	return {}


func resolve_resource_by_name(file_name: String) -> Dictionary:
	var extension := file_name.get_extension().to_lower()
	var basename := file_name.get_basename().get_file()
	if basename.is_empty() or extension.is_empty():
		return {}
	return resolve_resource(basename, extension)


func list_resource_variants(resref: String, resource_type: Variant) -> Array[Dictionary]:
	var normalized_type := _normalize_resource_type(resource_type)
	if normalized_type < 0:
		return []
	var key := _resource_key(resref, normalized_type)
	var variants: Array = _resource_variants.get(key, [])
	var results: Array[Dictionary] = []
	for variant: Dictionary in variants:
		results.append(variant.duplicate(true))
	return results


func list_resource_variants_for_entry(entry: Dictionary) -> Array[Dictionary]:
	if entry.is_empty():
		return []
	return list_resource_variants(
		str(entry.get("resref", "")),
		int(entry.get("resource_type", -1))
	)


func list_chitin_bif_catalog() -> Array[Dictionary]:
	if key_index.is_empty():
		return []

	var key_counts: Dictionary = {}
	for key_entry: KEYBIFParser.KEYEntry in key_index.get("key_entries", []):
		var bif_index := key_entry.bif_index
		key_counts[bif_index] = int(key_counts.get(bif_index, 0)) + 1

	var catalog: Array[Dictionary] = []
	var bif_entries: Array = key_index.get("bif_entries", [])
	for bif_index in bif_entries.size():
		var bif_entry: KEYBIFParser.BIFEntry = bif_entries[bif_index]
		var absolute_path := str(_bif_path_cache.get(bif_index, ""))
		if absolute_path.is_empty() and not str(bif_entry.filename).is_empty():
			absolute_path = game_path.path_join(_normalize_game_path(str(bif_entry.filename)))
		catalog.append({
			"bif_index": bif_index,
			"filename": bif_entry.filename,
			"location": _relative_to_game_path(absolute_path),
			"absolute_path": absolute_path,
			"file_size": bif_entry.file_size,
			"key_entry_count": int(key_counts.get(bif_index, 0)),
			"source": SOURCE_CHITIN,
		})
	return catalog


func list_chitin_resource_entries(bif_index: int = -1) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for entry: Dictionary in _resource_list:
		if str(entry.get("source", "")) != SOURCE_CHITIN:
			continue
		if bif_index >= 0 and int(entry.get("bif_index", -1)) != bif_index:
			continue
		results.append(entry.duplicate(true))
	return results


func lookup_chitin_key_entry(resref: String, resource_type: int) -> Dictionary:
	if key_index.is_empty():
		return {}
	var normalized_resref := resref.strip_edges().to_lower()
	if normalized_resref.is_empty() or resource_type < 0:
		return {}
	var key_entry: KEYBIFParser.KEYEntry = KEYBIFParser.find_key_entry(
		key_index,
		normalized_resref,
		resource_type
	)
	if key_entry == null:
		return {}
	for entry: Dictionary in _resource_list:
		if str(entry.get("source", "")) != SOURCE_CHITIN:
			continue
		if str(entry.get("resref", "")).to_lower() != normalized_resref:
			continue
		if int(entry.get("resource_type", -1)) != resource_type:
			continue
		return entry.duplicate(true)
	return {}


func extract_bif_member_to_override(entry: Dictionary) -> Dictionary:
	if str(entry.get("source", "")) != SOURCE_CHITIN:
		return {"ok": false, "message": "Not a chitin.key catalog member."}
	if str(entry.get("resref", "")).strip_edges().is_empty():
		return {"ok": false, "message": "Resource entry has an invalid resref."}
	var result := KotorModdingPipeline.install_gamefs_entry_to_override(self, entry)
	return _normalize_install_result(result)


func _normalize_install_result(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		return result
	var status := str(result.get("status", ""))
	if status == "unchanged":
		result["action"] = "noop"
		result["applied"] = false
	elif status == "written":
		result["applied"] = true
	return result


func extract_bif_members_to_override(bif_index: int = -1) -> Dictionary:
	var entries := list_chitin_resource_entries(bif_index)
	if entries.is_empty():
		return {
			"ok": false,
			"applied": 0,
			"unchanged": 0,
			"skipped": 0,
			"failed": 0,
			"message": "No chitin.key members to extract.",
		}
	var applied := 0
	var unchanged := 0
	var skipped := 0
	var failed := 0
	for entry: Dictionary in entries:
		var result := extract_bif_member_to_override(entry)
		if result.is_empty():
			skipped += 1
			continue
		if not result.get("ok", false):
			if str(entry.get("resref", "")).strip_edges().is_empty():
				skipped += 1
			else:
				failed += 1
			continue
		var status := str(result.get("status", ""))
		if result.get("applied", false) or status == "written":
			applied += 1
		elif result.get("action", "") == "noop" or status == "unchanged":
			unchanged += 1
		else:
			failed += 1
	var message := "Extracted %d chitin member(s) to override (%d unchanged, %d skipped, %d failed)." % [
		applied,
		unchanged,
		skipped,
		failed,
	]
	return {
		"ok": failed == 0,
		"applied": applied,
		"unchanged": unchanged,
		"skipped": skipped,
		"failed": failed,
		"message": message,
	}


func extract_bif_members_to_folder(dest_dir: String, bif_index: int = -1) -> Dictionary:
	var folder := dest_dir.strip_edges()
	if folder.is_empty():
		return {"ok": false, "message": "Choose a destination folder.", "written": 0, "skipped": 0, "failed": 0}
	var mkdir_err := DirAccess.make_dir_recursive_absolute(folder)
	if mkdir_err != OK and not DirAccess.dir_exists_absolute(folder):
		return {"ok": false, "message": "Could not create destination folder: %s" % folder, "written": 0, "skipped": 0, "failed": 0}
	var entries := list_chitin_resource_entries(bif_index)
	if entries.is_empty():
		return {"ok": false, "message": "No chitin.key members to extract.", "written": 0, "skipped": 0, "failed": 0}
	var written := 0
	var skipped := 0
	var failed := 0
	for entry: Dictionary in entries:
		var file_name := "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]
		if file_name.strip_edges().is_empty() or file_name.find("..") != -1:
			skipped += 1
			continue
		var out_path := folder.path_join(file_name)
		var result := KotorModdingPipeline.export_gamefs_entry(self, entry, out_path)
		if not result.get("ok", false):
			failed += 1
			continue
		if result.get("action", "") == "noop":
			skipped += 1
		else:
			written += 1
	return {
		"ok": failed == 0,
		"written": written,
		"skipped": skipped,
		"failed": failed,
		"message": "Extracted %d chitin member(s) to folder (%d skipped, %d failed)." % [
			written,
			skipped,
			failed,
		],
	}


func list_core_resources(
		query: String = "",
		resource_type: Variant = null,
		source: String = "",
		limit: int = 0
) -> Array[Dictionary]:
	var normalized_type := _normalize_resource_type(resource_type) if resource_type != null else -1
	var normalized_query := query.strip_edges().to_lower()
	var normalized_source := source.strip_edges().to_lower()
	var results: Array[Dictionary] = []

	for entry: Dictionary in _resource_list:
		if normalized_type >= 0 and int(entry.get("resource_type", -1)) != normalized_type:
			continue
		if not normalized_source.is_empty() and str(entry.get("source", "")).to_lower() != normalized_source:
			continue
		if not normalized_query.is_empty():
			var haystack := "%s %s %s %s" % [
				entry.get("resref", ""),
				entry.get("extension", ""),
				entry.get("source", ""),
				entry.get("location", ""),
			]
			if not haystack.to_lower().contains(normalized_query):
				continue
		results.append(entry.duplicate(true))
		if limit > 0 and results.size() >= limit:
			break
	return results


func list_container_resources(
		container_path: String,
		query: String = "",
		resource_type: Variant = null,
		limit: int = 0
) -> Array[Dictionary]:
	var normalized_container := _normalize_game_path(container_path)
	if normalized_container.is_empty():
		return []
	var normalized_type := _normalize_resource_type(resource_type) if resource_type != null else -1
	var normalized_query := query.strip_edges().to_lower()
	var results: Array[Dictionary] = []

	for entry: Dictionary in _resource_list:
		if _normalize_game_path(str(entry.get("container_path", ""))) != normalized_container:
			continue
		if normalized_type >= 0 and int(entry.get("resource_type", -1)) != normalized_type:
			continue
		if not normalized_query.is_empty():
			var haystack := "%s %s %s" % [
				entry.get("resref", ""),
				entry.get("extension", ""),
				entry.get("location", ""),
			]
			if not haystack.to_lower().contains(normalized_query):
				continue
		results.append(entry.duplicate(true))
		if limit > 0 and results.size() >= limit:
			break
	return results


func load_resource_bytes(resref: String, resource_type: Variant) -> PackedByteArray:
	var entry := resolve_resource(resref, resource_type)
	if entry.is_empty():
		return PackedByteArray()
	return load_resource_entry_bytes(entry)


func load_resource_entry_bytes(entry: Dictionary) -> PackedByteArray:
	var source := str(entry.get("source", ""))
	match source:
		SOURCE_OVERRIDE, SOURCE_DIALOG_TLK:
			return _read_file_bytes(str(entry.get("absolute_path", "")))
		SOURCE_MODULES:
			return _load_archive_entry_bytes(entry)
		SOURCE_CHITIN:
			return _load_bif_resource_bytes(entry)
		_:
			return _read_file_bytes(str(entry.get("absolute_path", "")))


func ensure_override_path() -> String:
	if not override_path.is_empty():
		if DirAccess.dir_exists_absolute(override_path):
			return override_path
		var existing_err := DirAccess.make_dir_recursive_absolute(override_path)
		return override_path if existing_err == OK or DirAccess.dir_exists_absolute(override_path) else ""
	if game_path.is_empty() or not DirAccess.dir_exists_absolute(game_path):
		return ""
	var candidate := game_path.path_join(OVERRIDE_DIR_NAME)
	var err := DirAccess.make_dir_recursive_absolute(candidate)
	if err != OK and not DirAccess.dir_exists_absolute(candidate):
		return ""
	override_path = candidate
	return override_path


func ensure_modules_path() -> String:
	if not modules_path.is_empty():
		if DirAccess.dir_exists_absolute(modules_path):
			return modules_path
		var existing_err := DirAccess.make_dir_recursive_absolute(modules_path)
		return modules_path if existing_err == OK or DirAccess.dir_exists_absolute(modules_path) else ""
	if game_path.is_empty() or not DirAccess.dir_exists_absolute(game_path):
		return ""
	for candidate: String in [game_path.path_join(MODULES_DIR_NAME), game_path.path_join("Modules")]:
		if DirAccess.dir_exists_absolute(candidate):
			modules_path = candidate
			return modules_path
	var created := game_path.path_join(MODULES_DIR_NAME)
	var err := DirAccess.make_dir_recursive_absolute(created)
	if err != OK and not DirAccess.dir_exists_absolute(created):
		return ""
	modules_path = created
	return modules_path


func resource_extension(resource_type: int) -> String:
	return str(ERFParser.RES_TYPES.get(resource_type, "bin"))


func resource_type_for_extension(extension: String) -> int:
	return int(_extension_type_map.get(extension.trim_prefix(".").to_lower(), -1))


func _index_dialog_tlk() -> void:
	if dialog_tlk_path.is_empty():
		return
	dialog_tlk = TLKParser.parse_file(dialog_tlk_path)
	if dialog_tlk.is_empty():
		return
	_dialog_count = 1
	_set_resource_entry({
		"resref": DIALOG_TLK_RESREF,
		"resource_type": DIALOG_TLK_TYPE,
		"extension": resource_extension(DIALOG_TLK_TYPE),
		"source": SOURCE_DIALOG_TLK,
		"location": _relative_to_game_path(dialog_tlk_path),
		"absolute_path": dialog_tlk_path,
		"size": _safe_file_len(dialog_tlk_path),
	})


func _index_override() -> void:
	if override_path.is_empty():
		return
	var dir := DirAccess.open(override_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if file_name.begins_with(".") or dir.current_is_dir():
			continue
		var extension := file_name.get_extension().to_lower()
		var resource_type := resource_type_for_extension(extension)
		if resource_type < 0:
			continue
		var absolute_path := override_path.path_join(file_name)
		_override_count += 1
		_set_resource_entry({
			"resref": file_name.get_basename().get_file(),
			"resource_type": resource_type,
			"extension": extension,
			"source": SOURCE_OVERRIDE,
			"location": _relative_to_game_path(absolute_path),
			"absolute_path": absolute_path,
			"size": _safe_file_len(absolute_path),
		})
	dir.list_dir_end()


func _index_module_archives() -> void:
	if modules_path.is_empty():
		return
	var dir := DirAccess.open(modules_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if file_name.begins_with(".") or dir.current_is_dir():
			continue
		var extension := file_name.get_extension().to_lower()
		if extension != "rim" and extension != "mod":
			continue
		var archive_path := modules_path.path_join(file_name)
		var parsed := ERFParser.parse_header_file(archive_path)
		if parsed.is_empty():
			continue
		_module_archive_count += 1
		for erf_entry: ERFParser.ERFEntry in parsed.get("entries", []):
			if not MODULE_INDEX_EXTENSIONS.has(erf_entry.extension):
				continue
			_module_resource_count += 1
			_set_resource_entry({
				"resref": erf_entry.resref,
				"resource_type": erf_entry.resource_type,
				"extension": erf_entry.extension,
				"source": SOURCE_MODULES,
				"location": "%s::%s.%s" % [
					_relative_to_game_path(archive_path),
					erf_entry.resref,
					erf_entry.extension,
				],
				"absolute_path": archive_path,
				"container_path": archive_path,
				"container_name": file_name,
				"size": erf_entry.size,
				"archive_offset": erf_entry.offset,
				"archive_size": erf_entry.size,
			})
	dir.list_dir_end()


func _index_chitin_key() -> void:
	if chitin_key_path.is_empty():
		return
	key_index = KEYBIFParser.parse_key_file(chitin_key_path)
	if key_index.is_empty():
		return

	var bif_entries: Array = key_index.get("bif_entries", [])
	for bif_index in bif_entries.size():
		var bif_entry: KEYBIFParser.BIFEntry = bif_entries[bif_index]
		_bif_path_cache[bif_index] = game_path.path_join(_normalize_game_path(str(bif_entry.filename)))

	for key_entry: KEYBIFParser.KEYEntry in key_index.get("key_entries", []):
		_chitin_count += 1
		var resource_type := key_entry.resource_type
		var bif_path := str(_bif_path_cache.get(key_entry.bif_index, ""))
		_set_resource_entry({
			"resref": key_entry.resref,
			"resource_type": resource_type,
			"extension": resource_extension(resource_type),
			"source": SOURCE_CHITIN,
			"location": _relative_to_game_path(bif_path),
			"absolute_path": bif_path,
			"bif_index": key_entry.bif_index,
			"fixed_index": key_entry.fixed_index,
			"size": -1,
		})


func _load_bif_resource_bytes(entry: Dictionary) -> PackedByteArray:
	var bif_index := int(entry.get("bif_index", -1))
	var fixed_index := int(entry.get("fixed_index", -1))
	if bif_index < 0 or fixed_index < 0:
		return PackedByteArray()

	var bif_data := _get_bif_bytes(bif_index)
	if bif_data.is_empty():
		return PackedByteArray()

	var bif_entries: Array = _get_bif_entries(bif_index, bif_data)
	for bif_entry: KEYBIFParser.BIFResEntry in bif_entries:
		if (bif_entry.res_id & 0xFFFFF) != fixed_index:
			continue
		return bif_data.slice(bif_entry.offset, bif_entry.offset + bif_entry.file_size)
	return PackedByteArray()


func _load_archive_entry_bytes(entry: Dictionary) -> PackedByteArray:
	var archive_path := str(entry.get("absolute_path", entry.get("container_path", "")))
	var offset := int(entry.get("archive_offset", -1))
	var size := int(entry.get("archive_size", entry.get("size", -1)))
	if archive_path.is_empty() or offset < 0 or size <= 0:
		return PackedByteArray()
	return _read_file_range(archive_path, offset, size)


func _get_bif_bytes(bif_index: int) -> PackedByteArray:
	if _bif_bytes_cache.has(bif_index):
		return _bif_bytes_cache[bif_index]
	var path := str(_bif_path_cache.get(bif_index, ""))
	var bytes := _read_file_bytes(path)
	if not bytes.is_empty():
		_bif_bytes_cache[bif_index] = bytes
	return bytes


func _get_bif_entries(bif_index: int, bif_data: PackedByteArray) -> Array:
	if _bif_entries_cache.has(bif_index):
		return _bif_entries_cache[bif_index]
	var parsed := KEYBIFParser.parse_bif_bytes(bif_data)
	var entries: Array = parsed.get("var_entries", [])
	_bif_entries_cache[bif_index] = entries
	return entries


func _set_resource_entry(entry: Dictionary) -> void:
	var key := _resource_key(str(entry.get("resref", "")), int(entry.get("resource_type", -1)))
	if not _resource_variants.has(key):
		_resource_variants[key] = []
	(_resource_variants[key] as Array).append(entry.duplicate(true))
	_resource_index[key] = entry


func _rebuild_resource_list() -> void:
	_resource_list.clear()
	for resource_key: String in _resource_index.keys():
		_resource_list.append((_resource_index[resource_key] as Dictionary).duplicate(true))
	_resource_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_resref := str(a.get("resref", "")).to_lower()
		var b_resref := str(b.get("resref", "")).to_lower()
		if a_resref != b_resref:
			return a_resref < b_resref
		var a_type := int(a.get("resource_type", -1))
		var b_type := int(b.get("resource_type", -1))
		if a_type != b_type:
			return a_type < b_type
		return str(a.get("source", "")).to_lower() < str(b.get("source", "")).to_lower()
	)


func _resource_key(resref: String, resource_type: int) -> String:
	return "%s:%d" % [resref.to_lower(), resource_type]


func _normalize_resource_type(resource_type: Variant) -> int:
	match typeof(resource_type):
		TYPE_INT:
			return int(resource_type)
		TYPE_STRING, TYPE_STRING_NAME:
			return resource_type_for_extension(str(resource_type))
		_:
			return -1


func _build_extension_type_map() -> void:
	if not _extension_type_map.is_empty():
		return
	for resource_type: int in ERFParser.RES_TYPES:
		var extension := str(ERFParser.RES_TYPES[resource_type]).to_lower()
		if not _extension_type_map.has(extension):
			_extension_type_map[extension] = resource_type


func _normalize_game_path(path: String) -> String:
	return path.replace("\\", "/").strip_edges()


func _relative_to_game_path(path: String) -> String:
	if path.is_empty():
		return ""
	var normalized_game_path := _normalize_game_path(game_path).trim_suffix("/")
	var normalized_path := _normalize_game_path(path)
	if normalized_path.begins_with(normalized_game_path + "/"):
		return normalized_path.substr(normalized_game_path.length() + 1)
	return normalized_path


func _find_dialog_tlk_path(install_path: String) -> String:
	return _find_existing_file([
		install_path.path_join("dialog.tlk"),
		install_path.path_join("dialog").path_join("dialog.tlk"),
	])


func _find_chitin_key_path(install_path: String) -> String:
	return _find_existing_file([install_path.path_join(CHITIN_KEY_NAME)])


func _find_modules_path(install_path: String) -> String:
	for candidate: String in [install_path.path_join(MODULES_DIR_NAME), install_path.path_join("Modules")]:
		if DirAccess.dir_exists_absolute(candidate):
			return candidate
	return ""


func _find_override_path(install_path: String) -> String:
	var candidates := [
		install_path.path_join(OVERRIDE_DIR_NAME),
		install_path.path_join("Override"),
	]
	for candidate: String in candidates:
		if DirAccess.dir_exists_absolute(candidate):
			return candidate
	return ""


func _find_existing_file(candidates: Array[String]) -> String:
	for candidate: String in candidates:
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


func _read_file_bytes(path: String) -> PackedByteArray:
	if path.is_empty() or not FileAccess.file_exists(path):
		return PackedByteArray()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var data := file.get_buffer(file.get_length())
	file.close()
	return data


func _read_file_range(path: String, offset: int, size: int) -> PackedByteArray:
	if path.is_empty() or not FileAccess.file_exists(path) or offset < 0 or size <= 0:
		return PackedByteArray()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	if offset > file.get_length():
		file.close()
		return PackedByteArray()
	file.seek(offset)
	var data := file.get_buffer(size)
	file.close()
	return data


func _safe_file_len(path: String) -> int:
	if path.is_empty() or not FileAccess.file_exists(path):
		return -1
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var size := file.get_length()
	file.close()
	return size
