## Decode embedded `.indoor` component base64 assets for native MOD assembly.
class_name KotorIndoorEmbeddedAssetGenerator

const BWMParser := preload("../../formats/bwm_parser.gd")

const FIELD_EXTENSIONS := {
	"bwm": "wok",
	"mdl": "mdl",
	"mdx": "mdx",
}


static func decode_base64_field(encoded: String) -> PackedByteArray:
	var trimmed := encoded.strip_edges()
	if trimmed.is_empty():
		return PackedByteArray()
	return Marshalls.base64_to_raw(trimmed)


static func asset_flags(component: Dictionary) -> Dictionary:
	var flags := {
		"has_wok": false,
		"has_mdl": false,
		"has_mdx": false,
	}
	for field in FIELD_EXTENSIONS.keys():
		var bytes := decode_base64_field(str(component.get(field, "")))
		if bytes.is_empty():
			continue
		if field == "bwm":
			flags["has_wok"] = not BWMParser.parse_bytes(bytes).is_empty()
		elif field == "mdl":
			flags["has_mdl"] = true
		elif field == "mdx":
			flags["has_mdx"] = true
	return flags


static func list_entries(component_id: String, component: Dictionary, warnings: Array = []) -> Array:
	var resref := component_id.strip_edges()
	if resref.is_empty():
		return []

	var entries: Array = []
	for field in FIELD_EXTENSIONS.keys():
		var extension: String = FIELD_EXTENSIONS[field]
		var bytes := decode_base64_field(str(component.get(field, "")))
		if bytes.is_empty():
			continue
		if field == "bwm" and BWMParser.parse_bytes(bytes).is_empty():
			warnings.append(
				"Embedded component '%s' has invalid BWM payload; skipping .wok entry." % resref
			)
			continue
		entries.append({
			"resref": resref,
			"extension": extension,
			"bytes": bytes,
		})
	return entries
