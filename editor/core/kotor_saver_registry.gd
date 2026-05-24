@tool
extends RefCounted

const TwodaResourceFormatSaver := preload("../../savers/twoda_resource_format_saver.gd")
const TlkResourceFormatSaver := preload("../../savers/tlk_resource_format_saver.gd")
const GffResourceFormatSaver := preload("../../savers/gff_resource_format_saver.gd")

var _savers: Array[ResourceFormatSaver] = []


func register_all() -> void:
	unregister_all()
	_savers = [
		TwodaResourceFormatSaver.new(),
		TlkResourceFormatSaver.new(),
		GffResourceFormatSaver.new(),
	]
	for saver in _savers:
		ResourceSaver.add_resource_format_saver(saver, true)


func unregister_all() -> void:
	for saver in _savers:
		if saver != null:
			ResourceSaver.remove_resource_format_saver(saver)
	_savers.clear()
