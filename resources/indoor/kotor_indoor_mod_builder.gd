## Assemble native indoor module outputs into a `.mod` ERF (native build slice).
class_name KotorIndoorModBuilder

const ERFParser := preload("../../formats/erf_parser.gd")
const ERFWriter := preload("../../formats/erf_writer.gd")
const KotorIndoorBuildManifest := preload("./kotor_indoor_build_manifest.gd")
const KotorIndoorDocument := preload("../documents/kotor_indoor_document.gd")
const KotorIndoorMapIO := preload("./kotor_indoor_map_io.gd")

const CORE_BUILDERS := {
	"lyt": "lyt",
	"ifo": "ifo",
	"vis": "vis",
	"are": "are",
	"git": "git",
}


static func build_from_document(document: KotorIndoorDocument, kit_library: RefCounted = null) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}

	var manifest := KotorIndoorBuildManifest.build(document, kit_library)
	return build_from_manifest(manifest, document, kit_library)


static func build_from_manifest(
	manifest: Dictionary,
	document: KotorIndoorDocument,
	kit_library: RefCounted = null
) -> Dictionary:
	if document == null:
		return {"ok": false, "errors": ["No indoor document."]}
	if manifest.is_empty():
		return {"ok": false, "errors": ["No build manifest."]}
	if not manifest.get("ok", false):
		return {
			"ok": false,
			"errors": manifest.get("errors", []),
			"warnings": manifest.get("warnings", []),
		}

	var errors: Array[String] = []
	for builder_key in CORE_BUILDERS.keys():
		var built: Dictionary = manifest.get(builder_key, {})
		if not built.get("ok", false):
			for error_text in built.get("errors", []):
				errors.append("%s: %s" % [builder_key.to_upper(), str(error_text)])
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "warnings": manifest.get("warnings", [])}

	var module_id := str(manifest.get("module_id", ""))
	var warnings: Array = manifest.get("warnings", []).duplicate()
	var entries := _build_entries(manifest, document, kit_library, warnings)
	if entries.is_empty():
		return {"ok": false, "errors": ["No MOD entries could be assembled."]}

	var bytes := ERFWriter.build("MOD ", entries)
	if bytes.is_empty():
		return {"ok": false, "errors": ["Failed to serialize MOD archive."]}

	return {
		"ok": true,
		"bytes": bytes,
		"module_id": module_id,
		"entry_count": entries.size(),
		"warnings": warnings,
	}


static func write_to_path(document: KotorIndoorDocument, output_path: String, kit_library: RefCounted = null) -> Dictionary:
	var built := build_from_document(document, kit_library)
	if not built.get("ok", false):
		return built
	var target_path := _ensure_mod_extension(output_path)
	var err := ERFWriter.save_bytes(built.get("bytes", PackedByteArray()), target_path)
	if err != OK:
		return {
			"ok": false,
			"errors": ["Failed to write MOD preview: %s" % target_path],
			"warnings": built.get("warnings", []),
		}
	built["output_path"] = target_path
	return built


static func _build_entries(
	manifest: Dictionary,
	document: KotorIndoorDocument,
	kit_library: RefCounted,
	warnings: Array
) -> Array:
	var entries: Array = []
	var module_id := str(manifest.get("module_id", ""))
	for builder_key in CORE_BUILDERS.keys():
		var extension := String(CORE_BUILDERS[builder_key])
		var built: Dictionary = manifest.get(builder_key, {})
		entries.append({
			"resref": module_id,
			"extension": extension,
			"bytes": built.get("bytes", PackedByteArray()),
		})
	_append_room_asset_entries(document, kit_library, entries, warnings)
	return entries


static func _append_room_asset_entries(
	document: KotorIndoorDocument,
	kit_library: RefCounted,
	entries: Array,
	warnings: Array
) -> void:
	if kit_library == null:
		kit_library = document.get_kit_library()
	var kits_path := ""
	if kit_library != null and kit_library.has_method("get_kits_path"):
		kits_path = str(kit_library.call("get_kits_path")).strip_edges()

	var seen := {}
	for index in document.get_room_count():
		var room := document.get_room_dictionary(index)
		var kit_id := str(room.get("kit", "")).strip_edges()
		var component_id := str(room.get("component", "")).strip_edges()
		if component_id.is_empty():
			continue
		if kit_id == KotorIndoorMapIO.EMBEDDED_KIT_ID:
			var embedded_key := "embedded:%s" % component_id
			if not seen.has(embedded_key):
				seen[embedded_key] = true
				warnings.append(
					"Room %d uses embedded component '%s'; native MOD omits on-disk MDL/WOK."
					% [index, component_id]
				)
			continue
		if kits_path.is_empty():
			warnings.append("Room %d kit assets skipped; kits path is not configured." % index)
			continue
		var kit_dir := kits_path.path_join(kit_id)
		for extension in ["wok", "mdl", "mdx"]:
			var asset_key := "%s.%s" % [component_id, extension]
			if seen.has(asset_key):
				continue
			var asset_path := kit_dir.path_join("%s.%s" % [component_id, extension])
			if not FileAccess.file_exists(asset_path):
				continue
			var file := FileAccess.open(asset_path, FileAccess.READ)
			if file == null:
				warnings.append("Failed to read kit asset: %s" % asset_path)
				continue
			seen[asset_key] = true
			entries.append({
				"resref": component_id,
				"extension": extension,
				"bytes": file.get_buffer(file.get_length()),
			})


static func list_entry_names(parsed: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for entry in parsed.get("entries", []):
		if entry is ERFParser.ERFEntry:
			var erf_entry: ERFParser.ERFEntry = entry
			names.append("%s.%s" % [erf_entry.resref, erf_entry.extension])
	names.sort()
	return names


static func _ensure_mod_extension(path: String) -> String:
	if path.get_extension().to_lower() == "mod":
		return path
	if path.get_extension().is_empty():
		return "%s.mod" % path
	return path.get_basename() + ".mod"
