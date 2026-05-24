@tool
extends SceneTree

const KotorDLGWorkspaceEditor := preload("../../ui/workspace/editors/dlg_workspace_editor.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const DLGResource := preload("../../resources/typed/dlg_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")

var _editor: KotorDLGWorkspaceEditor
var _editor_state: KotorEditorState
var _resource: DLGResource
var _install_root := ""
var _saved_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://dlg_workspace_editor_test_install")
	_saved_path = _install_root.path_join("test_dialogue.dlg")
	DirAccess.make_dir_recursive_absolute(_install_root)
	_editor_state = KotorEditorState.new()
	_editor_state.game_path = _install_root
	_editor_state.refresh_gamefs()
	_editor = KotorDLGWorkspaceEditor.new()
	_editor._skip_preflight_for_testing = true
	_editor.setup(_editor_state)
	root.add_child(_editor)
	call_deferred("_assert_editor_behavior")


func _assert_editor_behavior() -> void:
	_resource = _build_dialogue_resource()
	_editor.open_resource(_resource, "", "test_dialogue.dlg")
	assert(_editor.has_document())
	assert(_editor.get_document().get_entry_count() == 1)
	assert(_editor.get_validation_text().contains("Dialogue validation passed."))

	var entry := _editor.get_document().get_node("entry", 0)
	assert(_editor.get_document().set_struct_locstring_text(entry, "Text", "Updated entry text"))
	assert(_editor.is_document_dirty())
	assert(_editor.get_validation_text().contains("Dialogue validation passed."))

	var save_result := _editor.save_document_to_path(_saved_path)
	assert(save_result.get("ok", false))
	assert(FileAccess.file_exists(_saved_path))
	assert(not _editor.is_document_dirty())

	var install_result := _editor.install_document_to_override()
	assert(install_result.get("ok", false))
	assert(FileAccess.file_exists(_install_root.path_join("override").path_join("test_dialogue.dlg")))

	_cleanup()
	quit()


func _build_dialogue_resource() -> DLGResource:
	var resource := DLGResource.new()
	resource.setup_from_parser_result({
		"file_type": "DLG",
		"root": {
			"Tag": "workspace_test",
			"StartingList": [
				{"Index": 0},
			],
			"EntryList": [
				{
					"Text": {
						"strref": 0xFFFFFFFF,
						"strings": {0: "Hello there."},
					},
					"RepliesList": [
						{
							"Index": 0,
							"Comment": "Go to reply 0",
						},
					],
				},
			],
			"ReplyList": [
				{
					"Text": {
						"strref": 0xFFFFFFFF,
						"strings": {0: "General Kenobi."},
					},
					"EntriesList": [],
				},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{
					"name": "Tag",
					"type": GFFParser.FIELD_CEXOSTRING,
				},
				{
					"name": "StartingList",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{
									"name": "Index",
									"type": GFFParser.FIELD_INT,
								},
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
								{
									"name": "Text",
									"type": GFFParser.FIELD_CEXOLOCSTR,
								},
								{
									"name": "RepliesList",
									"type": GFFParser.FIELD_LIST,
									"items": [
										{
											"struct_type": 0,
											"fields": [
												{
													"name": "Index",
													"type": GFFParser.FIELD_INT,
												},
												{
													"name": "Comment",
													"type": GFFParser.FIELD_CEXOSTRING,
												},
											],
										},
									],
								},
							],
						},
					],
				},
				{
					"name": "ReplyList",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{
									"name": "Text",
									"type": GFFParser.FIELD_CEXOLOCSTR,
								},
								{
									"name": "EntriesList",
									"type": GFFParser.FIELD_LIST,
									"items": [],
								},
							],
						},
					],
				},
			],
		},
	})
	return resource


func _cleanup() -> void:
	if _editor != null:
		_editor.open_resource(null)
		root.remove_child(_editor)
		_editor.free()
		_editor = null
	_resource = null
	_editor_state = null
	var override_path := _install_root.path_join("override").path_join("test_dialogue.dlg")
	if FileAccess.file_exists(override_path):
		DirAccess.remove_absolute(override_path)
	var override_dir := _install_root.path_join("override")
	if DirAccess.dir_exists_absolute(override_dir):
		DirAccess.remove_absolute(override_dir)
	if FileAccess.file_exists(_saved_path):
		DirAccess.remove_absolute(_saved_path)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
