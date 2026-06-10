## ModuleKit loader — synthesize indoor-kit components from install module LYT rooms.
class_name KotorModuleKitLoader

const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")
const BWMParser := preload("../../formats/bwm_parser.gd")

const DEFAULT_DOOR := {
	"utd_k1": "sw_door",
	"utd_k2": "sw_door",
	"width": 2.0,
	"height": 3.0,
}


## Return sorted module roots that have an indexed LYT resource.
static func discover_module_roots(gamefs: RefCounted, source_filter: String = "") -> Array[String]:
	var roots: Dictionary = {}
	if gamefs == null or not gamefs.has_method("list_core_resources"):
		return []
	var entries: Array = gamefs.list_core_resources("", "lyt", source_filter, 0)
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var resref := str(entry.get("resref", "")).strip_edges().to_lower()
		if resref.is_empty():
			continue
		roots[resref] = true
	var sorted_roots: Array[String] = []
	for root_name in roots.keys():
		sorted_roots.append(str(root_name))
	sorted_roots.sort()
	return sorted_roots


## Build a Holocron/PyKotor-compatible kit dictionary from a module bundle.
static func load_module_kit(gamefs: RefCounted, module_root: String) -> Dictionary:
	var normalized := module_root.strip_edges().to_lower()
	if gamefs == null or normalized.is_empty():
		return {"ok": false, "message": "Module root is required."}

	var bundle := KotorModuleContext.find_module_bundle(gamefs, normalized)
	var lyt_entry: Dictionary = bundle.get("lyt", {})
	if lyt_entry.is_empty():
		return {"ok": false, "message": "Module '%s' has no LYT resource." % normalized}

	var layout := KotorModuleContext.load_parsed_layout(gamefs, bundle)
	var rooms: Array = layout.get("rooms", [])
	if rooms.is_empty():
		return {"ok": false, "message": "Module '%s' LYT has no rooms." % normalized}

	var components: Array[Dictionary] = []
	for room_index in range(rooms.size()):
		var raw_room = rooms[room_index]
		if typeof(raw_room) != TYPE_DICTIONARY:
			continue
		var room: Dictionary = raw_room
		var component := _component_from_lyt_room(gamefs, room, room_index)
		if not component.is_empty():
			components.append(component)

	if components.is_empty():
		return {"ok": false, "message": "Module '%s' produced no loadable components." % normalized}

	return {
		"ok": true,
		"kit": {
			"id": normalized,
			"name": "Module: %s" % normalized.to_upper(),
			"is_module_kit": true,
			"module_root": normalized,
			"doors": [DEFAULT_DOOR.duplicate(true)],
			"components": components,
		},
	}


static func _component_from_lyt_room(
		gamefs: RefCounted,
		room: Dictionary,
		room_index: int
) -> Dictionary:
	var model := str(room.get("model", "")).strip_edges().to_lower()
	if model.is_empty():
		model = "room%d" % room_index
	var component_id := "%s_%d" % [model, room_index]
	var component_name := "%s_%d" % [model.to_upper(), room_index]
	var position := _read_room_position(room)

	var footprint := _footprint_for_model(gamefs, model)
	var mdl_entry: Dictionary = {}
	var mdx_entry: Dictionary = {}
	if gamefs.has_method("resolve_resource"):
		mdl_entry = gamefs.resolve_resource(model, "mdl")
		mdx_entry = gamefs.resolve_resource(model, "mdx")

	return {
		"id": component_id,
		"name": component_name,
		"model": model,
		"hooks": [],
		"half_width": footprint.x,
		"half_height": footprint.y,
		"has_mdl": not mdl_entry.is_empty(),
		"has_mdx": not mdx_entry.is_empty(),
		"default_position": [position.x, position.y, position.z],
	}


static func _footprint_for_model(gamefs: RefCounted, model_name: String) -> Vector2:
	if gamefs == null or not gamefs.has_method("resolve_resource"):
		return Vector2(2.0, 2.0)
	if not gamefs.has_method("load_resource_entry_bytes"):
		return Vector2(2.0, 2.0)
	var wok_entry: Dictionary = gamefs.resolve_resource(model_name, "wok")
	if wok_entry.is_empty():
		return Vector2(2.0, 2.0)
	var bytes: PackedByteArray = gamefs.load_resource_entry_bytes(wok_entry)
	if bytes.is_empty():
		return Vector2(2.0, 2.0)
	var parsed := BWMParser.parse_bytes(bytes)
	if parsed.is_empty():
		return Vector2(2.0, 2.0)
	return _footprint_from_bwm(parsed)


static func _footprint_from_bwm(parsed: Dictionary) -> Vector2:
	var bounds := BWMParser.compute_bounds(parsed)
	if bounds.size == Vector3.ZERO:
		return Vector2(2.0, 2.0)
	var half_x := maxf(bounds.size.x * 0.5, 0.5)
	var half_y := maxf(bounds.size.z * 0.5, 0.5)
	return Vector2(half_x, half_y)


static func _read_room_position(room: Dictionary) -> Vector3:
	var position: Variant = room.get("position", Vector3.ZERO)
	if typeof(position) == TYPE_VECTOR3:
		return position
	if typeof(position) == TYPE_ARRAY:
		var values: Array = position
		return Vector3(
			float(values[0]) if values.size() > 0 else 0.0,
			float(values[1]) if values.size() > 1 else 0.0,
			float(values[2]) if values.size() > 2 else 0.0
		)
	return Vector3.ZERO
