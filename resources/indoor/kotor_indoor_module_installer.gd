## Install native indoor `.mod` files into a KotOR game `modules/` folder.
class_name KotorIndoorModuleInstaller

const ERFParser := preload("../../formats/erf_parser.gd")
const KotorGameFS := preload("../../gamefs/kotor_gamefs.gd")
const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const KotorIndoorModBuilder := preload("./kotor_indoor_mod_builder.gd")
const KotorIndoorNativeExporter := preload("./kotor_indoor_native_exporter.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")

const MODULES_DIR_NAMES := ["modules", "Modules"]


static func validate_preflight(config: Dictionary) -> Dictionary:
	var export_preflight := KotorIndoorNativeExporter.validate_preflight(config)
	var errors: Array = export_preflight.get("errors", []).duplicate()
	var warnings: Array = export_preflight.get("warnings", []).duplicate()

	var game_path := str(config.get("game_path", "")).strip_edges()
	if game_path.is_empty():
		errors.append("Configure a KotOR game install path in editor settings.")
	elif not DirAccess.dir_exists_absolute(game_path):
		errors.append("Game install path does not exist: %s" % game_path)
	else:
		var modules_path := resolve_modules_path(game_path)
		if modules_path.is_empty():
			errors.append("Could not resolve or create the game modules folder.")

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func install_indoor_mod_to_modules(config: Dictionary) -> Dictionary:
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

	var built := KotorIndoorModBuilder.build_from_document(document, kit_library)
	if not built.get("ok", false):
		return {
			"ok": false,
			"message": _join_lines(built.get("errors", [])),
			"errors": built.get("errors", []),
			"warnings": built.get("warnings", []),
		}

	var game_path := str(config.get("game_path", "")).strip_edges()
	var modules_path := resolve_modules_path(game_path)
	if modules_path.is_empty():
		return {"ok": false, "message": "Could not resolve modules folder for install."}

	var module_id := str(built.get("module_id", "")).strip_edges().to_lower()
	if module_id.is_empty() and document != null:
		module_id = document.get_module_id().strip_edges().to_lower()
	if module_id.is_empty():
		return {"ok": false, "message": "Indoor layout has no module ID."}

	var target_path := modules_path.path_join("%s.mod" % module_id)
	var mod_bytes: PackedByteArray = built.get("bytes", PackedByteArray())
	var write_result := KotorModdingPipeline.write_payload_to_path_with_backup(
		target_path,
		mod_bytes,
		"%s.mod" % module_id
	)
	if not write_result.get("ok", false):
		return {
			"ok": false,
			"message": str(write_result.get("message", "Failed to install module.")),
			"errors": [str(write_result.get("message", "Failed to install module."))],
			"warnings": built.get("warnings", []),
		}

	var warnings: Array = preflight.get("warnings", []).duplicate()
	for warning_text in built.get("warnings", []):
		warnings.append(str(warning_text))

	return {
		"ok": true,
		"message": "Installed %s.mod to modules" % module_id,
		"output_path": target_path,
		"module_id": module_id,
		"entry_count": built.get("entry_count", 0),
		"backup_path": str(write_result.get("backup_path", "")),
		"warnings": warnings,
	}


static func resolve_modules_path(game_path: String) -> String:
	var normalized := game_path.strip_edges()
	if normalized.is_empty() or not DirAccess.dir_exists_absolute(normalized):
		return ""
	for dir_name in MODULES_DIR_NAMES:
		var candidate := normalized.path_join(dir_name)
		if DirAccess.dir_exists_absolute(candidate):
			return candidate
	var created := normalized.path_join(KotorGameFS.MODULES_DIR_NAME)
	var err := DirAccess.make_dir_recursive_absolute(created)
	if err == OK or DirAccess.dir_exists_absolute(created):
		return created
	return ""


static func list_core_resource_names(parsed: Dictionary) -> Array[String]:
	return KotorIndoorModBuilder.list_entry_names(parsed)


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)
