@tool
extends RefCounted
class_name GFFResourceFactory

const GFFResource := preload("./gff_resource.gd")
const UTCResource := preload("./typed/utc_resource.gd")
const UTPResource := preload("./typed/utp_resource.gd")
const DLGResource := preload("./typed/dlg_resource.gd")
const AREResource := preload("./typed/are_resource.gd")
const GITResource := preload("./typed/git_resource.gd")
const IFOResource := preload("./typed/ifo_resource.gd")

const RESOURCE_TYPES := {
	"ARE": AREResource,
	"DLG": DLGResource,
	"GIT": GITResource,
	"IFO": IFOResource,
	"UTC": UTCResource,
	"UTP": UTPResource,
}


static func create_from_parser_result(parsed: Dictionary) -> GFFResource:
	var file_type := String(parsed.get("file_type", "")).strip_edges().to_upper()
	var script = RESOURCE_TYPES.get(file_type, GFFResource)
	var resource: GFFResource = script.new()
	resource.setup_from_parser_result(parsed)
	return resource
