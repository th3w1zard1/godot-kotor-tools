@tool
extends ResourceFormatSaver

const GFFResource := preload("../resources/gff_resource.gd")
const GFFWriter := preload("../formats/gff_writer.gd")

const EXTENSIONS := PackedStringArray([
	"are", "dlg", "gff", "git", "ifo", "jrl",
	"utc", "utd", "ute", "uti", "utm", "utp", "uts", "utt", "utw",
])


func _recognize(resource: Resource) -> bool:
	return resource is GFFResource


func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	if not _recognize(resource):
		return PackedStringArray()
	return EXTENSIONS


func _save(resource: Resource, path: String, _flags: int) -> Error:
	if not _recognize(resource):
		return ERR_INVALID_PARAMETER
	return GFFWriter.save_resource(resource as GFFResource, path)
