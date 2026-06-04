## Holocron/PyKotor indoor kit folder loader (headless, v1 component kits).
class_name KotorIndoorKitLoader

const BWMParser := preload("../../formats/bwm_parser.gd")


static func load_kits_from_directory(kits_path: String) -> Dictionary:
	var result := {"kits": [], "errors": []}
	var normalized := kits_path.strip_edges()
	if normalized.is_empty() or not DirAccess.dir_exists_absolute(normalized):
		result["errors"].append("Kits directory does not exist: %s" % normalized)
		return result

	var dir := DirAccess.open(normalized)
	if dir == null:
		result["errors"].append("Failed to open kits directory: %s" % normalized)
		return result

	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if not dir.current_is_dir() and entry_name.to_lower().ends_with(".json"):
			var kit_file := normalized.path_join(entry_name)
			_load_kit_json(kit_file, normalized, result)
		entry_name = dir.get_next()
	dir.list_dir_end()

	var kits: Array = result["kits"]
	kits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")).nocasecmp_to(str(b.get("id", ""))) < 0
	)
	result["kits"] = kits
	return result


static func _load_kit_json(kit_file: String, kits_root: String, result: Dictionary) -> void:
	var file := FileAccess.open(kit_file, FileAccess.READ)
	if file == null:
		result["errors"].append("Failed to read kit JSON: %s" % kit_file)
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		result["errors"].append("Invalid kit JSON: %s" % kit_file)
		return
	var kit_json: Dictionary = parsed
	if not kit_json.has("name"):
		return
	if int(kit_json.get("format_version", 0)) == 2:
		return

	var kit_id := str(kit_json.get("id", kit_file.get_file().get_basename()))
	var kit_name := str(kit_json.get("name", kit_id))
	var base_path := kits_root.path_join(kit_id)
	var doors := _parse_doors(kit_json.get("doors", []))
	var components: Array[Dictionary] = []
	var components_json: Variant = kit_json.get("components", [])
	if typeof(components_json) == TYPE_ARRAY:
		for raw_component in components_json:
			if typeof(raw_component) != TYPE_DICTIONARY:
				continue
			var component := _load_component(raw_component as Dictionary, base_path, kit_name, doors, result)
			if not component.is_empty():
				components.append(component)

	if components.is_empty():
		result["errors"].append("Kit %s has no loadable components" % kit_id)
		return

	result["kits"].append({
		"id": kit_id,
		"name": kit_name,
		"doors": doors,
		"components": components,
	})


static func _parse_doors(raw_doors: Variant) -> Array[Dictionary]:
	var doors: Array[Dictionary] = []
	if typeof(raw_doors) != TYPE_ARRAY:
		return doors
	for raw_door in raw_doors:
		if typeof(raw_door) != TYPE_DICTIONARY:
			continue
		var door: Dictionary = raw_door
		doors.append({
			"utd_k1": str(door.get("utd_k1", "")),
			"utd_k2": str(door.get("utd_k2", "")),
			"width": float(door.get("width", 0.0)),
			"height": float(door.get("height", 0.0)),
		})
	return doors


static func _load_component(
	component_json: Dictionary,
	base_path: String,
	kit_name: String,
	doors: Array[Dictionary],
	result: Dictionary
) -> Dictionary:
	if not component_json.has("name") or not component_json.has("id"):
		return {}
	var component_id := str(component_json.get("id", ""))
	var component_name := str(component_json.get("name", component_id))
	if component_id.is_empty():
		return {}

	var wok_path := base_path.path_join("%s.wok" % component_id)
	if not FileAccess.file_exists(wok_path):
		result["errors"].append(
			"[%s] missing walkmesh: %s" % [kit_name, wok_path]
		)
		return {}

	var wok_file := FileAccess.open(wok_path, FileAccess.READ)
	if wok_file == null:
		result["errors"].append("[%s] failed to read walkmesh: %s" % [kit_name, wok_path])
		return {}
	var wok_bytes := wok_file.get_buffer(wok_file.get_length())
	wok_file.close()
	var parsed_bwm := BWMParser.parse_bytes(wok_bytes)
	if parsed_bwm.is_empty():
		result["errors"].append("[%s] invalid walkmesh: %s" % [kit_name, wok_path])
		return {}

	var footprint := _footprint_from_bwm(parsed_bwm)
	var mdl_path := base_path.path_join("%s.mdl" % component_id)
	var mdx_path := base_path.path_join("%s.mdx" % component_id)
	var hooks := _parse_hooks(component_json.get("doorhooks", []), doors)

	return {
		"id": component_id,
		"name": component_name,
		"hooks": hooks,
		"half_width": footprint.x,
		"half_height": footprint.y,
		"has_mdl": FileAccess.file_exists(mdl_path),
		"has_mdx": FileAccess.file_exists(mdx_path),
	}


static func _parse_hooks(raw_hooks: Variant, doors: Array[Dictionary]) -> Array[Dictionary]:
	var hooks: Array[Dictionary] = []
	if typeof(raw_hooks) != TYPE_ARRAY:
		return hooks
	for raw_hook in raw_hooks:
		if typeof(raw_hook) != TYPE_DICTIONARY:
			continue
		var hook: Dictionary = raw_hook
		var door_index := int(hook.get("door", -1))
		if door_index < 0 or door_index >= doors.size():
			continue
		hooks.append({
			"x": float(hook.get("x", 0.0)),
			"y": float(hook.get("y", 0.0)),
			"z": float(hook.get("z", 0.0)),
			"rotation": float(hook.get("rotation", 0.0)),
			"door": door_index,
			"edge": int(hook.get("edge", 0)),
		})
	return hooks


static func _footprint_from_bwm(parsed: Dictionary) -> Vector2:
	var bounds := BWMParser.compute_bounds(parsed)
	if bounds.size == Vector3.ZERO:
		return Vector2(2.0, 2.0)
	var half_x := maxf(bounds.size.x * 0.5, 0.5)
	var half_y := maxf(bounds.size.z * 0.5, 0.5)
	return Vector2(half_x, half_y)
