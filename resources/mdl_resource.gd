## resources/mdl_resource.gd
## Typed KotOR MDL document for write-back foundations.
@tool
extends Resource
class_name MdlResource

const MDLParser := preload("../formats/mdl_parser.gd")
const MDLWriter := preload("../formats/mdl_writer.gd")

@export var mdl_bytes: PackedByteArray = PackedByteArray()
@export var mdx_bytes: PackedByteArray = PackedByteArray()
@export var model_name: String = ""
@export var vertex_count: int = 0
@export var face_count: int = 0


static func from_bytes(
	mdl_data: PackedByteArray,
	mdx_data: PackedByteArray = PackedByteArray()
) -> MdlResource:
	var resource: MdlResource = load("res://resources/mdl_resource.gd").new()
	if not resource.setup_from_bytes(mdl_data, mdx_data):
		return null
	return resource


func setup_from_bytes(mdl_data: PackedByteArray, mdx_data: PackedByteArray = PackedByteArray()) -> bool:
	if mdl_data.is_empty():
		return false
	var parsed := MDLParser.parse_bytes(mdl_data, mdx_data)
	if parsed.is_empty():
		return false
	mdl_bytes = mdl_data.duplicate()
	mdx_bytes = mdx_data.duplicate()
	model_name = str(parsed.get("model_name", ""))
	vertex_count = int(parsed.get("vertex_count", 0))
	face_count = int(parsed.get("face_count", 0))
	return true


func is_valid() -> bool:
	return not mdl_bytes.is_empty() and vertex_count > 0 and face_count > 0


func has_mdx() -> bool:
	return not mdx_bytes.is_empty()


func serialize_mdl() -> PackedByteArray:
	return MDLWriter.serialize_passthrough(mdl_bytes, mdx_bytes)


func serialize_mdx() -> PackedByteArray:
	return MDLWriter.serialize_mdx_passthrough(mdx_bytes)


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	if not model_name.is_empty():
		lines.append("Model: %s" % model_name)
	lines.append("Vertices: %d" % vertex_count)
	lines.append("Faces: %d" % face_count)
	lines.append("MDL size: %d bytes" % mdl_bytes.size())
	if has_mdx():
		lines.append("MDX size: %d bytes" % mdx_bytes.size())
	else:
		lines.append("MDX: not loaded")
	return lines
