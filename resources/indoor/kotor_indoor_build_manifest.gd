## Expected module outputs for a validated `.indoor` layout (native build planning).
class_name KotorIndoorBuildManifest

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const KotorIndoorLayoutValidator := preload("./kotor_indoor_layout_validator.gd")
const KotorIndoorMapIO := preload("./kotor_indoor_map_io.gd")
const KotorIndoorLyTBuilder := preload("./kotor_indoor_lyt_builder.gd")

const CORE_MODULE_EXTENSIONS := ["are", "git", "ifo", "lyt", "vis"]
const MODULE_ID_MAX_LEN := 16


static func build(document: KotorIndoorDocument, kit_library: RefCounted = null) -> Dictionary:
	var validation := KotorIndoorLayoutValidator.validate(document, kit_library)
	if not validation.get("ok", false):
		return {
			"ok": false,
			"errors": validation.get("errors", []),
			"warnings": validation.get("warnings", []),
		}

	if kit_library == null:
		kit_library = document.get_kit_library()

	var module_id := normalize_module_id(document.get_module_id())
	var resources: Array[Dictionary] = []
	for extension in CORE_MODULE_EXTENSIONS:
		resources.append({
			"resref": module_id,
			"extension": extension,
			"kind": "core_module",
		})

	var room_assets: Array[Dictionary] = []
	var unique_assets := {}
	for index in document.get_room_count():
		var room := document.get_room_dictionary(index)
		var kit_id := str(room.get("kit", "")).strip_edges()
		var component_id := str(room.get("component", "")).strip_edges()
		var asset := {
			"room_index": index,
			"kit": kit_id,
			"component": component_id,
			"model_resref": component_id,
			"walkmesh_resref": component_id,
			"has_mdl": false,
			"has_mdx": false,
		}
		if kit_id == KotorIndoorMapIO.EMBEDDED_KIT_ID:
			if document.has_embedded_component(component_id):
				asset["has_mdl"] = true
		elif kit_library != null and kit_library.has_method("find_component"):
			var component: Dictionary = kit_library.call("find_component", kit_id, component_id)
			asset["has_mdl"] = bool(component.get("has_mdl", false))
			asset["has_mdx"] = bool(component.get("has_mdx", false))
		room_assets.append(asset)

		for extension in ["mdl", "wok"]:
			var key := "%s.%s" % [component_id, extension]
			if unique_assets.has(key):
				continue
			unique_assets[key] = true
			resources.append({
				"resref": component_id,
				"extension": extension,
				"kind": "room_%s" % ("model" if extension == "mdl" else "walkmesh"),
				"room_index": index,
			})

	var hook_counts := document.get_hook_connection_counts()
	var lyt := KotorIndoorLyTBuilder.build_from_document(document)
	return {
		"ok": true,
		"module_id": module_id,
		"warp": str(document.get_data().get("warp", module_id)),
		"resources": resources,
		"room_assets": room_assets,
		"hook_counts": hook_counts,
		"warnings": validation.get("warnings", []),
		"lyt": lyt,
	}


static func normalize_module_id(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	if normalized.length() > MODULE_ID_MAX_LEN:
		normalized = normalized.substr(0, MODULE_ID_MAX_LEN)
	return normalized


static func format_report(manifest: Dictionary) -> String:
	if manifest.is_empty():
		return "No build manifest."
	if not manifest.get("ok", false):
		var lines: Array[String] = ["Build manifest unavailable:"]
		for error_text in manifest.get("errors", []):
			lines.append("- %s" % str(error_text))
		for warning_text in manifest.get("warnings", []):
			lines.append("Warning: %s" % str(warning_text))
		return "\n".join(lines)

	var lines: Array[String] = []
	lines.append("Module ID: %s" % str(manifest.get("module_id", "")))
	lines.append("Warp: %s" % str(manifest.get("warp", "")))
	var hook_counts: Dictionary = manifest.get("hook_counts", {})
	lines.append(
		"Hook connections: %d connected, %d open"
		% [int(hook_counts.get("connected", 0)), int(hook_counts.get("open", 0))]
	)
	var lyt: Dictionary = manifest.get("lyt", {})
	if lyt.get("ok", false):
		lines.append("LYT preview: %d room model(s) ready" % int(lyt.get("room_count", 0)))
	else:
		for error_text in lyt.get("errors", []):
			lines.append("LYT preview unavailable: %s" % str(error_text))
	lines.append("Core module resources:")
	for resource in manifest.get("resources", []):
		if typeof(resource) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = resource
		if str(entry.get("kind", "")) != "core_module":
			continue
		lines.append("  %s.%s" % [entry.get("resref", ""), entry.get("extension", "")])

	var room_assets: Array = manifest.get("room_assets", [])
	if not room_assets.is_empty():
		lines.append("Room assets:")
		for raw_asset in room_assets:
			if typeof(raw_asset) != TYPE_DICTIONARY:
				continue
			var asset: Dictionary = raw_asset
			var model_flags := "mdl"
			if bool(asset.get("has_mdx", false)):
				model_flags += "+mdx"
			if not bool(asset.get("has_mdl", false)):
				model_flags = "mdl missing"
			lines.append(
				"  Room %d: %s/%s -> %s.%s, %s.wok (%s)"
				% [
					int(asset.get("room_index", 0)),
					asset.get("kit", ""),
					asset.get("component", ""),
					asset.get("model_resref", ""),
					"mdl",
					asset.get("walkmesh_resref", ""),
					model_flags,
				]
			)

	for warning_text in manifest.get("warnings", []):
		lines.append("Warning: %s" % str(warning_text))

	return "\n".join(lines)
