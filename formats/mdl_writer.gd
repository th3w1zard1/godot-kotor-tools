## formats/mdl_writer.gd
## KotOR MDL write-back — passthrough serialization for phase 0 foundations.
##
## Validates MDL trimesh parse before accepting passthrough bytes.
@tool
class_name MDLWriter

const MDLParser := preload("./mdl_parser.gd")
const MdlResource := preload("../resources/mdl_resource.gd")


## Return byte-identical MDL when input parses as K1 trimesh geometry.
static func serialize_passthrough(
	mdl_bytes: PackedByteArray,
	mdx_bytes: PackedByteArray = PackedByteArray()
) -> PackedByteArray:
	if mdl_bytes.is_empty():
		push_error("MDLWriter: MDL payload is empty")
		return PackedByteArray()
	var parsed := MDLParser.parse_bytes(mdl_bytes, mdx_bytes)
	if parsed.is_empty():
		push_error("MDLWriter: passthrough rejected unparsable MDL")
		return PackedByteArray()
	return mdl_bytes.duplicate()


## Return byte-identical MDX bytes (empty MDX is valid for some models).
static func serialize_mdx_passthrough(mdx_bytes: PackedByteArray) -> PackedByteArray:
	return mdx_bytes.duplicate()


## Serialize a typed MDL resource to export/install bytes.
static func serialize_resource(resource: Resource) -> Dictionary:
	if resource == null or not resource is MdlResource:
		push_error("MDLWriter: resource is not an MdlResource")
		return {}
	var mdl_resource := resource as MdlResource
	var mdl_bytes := serialize_passthrough(mdl_resource.mdl_bytes, mdl_resource.mdx_bytes)
	if mdl_bytes.is_empty():
		return {}
	return {
		"mdl": mdl_bytes,
		"mdx": serialize_mdx_passthrough(mdl_resource.mdx_bytes),
	}
