## Cached Holocron/PyKotor indoor kit library for the Indoor Builder.
class_name KotorIndoorKitLibrary
extends RefCounted

const KotorIndoorKitLoader := preload("./kotor_indoor_kit_loader.gd")

var _kits_path := ""
var _kits_by_id: Dictionary = {}
var _last_errors: Array[String] = []


func configure(kits_path: String) -> void:
	_kits_path = kits_path.strip_edges()


func get_kits_path() -> String:
	return _kits_path


func refresh() -> void:
	_kits_by_id.clear()
	_last_errors.clear()
	if _kits_path.is_empty() or not DirAccess.dir_exists_absolute(_kits_path):
		if not _kits_path.is_empty():
			_last_errors.append("Kits directory does not exist: %s" % _kits_path)
		return
	var loaded := KotorIndoorKitLoader.load_kits_from_directory(_kits_path)
	for error_text in loaded.get("errors", []):
		_last_errors.append(str(error_text))
	for raw_kit in loaded.get("kits", []):
		if typeof(raw_kit) != TYPE_DICTIONARY:
			continue
		var kit: Dictionary = raw_kit
		var kit_id := str(kit.get("id", ""))
		if kit_id.is_empty():
			continue
		_kits_by_id[kit_id] = kit


func get_kit_count() -> int:
	return _kits_by_id.size()


func get_kit_ids() -> Array[String]:
	var ids: Array[String] = []
	for kit_id in _kits_by_id.keys():
		ids.append(str(kit_id))
	ids.sort()
	return ids


func get_kit_name(kit_id: String) -> String:
	var kit: Dictionary = _kits_by_id.get(kit_id, {})
	if kit.is_empty():
		return kit_id
	return str(kit.get("name", kit_id))


func get_component_summaries(kit_id: String) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	var kit: Dictionary = _kits_by_id.get(kit_id, {})
	if kit.is_empty():
		return summaries
	var components: Variant = kit.get("components", [])
	if typeof(components) != TYPE_ARRAY:
		return summaries
	for raw_component in components:
		if typeof(raw_component) != TYPE_DICTIONARY:
			continue
		var component: Dictionary = raw_component
		summaries.append({
			"id": str(component.get("id", "")),
			"name": str(component.get("name", "")),
			"half_width": float(component.get("half_width", 2.0)),
			"half_height": float(component.get("half_height", 2.0)),
			"hook_count": int((component.get("hooks", []) as Array).size()),
			"has_mdl": bool(component.get("has_mdl", false)),
			"has_mdx": bool(component.get("has_mdx", false)),
		})
	return summaries


func find_component(kit_id: String, component_id: String) -> Dictionary:
	var kit: Dictionary = _kits_by_id.get(kit_id, {})
	if kit.is_empty():
		return {}
	var components: Variant = kit.get("components", [])
	if typeof(components) != TYPE_ARRAY:
		return {}
	for raw_component in components:
		if typeof(raw_component) != TYPE_DICTIONARY:
			continue
		var component: Dictionary = raw_component
		if str(component.get("id", "")) == component_id:
			return component
	return {}


func get_component_footprint(kit_id: String, component_id: String) -> Vector2:
	var component := find_component(kit_id, component_id)
	if component.is_empty():
		return Vector2(2.0, 2.0)
	return Vector2(
		float(component.get("half_width", 2.0)),
		float(component.get("half_height", 2.0))
	)


func has_component(kit_id: String, component_id: String) -> bool:
	return not find_component(kit_id, component_id).is_empty()


func get_last_errors() -> Array[String]:
	return _last_errors.duplicate()
