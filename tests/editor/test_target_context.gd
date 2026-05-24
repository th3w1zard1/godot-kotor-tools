@tool
extends SceneTree

const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorTargetContext := preload("../../editor/workspace/kotor_target_context.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")
const KotorResourceLocator := preload("../../editor/navigation/kotor_resource_locator.gd")
const KotorWorkspaceSession := preload("../../editor/workspace/kotor_workspace_session.gd")
const DLGResource := preload("../../resources/typed/dlg_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")

var _install_one := ""
var _install_two := ""


func _initialize() -> void:
	_install_one = ProjectSettings.globalize_path("user://target_context_install_one")
	_install_two = ProjectSettings.globalize_path("user://target_context_install_two")
	DirAccess.make_dir_recursive_absolute(_install_one.path_join("override"))
	DirAccess.make_dir_recursive_absolute(_install_two.path_join("override"))
	_write_dialogue(_install_one.path_join("override").path_join("target_one.dlg"), "target_one")
	_write_dialogue(_install_two.path_join("override").path_join("target_two.dlg"), "target_two")
	call_deferred("_assert_target_context")


func _assert_target_context() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_one
	state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(state)
	var target_context := KotorTargetContext.new().setup(state, controller)

	var entries: Array[Dictionary] = target_context.list_resources("target_one")
	assert(entries.size() == 1)
	var entry: Dictionary = entries[0]
	assert(str(entry.get("source", "")) == "override")
	assert(KotorResourceLocator.build_entry_details(entry, target_context.list_variants(entry)).contains("Primary source: Override"))
	assert(not target_context.load_entry_bytes(entry).is_empty())

	var switch_result: Dictionary = target_context.switch_target(_install_two)
	assert(switch_result.get("ok", false))
	assert(target_context.list_resources("target_two").size() == 1)

	var resource := _build_dialogue_resource("dirty_target")
	var document = resource.create_document()
	var registry_entry: Dictionary = controller.register_document("dlg", resource, document, _install_two.path_join("override").path_join("dirty_target.dlg"), "dirty_target.dlg")
	controller.activate_document(str(registry_entry.get("key", "")), true)
	controller.update_document_dirty(str(registry_entry.get("key", "")), true)
	var blocked: Dictionary = target_context.switch_target(_install_one)
	assert(blocked.get("blocked", false))
	assert((blocked.get("actions", []) as Array).has("cancel"))

	var session := KotorWorkspaceSession.new()
	session.clear_state()
	_cleanup()
	quit()


func _write_dialogue(path: String, tag: String) -> void:
	var pipeline := KotorModdingPipeline.new()
	var result: Dictionary = pipeline.export_payload_to_path(path, _build_dialogue_resource(tag), path.get_file())
	assert(result.get("ok", false))


func _build_dialogue_resource(tag: String) -> DLGResource:
	var resource := DLGResource.new()
	resource.setup_from_parser_result({
		"file_type": "DLG",
		"root": {
			"Tag": tag,
			"StartingList": [
				{"Index": 0},
			],
			"EntryList": [
				{
					"Text": {
						"strref": 0xFFFFFFFF,
						"strings": {0: tag},
					},
					"RepliesList": [],
				},
			],
			"ReplyList": [],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
				{
					"name": "StartingList",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{"name": "Index", "type": GFFParser.FIELD_INT},
							],
						},
					],
				},
				{
					"name": "EntryList",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{"name": "Text", "type": GFFParser.FIELD_CEXOLOCSTR},
								{"name": "RepliesList", "type": GFFParser.FIELD_LIST, "items": []},
							],
						},
					],
				},
				{
					"name": "ReplyList",
					"type": GFFParser.FIELD_LIST,
					"items": [],
				},
			],
		},
	})
	return resource


func _cleanup() -> void:
	var paths := [
		_install_one.path_join("override").path_join("target_one.dlg"),
		_install_two.path_join("override").path_join("target_two.dlg"),
	]
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for directory in [
		_install_one.path_join("override"),
		_install_two.path_join("override"),
		_install_one,
		_install_two,
	]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
