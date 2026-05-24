@tool
extends ResourceFormatSaver

const TwoDaResource := preload("../resources/twoda_resource.gd")
const TwoDaWriter := preload("../formats/twoda_writer.gd")


func _recognize(resource: Resource) -> bool:
	return resource is TwoDaResource


func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	if not _recognize(resource):
		return PackedStringArray()
	return PackedStringArray(["2da"])


func _save(resource: Resource, path: String, _flags: int) -> Error:
	if not _recognize(resource):
		return ERR_INVALID_PARAMETER
	return TwoDaWriter.save_resource(resource as TwoDaResource, path)
