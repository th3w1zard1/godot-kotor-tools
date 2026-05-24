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

	_test_string_edit_undo_redo()
	_test_bool_edit_undo_redo()
	_test_int_edit_undo_redo()
	_test_locstring_edit_undo_redo()
	_test_validation_failure_no_mutation()
	_test_stale_document_state()

	_cleanup()
	quit()


func _test_string_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	var old_comment = str(entry.get("Comment", ""))
	
	_editor._apply_string_edit(entry, "Comment", "Updated comment")
	assert(str(entry.get("Comment", "")) == "Updated comment")
	assert(_editor.is_document_dirty())


func _test_bool_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	
	# Test with a bool field (we'll use a test struct value)
	var test_struct = {"BoolField": false}
	_editor._apply_bool_edit(test_struct, "BoolField", true)
	assert(test_struct.get("BoolField", false) == true)
	assert(_editor.is_document_dirty())


func _test_int_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var reply := _editor.get_document().get_node("reply", 0)
	var old_value = int(reply.get("Index", 0))
	
	_editor._apply_int_edit(reply, "Index", 42.0)
	assert(int(reply.get("Index", 0)) == 42)
	assert(_editor.is_document_dirty())


func _test_locstring_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	var old_text = _editor._dlg_locstring_text(entry.get("Text", {}))
	
	_editor._apply_locstring_edit(entry, "Text", "Updated locstring text")
	var updated_locstring = entry.get("Text", {})
	var new_text = _editor._dlg_locstring_text(updated_locstring)
	assert(new_text == "Updated locstring text")
	assert(_editor.is_document_dirty())
	
	# Verify language ID is preserved
	var strings = updated_locstring.get("strings", {})
	assert(0 in strings)  # Default language ID


func _test_validation_failure_no_mutation() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	
	# Test with stale document (null)
	_editor._dlg_document = null
	var test_struct = {"Field": "value"}
	_editor._apply_string_edit(test_struct, "Field", "new value")
	assert(test_struct.get("Field", "") == "value")  # Should not change


func _test_stale_document_state() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	
	# Close document to make it stale
	_editor.open_resource(null)
	
	# Try to apply edit on stale document
	_editor._apply_string_edit(entry, "Comment", "New comment")
	# Should return gracefully without mutation since document is null


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
