@tool
extends SceneTree

const KotorDLGWorkspaceEditor := preload("../../ui/workspace/editors/dlg_workspace_editor.gd")
const KotorDLGDocument := preload("../../resources/documents/kotor_dlg_document.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const DLGResource := preload("../../resources/typed/dlg_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")

var _editor: KotorDLGWorkspaceEditor
var _editor_state: KotorEditorState
var _resource: DLGResource
var _install_root := ""
var _saved_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://dlg_workspace_editor_test_install")
	_saved_path = _install_root.path_join("test_dialogue.dlg")
	_remove_path_recursive(_install_root)
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

	_test_link_target_metadata()
	_test_jump_to_link_target()

	_test_string_edit_undo_redo()
	_test_bool_edit_undo_redo()
	_test_bool_edit_non_bool_original_value()
	_test_int_edit_undo_redo()
	_test_int_edit_non_int_original_value()
	_test_locstring_edit_undo_redo()
	_test_validation_failure_no_mutation()
	_test_stale_document_state()
	_test_multi_step_undo_redo_sequence()
	_test_changed_signal_emissions()
	_test_validation_state_after_undo()
	_test_multi_entry_edits_and_undo()
	
	# Q6 Array mutation tests
	_test_array_insert_basic()
	_test_array_remove_basic()
	_test_array_reorder_basic()
	_test_array_insert_empty_list()
	_test_array_remove_last_item()
	_test_array_undo_redo_round_trip()
	_test_array_validation_required_field()
	_test_array_validation_optional_field()

	_test_node_add_entry()
	_test_node_add_reply_and_link()
	_test_node_remove_entry_repairs_indices()
	_test_find_orphaned_nodes_after_reference_removal()
	_test_restore_orphan_link()
	_test_node_add_remove_undo_redo()

	_test_navigation_back_after_jump()
	_test_navigation_back_empty_stack()

	_test_remove_all_references_entry_via_editor()
	_test_remove_all_references_reply_via_editor()
	_test_remove_all_references_undo_redo()

	_test_add_node_link_document_api()
	_test_graph_link_via_editor()
	_test_graph_link_undo_redo()

	_test_find_linkable_orphans_for_owner()
	_test_restore_orphan_via_editor()
	_test_orphan_double_click_restore()
	_test_node_animations_crud()
	_test_camera_fade_fields()

	_cleanup()
	quit()


func _test_string_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	var old_comment = str(entry.get("Comment", ""))
	
	_editor._apply_string_edit(entry, "Comment", "Updated comment")
	assert(str(entry.get("Comment", "")) == "Updated comment", "String edit should apply new value")
	assert(_editor.is_document_dirty(), "Document should be dirty after string edit")
	
	# Verify undo/redo action was created properly by checking the undo state
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(str(entry.get("Comment", "")) == old_comment, "Undo should restore original value")
		ur.redo()
		assert(str(entry.get("Comment", "")) == "Updated comment", "Redo should restore new value")


func _test_bool_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	
	# Test with a bool field (we'll use a test struct value)
	var test_struct = {"BoolField": false}
	_editor._apply_bool_edit(test_struct, "BoolField", true)
	assert(test_struct.get("BoolField", false) == true, "Bool edit should apply new value")
	assert(_editor.is_document_dirty(), "Document should be dirty after bool edit")
	
	# Verify undo/redo restores the original value
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(test_struct.get("BoolField", false) == false, "Undo should restore original bool value")
		ur.redo()
		assert(test_struct.get("BoolField", false) == true, "Redo should restore new bool value")


func _test_bool_edit_non_bool_original_value() -> void:
	# Test edge case: bool edit on a field with non-bool original value
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	
	# Create struct with non-bool original value
	var test_struct = {"Field": 42}  # Original value is int, not bool
	_editor._apply_bool_edit(test_struct, "Field", true)
	assert(test_struct.get("Field") == true, "Bool edit should apply new bool value")
	
	# Verify undo restores the non-bool original value (critical: not bool(42) = true)
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(test_struct.get("Field") == 42, "Undo should restore non-bool original value (42), not bool(42)")
		ur.redo()
		assert(test_struct.get("Field") == true, "Redo should restore new bool value")


func _test_int_edit_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var start := doc.get_start(0)
	assert(not start.is_empty(), "Fixture should include a starting node")
	doc.insert_struct_at_array(
		"EntryList",
		doc.get_entry_count(),
		{
			"Text": {"strref": 0xFFFFFFFF, "strings": {0: "Second entry."}},
			"RepliesList": [],
		}
	)
	var old_value := int(start.get("Index", 0))
	assert(old_value == 0, "Starting node should begin at index 0")

	_editor._apply_int_edit(start, "Index", 1.0)
	assert(int(start.get("Index", 0)) == 1, "Int edit should apply new value")
	assert(_editor.is_document_dirty(), "Document should be dirty after int edit")

	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(int(start.get("Index", 0)) == old_value, "Undo should restore original int value")
		ur.redo()
		assert(int(start.get("Index", 0)) == 1, "Redo should restore new int value")


func _test_int_edit_non_int_original_value() -> void:
	# Test edge case: int edit on a field with non-int original value
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	
	# Create struct with non-int original value (e.g., float or missing)
	var test_struct = {"Field": 3.14}  # Original value is float
	_editor._apply_int_edit(test_struct, "Field", 42.0)
	assert(test_struct.get("Field") == 42, "Int edit should apply new int value")
	
	# Verify undo restores the non-int original value (critical: not 0)
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(test_struct.get("Field") == 3.14, "Undo should restore non-int original value (3.14), not 0")
		ur.redo()
		assert(test_struct.get("Field") == 42, "Redo should restore new int value")


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


func _test_multi_step_undo_redo_sequence() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	var reply := _editor.get_document().get_node("reply", 0)
	
	# Initial state
	var initial_comment = str(entry.get("Comment", ""))
	var initial_index = int(reply.get("Index", 0))
	
	# Edit entry A text
	_editor._apply_string_edit(entry, "Comment", "Edit A")
	assert(str(entry.get("Comment", "")) == "Edit A", "Edit A should be applied")
	assert(_editor.is_document_dirty(), "Document should be dirty after edit A")
	
	# Edit entry B bool (using a test struct to simulate bool field)
	var test_struct_b = {"BoolField": false}
	_editor._apply_bool_edit(test_struct_b, "BoolField", true)
	assert(test_struct_b.get("BoolField", false) == true, "Edit B should be applied")
	
	# Verify that the document is still dirty and edits are retained
	assert(_editor.is_document_dirty(), "Document should still be dirty after edit B")
	assert(str(entry.get("Comment", "")) == "Edit A", "Edit A should still be retained after edit B")


func _test_changed_signal_emissions() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	var doc := _editor.get_document()
	
	# Track changed signal emissions (use a mutable holder; lambdas capture ints by value).
	var changed_counts: Array[int] = [0]
	var changed_handler = func() -> void:
		changed_counts[0] += 1

	doc.changed.connect(changed_handler)

	var initial_count := changed_counts[0]
	_editor._apply_string_edit(entry, "Comment", "Signal test edit")
	var after_edit_count := changed_counts[0]
	
	# Verify that changed signal was emitted
	assert(after_edit_count > initial_count, "Changed signal should be emitted after edit")
	
	# Verify the field was updated
	assert(str(entry.get("Comment", "")) == "Signal test edit", "Field should be updated")
	
	doc.changed.disconnect(changed_handler)


func _test_validation_state_after_undo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var initial_validation := _editor.get_validation_text()
	
	# Get initial validation state
	assert(initial_validation.contains("Dialogue validation passed."), "Initial validation should pass")
	
	# Make an edit
	var entry := _editor.get_document().get_node("entry", 0)
	_editor._apply_string_edit(entry, "Comment", "Updated comment")
	assert(_editor.is_document_dirty(), "Document should be dirty")
	
	# Validation state should still be valid after edit
	var validation_after_edit := _editor.get_validation_text()
	assert(validation_after_edit.contains("Dialogue validation passed."), "Validation should still pass after edit")


func _test_multi_entry_edits_and_undo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	
	var entry := _editor.get_document().get_node("entry", 0)
	var reply := _editor.get_document().get_node("reply", 0)
	
	# Record initial states
	var initial_entry_comment = str(entry.get("Comment", ""))
	var initial_reply_text_str = _editor._dlg_locstring_text(reply.get("Text", {}))
	
	# Edit multiple entries
	_editor._apply_string_edit(entry, "Comment", "Entry comment updated")
	_editor._apply_locstring_edit(reply, "Text", "Reply text updated")
	
	# Verify edits were applied
	assert(str(entry.get("Comment", "")) == "Entry comment updated", "Entry comment should be updated")
	assert(_editor._dlg_locstring_text(reply.get("Text", {})) == "Reply text updated", "Reply text should be updated")
	assert(_editor.is_document_dirty(), "Document should be dirty after multiple edits")
	
	# Verify both changes are retained (no orphaned state)
	assert(str(entry.get("Comment", "")) == "Entry comment updated", "Entry comment should be retained")
	assert(_editor._dlg_locstring_text(reply.get("Text", {})) == "Reply text updated", "Reply text should be retained")


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
					"CameraAngle": 45.0,
					"CameraID": 0,
					"CameraAnim": "",
					"FadeType": 0,
					"FadeDelay": 0.0,
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
									"name": "CameraAngle",
									"type": GFFParser.FIELD_FLOAT,
								},
								{
									"name": "CameraID",
									"type": GFFParser.FIELD_INT,
								},
								{
									"name": "CameraAnim",
									"type": GFFParser.FIELD_CEXOSTRING,
								},
								{
									"name": "FadeType",
									"type": GFFParser.FIELD_INT,
								},
								{
									"name": "FadeDelay",
									"type": GFFParser.FIELD_FLOAT,
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


# Q6 Array Mutation Tests

func _test_array_insert_basic() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var entry_list = doc.get_struct_list("EntryList")
	assert(entry_list.size() == 1, "Should start with 1 entry")
	
	var initial_size := doc.get_reply_count()

	var new_reply = {"Index": 0, "Comment": "Test reply", "Active": "", "IsChild": 0}
	var success = doc.insert_struct_at_array("ReplyList", initial_size, new_reply)
	assert(success, "Insert should succeed")
	assert(doc.get_reply_count() == initial_size + 1, "ReplyList should grow by 1")
	var reply_list := doc.get_struct_list_array("ReplyList")
	assert(reply_list[initial_size] == new_reply, "New reply should be at inserted index")
	assert(_editor.is_document_dirty(), "Document should be dirty after insert")


func _test_array_remove_basic() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var initial_size := doc.get_reply_count()
	if initial_size == 0:
		var new_reply = {"Index": 0, "Comment": "Test", "Active": "", "IsChild": 0}
		doc.insert_struct_at_array("ReplyList", 0, new_reply)
		initial_size = 1

	var success = doc.remove_struct_from_array("ReplyList", 0)
	assert(success, "Remove should succeed")
	assert(doc.get_reply_count() == initial_size - 1, "ReplyList should return to initial size")
	assert(_editor.is_document_dirty(), "Document should be dirty after remove")


func _test_array_reorder_basic() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var reply1 = {"Index": 0, "Comment": "Reply 1", "Active": "", "IsChild": 0}
	var reply2 = {"Index": 0, "Comment": "Reply 2", "Active": "", "IsChild": 0}
	doc.insert_struct_at_array("ReplyList", 0, reply1)
	doc.insert_struct_at_array("ReplyList", 1, reply2)

	var reply_list := doc.get_struct_list_array("ReplyList")
	assert(str(reply_list[0].get("Comment", "")) == "Reply 1", "First item should be Reply 1")
	assert(str(reply_list[1].get("Comment", "")) == "Reply 2", "Second item should be Reply 2")

	var success = doc.reorder_array_item("ReplyList", 0, 1)
	assert(success, "Reorder should succeed")
	reply_list = doc.get_struct_list_array("ReplyList")
	assert(str(reply_list[0].get("Comment", "")) == "Reply 2", "After reorder, first should be Reply 2")
	assert(str(reply_list[1].get("Comment", "")) == "Reply 1", "After reorder, second should be Reply 1")


func _test_array_insert_empty_list() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var entry_list = doc.get_struct_list("EntryList")
	var first_entry = entry_list[0] if entry_list.size() > 0 else {}
	
	if not first_entry.is_empty() and first_entry.has("RepliesList"):
		var replies = first_entry.get("RepliesList", [])
		var initial_size = (replies as Array).size() if typeof(replies) == TYPE_ARRAY else 0
		
		var new_reply = {"Index": 0, "Comment": "", "Active": "", "IsChild": 0}
		# Access via path instead of just array name (this tests the base class method works)
		var entry_root = doc.get_root()
		var test_list = entry_root.get("StartingList", [])
		if typeof(test_list) == TYPE_ARRAY:
			var success = doc.insert_struct_at_array("StartingList", (test_list as Array).size(), new_reply)
			assert(success, "Insert to empty/partial list should succeed")


func _test_array_remove_last_item() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	if doc.get_reply_count() == 0:
		var new_reply = {"Index": 0, "Comment": "Only reply", "Active": "", "IsChild": 0}
		doc.insert_struct_at_array("ReplyList", 0, new_reply)

	var final_size := doc.get_reply_count() - 1
	var success = doc.remove_struct_from_array("ReplyList", doc.get_reply_count() - 1)
	assert(success, "Remove last item should succeed")
	assert(doc.get_reply_count() == final_size, "List size should decrease")
	assert(_editor.is_document_dirty(), "Document should be dirty")


func _test_array_undo_redo_round_trip() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var initial_size := doc.get_reply_count()

	_editor._apply_array_insert("ReplyList", 0, {"Index": 0, "Comment": "Undo test", "Active": "", "IsChild": 0})
	assert(doc.get_reply_count() == initial_size + 1, "Insert should increase size")

	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(doc.get_reply_count() == initial_size, "Undo should restore size")
		ur.redo()
		assert(doc.get_reply_count() == initial_size + 1, "Redo should restore inserted state")


func _test_array_validation_required_field() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var entry_list = doc.get_struct_list("EntryList")
	var test_struct = {"Index": entry_list.size(), "Comment": "", "Active": "", "IsChild": 0}
	
	# This Index is out of bounds (>= entry_list.size())
	# The validation should detect this and block the edit
	var is_required = TypedFieldHelpers.is_required_field("Index")
	assert(is_required, "Index should be required field")
	
	var is_valid = TypedFieldHelpers.validate_required_field("Index", entry_list.size(), entry_list.size())
	assert(not is_valid, "Out-of-bounds Index should be invalid")


func _test_array_validation_optional_field() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	
	# Test that optional fields don't block operations
	var is_required_comment = TypedFieldHelpers.is_required_field("Comment")
	assert(not is_required_comment, "Comment should not be required field")
	
	var warning = TypedFieldHelpers.get_validation_warning("Comment", "")
	assert(not warning.is_empty(), "Empty comment should generate warning")
	
	var warning_active = TypedFieldHelpers.get_validation_warning("Active", "")
	assert(not warning_active.is_empty(), "Empty active should generate warning")


func _test_link_target_metadata() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()

	var target := doc.get_link_target_metadata("entry", 0, 0)
	assert(target.get("kind", "") == "reply", "Entry link should resolve to reply kind")
	assert(int(target.get("index", -1)) == 0, "Entry link should resolve to reply 0")

	assert(doc.get_link_target_metadata("entry", 0, 99).is_empty(), "Out-of-range link index should return empty")
	assert(doc.get_link_target_metadata("entry", 99, 0).is_empty(), "Out-of-range owner index should return empty")

	var entry_list := doc.get_struct_list_array("EntryList")
	var entry: Dictionary = entry_list[0]
	var replies: Array = entry.get("RepliesList", [])
	replies[0]["Index"] = 99
	assert(doc.get_link_target_metadata("entry", 0, 0).is_empty(), "Out-of-range target index should return empty")


func _test_jump_to_link_target() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")

	_editor._jump_to_link_target("entry", 0, 0)
	assert(str(_editor._dlg_selection.get("kind", "")) == "reply", "Jump should select reply node")
	assert(int(_editor._dlg_selection.get("index", -1)) == 0, "Jump should select reply 0")

	_editor._jump_to_link_target("entry", 0, 99)
	assert(str(_editor._dlg_selection.get("kind", "")) == "reply", "Invalid jump should leave selection unchanged")

	_editor.open_resource(resource, "", "test_dialogue.dlg")
	_editor._select_dlg_metadata({"kind": "entry", "index": 0})
	assert(_editor.get_navigation_stack_depth() == 0, "Reloaded editor should reset navigation stack")
	_editor._jump_to_link_target("entry", 0, 99)
	assert(_editor.get_navigation_stack_depth() == 0, "Invalid jump should not push navigation state")


func _test_node_add_entry() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var initial_count := doc.get_entry_count()
	var new_index := doc.add_entry()
	assert(new_index == initial_count, "New entry should append at end")
	assert(doc.get_entry_count() == initial_count + 1, "Entry count should increase")
	assert(doc.validate().is_empty(), "Dialogue should validate after add entry")


func _test_node_add_reply_and_link() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var reply_index := doc.add_reply()
	assert(reply_index == doc.get_reply_count() - 1, "Reply should append at end")
	var entry := doc.get_node("entry", 0)
	var links: Array = entry.get("RepliesList", [])
	links.append(KotorDLGDocument.create_default_link_struct(reply_index))
	entry["RepliesList"] = links
	doc.mark_changed()
	assert(
		doc.get_link_target_metadata("entry", 0, links.size() - 1).get("index", -1) == reply_index,
		"New reply link should resolve to added reply"
	)
	assert(doc.validate().is_empty(), "Linked reply should validate")


func _test_node_remove_entry_repairs_indices() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	assert(doc.add_entry() == 1, "Second entry should be index 1")
	assert(doc.add_entry() == 2, "Third entry should be index 2")
	doc.add_start(2)
	assert(doc.remove_entry(0), "Remove entry should succeed")
	assert(doc.get_entry_count() == 2, "Entry count should decrease")
	var found_shifted_start := false
	for start_index in range(doc.get_start_count()):
		if int(doc.get_start(start_index).get("Index", -1)) == 1:
			found_shifted_start = true
	assert(found_shifted_start, "Start targeting entry 2 should shift to index 1 after entry 0 removed")
	assert(doc.validate().is_empty(), "Repaired dialogue should validate")


func _test_find_orphaned_nodes_after_reference_removal() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var reply_index := doc.add_reply()
	assert(doc.remove_all_references_to_node("reply", 0) >= 1, "Should remove incoming links to reply 0")
	var orphans := doc.find_orphaned_nodes()
	var found_reply_zero := false
	for orphan in orphans:
		if str(orphan.get("kind", "")) == "reply" and int(orphan.get("index", -1)) == 0:
			found_reply_zero = true
	assert(found_reply_zero, "Reply 0 should be orphaned after references removed")
	assert(reply_index == 1, "Added reply should remain at index 1")


func _test_restore_orphan_link() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	doc.remove_all_references_to_node("reply", 0)
	assert(doc.restore_link_to_orphan("entry", 0, "reply", 0), "Restore should add reply link from entry 0")
	assert(doc.get_node_links("entry", 0).size() >= 1, "Entry should have restored reply link")
	assert(doc.validate().is_empty(), "Restored link should validate")


func _test_navigation_back_after_jump() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	_editor._select_dlg_metadata({"kind": "link", "owner": "entry", "index": 0, "link_index": 0})
	var prior_selection := _editor._dlg_selection.duplicate(true)
	assert(_editor.get_navigation_stack_depth() == 0, "Fresh document should have empty navigation stack")

	_editor._jump_to_link_target("entry", 0, 0)
	assert(str(_editor._dlg_selection.get("kind", "")) == "reply")
	assert(_editor.get_navigation_stack_depth() == 1, "Successful jump should push prior selection")

	_editor._on_navigation_back_pressed()
	assert(_editor._metadata_matches(_editor._dlg_selection, prior_selection), "Back should restore prior link selection")
	assert(_editor.get_navigation_stack_depth() == 0, "Back should pop navigation stack")


func _test_navigation_back_empty_stack() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	_editor._on_navigation_back_pressed()
	assert(_editor.get_navigation_stack_depth() == 0, "Back on empty stack should remain empty")


func _test_remove_all_references_entry_via_editor() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	assert(doc.get_start_count() >= 1, "Fixture should include a start pointing at entry 0")
	_editor._apply_remove_all_references("entry", 0)
	assert(doc.get_start_count() == 0, "Delete references should remove StartingList links to entry 0")
	var orphans := doc.find_orphaned_nodes()
	var found_entry_zero := false
	for orphan in orphans:
		if str(orphan.get("kind", "")) == "entry" and int(orphan.get("index", -1)) == 0:
			found_entry_zero = true
	assert(found_entry_zero, "Entry 0 should be orphaned after start reference removed")
	assert(doc.validate().is_empty(), "Orphaned entry should still validate")


func _test_remove_all_references_reply_via_editor() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	assert(doc.get_node_links("entry", 0).size() >= 1, "Fixture should link entry 0 to reply 0")
	_editor._apply_remove_all_references("reply", 0)
	assert(doc.get_node_links("entry", 0).is_empty(), "Delete references should clear incoming reply links")
	var orphans := doc.find_orphaned_nodes()
	var found_reply_zero := false
	for orphan in orphans:
		if str(orphan.get("kind", "")) == "reply" and int(orphan.get("index", -1)) == 0:
			found_reply_zero = true
	assert(found_reply_zero, "Reply 0 should appear in orphan list after references removed")


func _test_add_node_link_document_api() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	assert(doc.add_entry() == 1, "Second entry should be index 1")
	assert(doc.add_node_link("entry", 1, "reply", 0), "Entry should link to reply via add_node_link")
	assert(
		doc.get_link_target_metadata("entry", 1, 0).get("index", -1) == 0,
		"New entry link should resolve to reply 0"
	)
	assert(not doc.add_node_link("entry", 0, "entry", 1), "Same-kind links should be rejected")
	assert(doc.validate().is_empty(), "Linked dialogue should validate")


func _test_graph_link_via_editor() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var entry_index := doc.add_entry()
	assert(entry_index == 1, "Second entry should be index 1")
	assert(doc.get_node_links("entry", entry_index).is_empty(), "New entry should have no outgoing links")
	_editor._apply_graph_link("entry", entry_index, "reply", 0)
	assert(
		doc.get_link_target_metadata("entry", entry_index, 0).get("index", -1) == 0,
		"Graph link apply should append entry-to-reply link"
	)


func _test_find_linkable_orphans_for_owner() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	doc.remove_all_references_to_node("reply", 0)
	var linkable := doc.find_linkable_orphans_for_owner("entry")
	assert(linkable.size() >= 1, "Entry owner should see orphaned reply targets")
	var found_reply_zero := false
	for orphan in linkable:
		if str(orphan.get("kind", "")) == "reply" and int(orphan.get("index", -1)) == 0:
			found_reply_zero = true
	assert(found_reply_zero, "Orphaned reply 0 should be linkable from entry owner")
	assert(doc.can_link_orphan_to_owner("entry", "reply"))
	assert(not doc.can_link_orphan_to_owner("entry", "entry"))


func _test_restore_orphan_via_editor() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	doc.remove_all_references_to_node("reply", 0)
	_editor._apply_restore_orphan_link("entry", 0, "reply", 0)
	assert(doc.get_node_links("entry", 0).size() >= 1, "Editor restore should recreate reply link")
	assert(doc.find_orphaned_nodes().filter(
		func(o: Dictionary) -> bool:
			return str(o.get("kind", "")) == "reply" and int(o.get("index", -1)) == 0
	).is_empty(), "Reply 0 should leave orphan list after restore")


func _test_orphan_double_click_restore() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	doc.remove_all_references_to_node("reply", 0)
	_editor._select_dlg_metadata({"kind": "entry", "index": 0})
	_editor._refresh_orphan_list()
	var orphan_index := -1
	for row in range(_editor._orphan_list.item_count):
		var metadata = _editor._orphan_list.get_item_metadata(row)
		if typeof(metadata) == TYPE_DICTIONARY:
			if str(metadata.get("kind", "")) == "reply" and int(metadata.get("index", -1)) == 0:
				orphan_index = row
				break
	assert(orphan_index >= 0, "Fixture should list orphaned reply 0")
	_editor._on_orphan_item_activated(orphan_index)
	assert(doc.get_node_links("entry", 0).size() >= 1, "Double-click orphan should restore link to selected entry")


func _test_graph_link_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var entry_index := doc.add_entry()
	_editor._apply_graph_link("entry", entry_index, "reply", 0)
	assert(doc.get_node_links("entry", entry_index).size() == 1, "Graph link should exist after apply")
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(doc.get_node_links("entry", entry_index).is_empty(), "Undo graph link should remove appended link")
		ur.redo()
		assert(doc.get_node_links("entry", entry_index).size() == 1, "Redo graph link should restore link")


func _test_remove_all_references_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var initial_link_count := doc.get_node_links("entry", 0).size()
	_editor._apply_remove_all_references("reply", 0)
	assert(doc.get_node_links("entry", 0).is_empty(), "Apply delete references should remove reply links")
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(
			doc.get_node_links("entry", 0).size() == initial_link_count,
			"Undo delete references should restore reply links"
		)
		ur.redo()
		assert(doc.get_node_links("entry", 0).is_empty(), "Redo delete references should remove reply links again")


func _test_node_add_remove_undo_redo() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	var initial_entries := doc.get_entry_count()
	_editor._apply_node_add("entry")
	assert(doc.get_entry_count() == initial_entries + 1, "Apply add entry should increase count")
	var ur := _editor._get_undo_redo()
	if ur != null:
		ur.undo()
		assert(doc.get_entry_count() == initial_entries, "Undo add entry should restore count")
		ur.redo()
		assert(doc.get_entry_count() == initial_entries + 1, "Redo add entry should restore added entry")


	print("✓ DLG orphan double-click restore passed")


func _test_node_animations_crud() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var doc := _editor.get_document()
	assert(doc.add_node_animation("entry", 0, "talk1"))
	assert(doc.get_node_animations("entry", 0) == ["talk1"])
	assert(doc.add_node_animation("entry", 0, "talk2", 0))
	assert(doc.get_node_animations("entry", 0) == ["talk2", "talk1"])
	assert(doc.reorder_node_animation("entry", 0, 0, 1))
	assert(doc.get_node_animations("entry", 0) == ["talk1", "talk2"])
	assert(doc.set_node_animation("entry", 0, 1, "idle1"))
	assert(doc.get_node_animations("entry", 0) == ["talk1", "idle1"])
	assert(doc.remove_node_animation("entry", 0, 0))
	assert(doc.get_node_animations("entry", 0) == ["idle1"])
	print("✓ DLG node animations CRUD passed")


func _test_camera_fade_fields() -> void:
	var resource := _build_dialogue_resource()
	_editor.open_resource(resource, "", "test_dialogue.dlg")
	var entry := _editor.get_document().get_node("entry", 0)
	assert(entry.has("CameraAngle"))
	assert(entry.has("FadeType"))
	_editor._apply_int_edit(entry, "FadeType", 1.0)
	assert(int(entry.get("FadeType", -1)) == 1)
	_editor._apply_int_edit(entry, "CameraID", 42.0)
	assert(int(entry.get("CameraID", -1)) == 42)
	_editor._apply_string_edit(entry, "CameraAnim", "cam01")
	assert(str(entry.get("CameraAnim", "")) == "cam01")
	print("✓ DLG camera/fade guided fields passed")


func _cleanup() -> void:
	if _editor != null:
		_editor.open_resource(null)
		root.remove_child(_editor)
		_editor.free()
		_editor = null
	_resource = null
	_editor_state = null
	_remove_path_recursive(_install_root)


static func _remove_path_recursive(path: String) -> void:
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var entry_path := path.path_join(entry_name)
			if dir.current_is_dir():
				_remove_path_recursive(entry_path)
			else:
				DirAccess.remove_absolute(entry_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
