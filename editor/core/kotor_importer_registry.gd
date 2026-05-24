@tool
extends RefCounted

const GffImportPlugin := preload("../../importers/gff_import_plugin.gd")
const ErfImportPlugin := preload("../../importers/erf_import_plugin.gd")
const TwodaImportPlugin := preload("../../importers/twoda_import_plugin.gd")
const TpcImportPlugin := preload("../../importers/tpc_import_plugin.gd")
const TLK_IMPORT_PLUGIN_PATH := "res://addons/kotor_tools/importers/tlk_import_plugin.gd"

var _importers: Array[EditorImportPlugin] = []


func register_all(plugin: EditorPlugin) -> bool:
	unregister_all(plugin)

	var tlk_importer_script := load(TLK_IMPORT_PLUGIN_PATH)
	if tlk_importer_script == null:
		push_error("KotOR Tools: failed to load TLK importer at %s" % TLK_IMPORT_PLUGIN_PATH)
		return false

	_importers = [
		GffImportPlugin.new(),
		ErfImportPlugin.new(),
		TwodaImportPlugin.new(),
		tlk_importer_script.new(),
		TpcImportPlugin.new(),
	]

	for importer in _importers:
		plugin.add_import_plugin(importer)
	return true


func unregister_all(plugin: EditorPlugin) -> void:
	for importer in _importers:
		if importer != null:
			plugin.remove_import_plugin(importer)
	_importers.clear()
