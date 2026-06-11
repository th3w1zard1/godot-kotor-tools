## Export `.indoor` layouts to `.mod` via native builders (no PyKotor CLI).
class_name KotorIndoorNativeExporter

const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const KotorIndoorLayoutValidator := preload("./kotor_indoor_layout_validator.gd")
const KotorIndoorMapIO := preload("./kotor_indoor_map_io.gd")
const KotorIndoorModBuilder := preload("./kotor_indoor_mod_builder.gd")


static func validate_preflight(config: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var document: KotorIndoorDocument = config.get("document")
	if document == null:
		errors.append("No indoor map is loaded.")
	else:
		var kit_library: RefCounted = config.get("kit_library")
		if kit_library == null:
			kit_library = document.get_kit_library()
		var layout := KotorIndoorLayoutValidator.validate(document, kit_library)
		for error_text in layout.get("errors", []):
			errors.append(str(error_text))
		for warning_text in layout.get("warnings", []):
			warnings.append(str(warning_text))

	var output_path := str(config.get("output_path", "")).strip_edges()
	if output_path.is_empty():
		errors.append("Choose an output .mod path.")
	elif not output_path.get_extension().to_lower() in ["mod", "erf", "rim", "sav"]:
		warnings.append("Output extension is not .mod; export will still write the chosen container.")

	if document != null and _needs_kits_path(document):
		var kits_path := str(config.get("kits_path", "")).strip_edges()
		if kits_path.is_empty():
			errors.append("Configure an indoor kits folder for kit-based rooms.")
		elif not DirAccess.dir_exists_absolute(kits_path):
			errors.append("Indoor kits folder does not exist: %s" % kits_path)

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func export_indoor_to_mod(config: Dictionary) -> Dictionary:
	var preflight := validate_preflight(config)
	if not preflight.get("ok", false):
		return {
			"ok": false,
			"message": _join_lines(preflight.get("errors", [])),
			"errors": preflight.get("errors", []),
			"warnings": preflight.get("warnings", []),
		}

	var document: KotorIndoorDocument = config.get("document")
	var kit_library: RefCounted = config.get("kit_library")
	if kit_library == null and document != null:
		kit_library = document.get_kit_library()

	var output_path := _ensure_mod_extension(str(config.get("output_path", "")).strip_edges())
	var built := KotorIndoorModBuilder.write_to_path(document, output_path, kit_library)
	if not built.get("ok", false):
		var errors: Array = built.get("errors", [])
		return {
			"ok": false,
			"message": _join_lines(errors),
			"errors": errors,
			"warnings": built.get("warnings", []),
		}

	var warnings: Array = preflight.get("warnings", []).duplicate()
	for warning_text in built.get("warnings", []):
		warnings.append(str(warning_text))

	return {
		"ok": true,
		"message": "Exported %s" % output_path.get_file(),
		"output_path": str(built.get("output_path", output_path)),
		"entry_count": built.get("entry_count", 0),
		"warnings": warnings,
	}


static func _needs_kits_path(document: KotorIndoorDocument) -> bool:
	for index in document.get_room_count():
		var room := document.get_room_dictionary(index)
		var kit_id := str(room.get("kit", "")).strip_edges()
		if kit_id.is_empty():
			continue
		if kit_id != KotorIndoorMapIO.EMBEDDED_KIT_ID:
			return true
	return false


static func _ensure_mod_extension(path: String) -> String:
	if path.get_extension().to_lower() == "mod":
		return path
	if path.get_extension().is_empty():
		return "%s.mod" % path
	return path.get_basename() + ".mod"


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)
