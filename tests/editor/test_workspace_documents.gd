@tool
extends SceneTree

const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWorkspaceSession := preload("../../editor/workspace/kotor_workspace_session.gd")
const DLGResource := preload("../../resources/typed/dlg_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")

var _install_root := ""
var _path_one := ""
var _path_two := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://workspace_documents_test_install")
	_path_one = _install_root.path_join("dialogue_one.dlg")
	_path_two = _install_root.path_join("dialogue_two.dlg")
	DirAccess.make_dir_recursive_absolute(_install_root)
	call_deferred("_assert_workspace_documents")


func _assert_workspace_documents() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(state)

	var resource_one := _build_dialogue_resource("one", "Hello")
	var resource_two := _build_dialogue_resource("two", "Goodbye")
	var document_one = resource_one.create_document()
	var document_two = resource_two.create_document()

	var entry_one: Dictionary = controller.register_document("dlg", resource_one, document_one, _path_one, "dialogue_one.dlg")
	var entry_two: Dictionary = controller.register_document("dlg", resource_two, document_two, _path_two, "dialogue_two.dlg")
	assert(controller.document_registry.list_documents().size() == 2)
	assert(controller.activate_document(str(entry_one.get("key", "")), true).get("ok", false))

	controller.update_document_dirty(str(entry_one.get("key", "")), true)
	assert(controller.document_registry.get_document_entry(str(entry_one.get("key", ""))).get("dirty", false))
	assert(not controller.document_registry.get_document_entry(str(entry_two.get("key", ""))).get("dirty", false))

	var blocked_switch: Dictionary = controller.activate_document(str(entry_two.get("key", "")))
	assert(blocked_switch.get("blocked", false))
	assert((blocked_switch.get("actions", []) as Array).has("discard"))

	controller.update_document_selection(str(entry_one.get("key", "")), {"kind": "entry", "index": 0})
	controller.persist_session()

	var restored_controller := KotorWorkspaceController.new(state)
	var restored_state: Dictionary = restored_controller.restore_workspace_session()
	assert((restored_state.get("documents", []) as Array).size() == 2)
	assert(str(restored_state.get("active_key", "")) == str(entry_one.get("key", "")))

	state.refresh_gamefs()
	assert(controller.document_registry.get_document_entry(str(entry_one.get("key", ""))).get("stale", false))

	DirAccess.remove_absolute(_path_two)
	var session := KotorWorkspaceSession.new()
	session.save_registry(controller.document_registry)
	var missing_state := session.load_state()
	var missing_documents: Array = missing_state.get("documents", [])
	var saw_missing := false
	for value in missing_documents:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var document_entry: Dictionary = value
		if str(document_entry.get("source_path", "")) == _path_two:
			saw_missing = bool(document_entry.get("missing_source", false))
	assert(saw_missing)
	session.clear_state()

	_cleanup()
	quit()


func _build_dialogue_resource(tag: String, text: String) -> DLGResource:
	var resource := DLGResource.new()
	resource.setup_from_parser_result({
		"file_type": "DLG",
		"root": {
			"Tag": "workspace_%s" % tag,
			"StartingList": [
				{"Index": 0},
			],
			"EntryList": [
				{
					"Text": {
						"strref": 0xFFFFFFFF,
						"strings": {0: text},
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
	var session := KotorWorkspaceSession.new()
	session.clear_state()
	if FileAccess.file_exists(_path_one):
		DirAccess.remove_absolute(_path_one)
	if FileAccess.file_exists(_path_two):
		DirAccess.remove_absolute(_path_two)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
