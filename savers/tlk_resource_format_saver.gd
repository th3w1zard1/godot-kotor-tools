@tool
extends ResourceFormatSaver

const TLKResource := preload("../resources/tlk_resource.gd")
const TLKWriter := preload("../formats/tlk_writer.gd")


func _recognize(resource: Resource) -> bool:
	return resource is TLKResource


func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	if not _recognize(resource):
		return PackedStringArray()
	return PackedStringArray(["tlk"])


func _save(resource: Resource, path: String, _flags: int) -> Error:
	if not _recognize(resource):
		return ERR_INVALID_PARAMETER
	return TLKWriter.save_resource(resource as TLKResource, path)
