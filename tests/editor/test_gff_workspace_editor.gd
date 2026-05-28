@tool
extends SceneTree

const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const UTCResource := preload("../../resources/typed/utc_resource.gd")
const AREResource := preload("../../resources/typed/are_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")

var _install_root := ""
var _utc_saved_path := ""
var _are_saved_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://gff_workspace_editor_test_install")
	_utc_saved_path = _install_root.path_join("test_creature.utc")
	_are_saved_path = _install_root.path_join("test_area.are")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_assert_editor_behavior")


func _assert_editor_behavior() -> void:
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("utc"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("are"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("ifo"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("jrl"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("pth"))
	assert(KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("fac"))
	assert(not KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("dlg"))

	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)

	var editor := KotorGFFWorkspaceEditor.new()
	editor._skip_preflight_for_testing = true
	editor.setup(editor_state, controller)
	root.add_child(editor)

	_exercise_utc_round_trip(editor, controller)
	_exercise_are_round_trip(editor, controller)

	_cleanup()
	quit()


func _exercise_utc_round_trip(editor: KotorGFFWorkspaceEditor, controller: KotorWorkspaceController) -> void:
	editor.open_resource(_build_utc_resource(), "", "test_creature.utc")
	assert(editor.has_document())
	assert(editor.get_document().get_tag() == "workspace_creature")

	editor.apply_tree_field_edit(["TemplateResRef"], "edited_template")
	assert(editor.get_document().get_resref("TemplateResRef") == "edited_template")

	editor.apply_tree_field_edit(["TestList", 0, "Text"], "gamma")
	assert(editor.get_document().get_field_at_path(["TestList", 0, "Text"]) == "gamma")

	editor.get_document().set_string("Tag", "edited_creature")
	assert(editor.is_document_dirty())

	var save_result := editor.save_document_to_path(_utc_saved_path)
	assert(save_result.get("ok", false))
	assert(FileAccess.file_exists(_utc_saved_path))
	assert(not editor.is_document_dirty())

	var install_result := editor.install_document_to_override()
	assert(install_result.get("ok", false))
	assert(FileAccess.file_exists(_install_root.path_join("override").path_join("test_creature.utc")))

	var utc_saved_bytes := FileAccess.get_file_as_bytes(_utc_saved_path)
	var utc_reparsed := GFFParser.parse_bytes(utc_saved_bytes)
	var utc_saved := GFFResourceFactory.create_from_parser_result(utc_reparsed)
	var utc_saved_document := utc_saved.create_document()
	assert(utc_saved_document.get_resref("TemplateResRef") == "edited_template")
	assert(utc_saved_document.get_field_at_path(["TestList", 0, "Text"]) == "gamma")

	assert(str(controller.document_registry.list_documents()[0].get("editor_kind", "")) == "gff")
	assert(controller.document_registry.get_document_entry("gff:%s" % _utc_saved_path).get("dirty", false) == false)


func _exercise_are_round_trip(editor: KotorGFFWorkspaceEditor, controller: KotorWorkspaceController) -> void:
	editor.open_resource(_build_are_resource(), "", "test_area.are")
	assert(editor.has_document())
	assert(editor.get_document().get_tag() == "workspace_area")

	editor.apply_display_name_edit("Edited Area Name")
	assert(editor.get_document().get_locstring_text("Name") == "Edited Area Name")

	editor.get_document().set_string("Tag", "edited_area")
	assert(editor.is_document_dirty())

	var save_result := editor.save_document_to_path(_are_saved_path)
	assert(save_result.get("ok", false))
	assert(FileAccess.file_exists(_are_saved_path))
	assert(not editor.is_document_dirty())

	var install_result := editor.install_document_to_override()
	assert(install_result.get("ok", false))
	assert(FileAccess.file_exists(_install_root.path_join("override").path_join("test_area.are")))

	var saved_bytes := FileAccess.get_file_as_bytes(_are_saved_path)
	var reparsed := GFFParser.parse_bytes(saved_bytes)
	var saved_resource := GFFResourceFactory.create_from_parser_result(reparsed)
	var saved_document := saved_resource.create_document()
	assert(saved_document.get_locstring_text("Name") == "Edited Area Name")
	assert(saved_document.get_string("Tag") == "edited_area")

	var documents: Array[Dictionary] = controller.document_registry.list_documents()
	assert(documents.size() == 2)
	assert(controller.document_registry.get_document_entry("gff:%s" % _are_saved_path).get("dirty", false) == false)


func _build_utc_resource() -> UTCResource:
	var resource := UTCResource.new()
	resource.setup_from_parser_result({
		"file_type": "UTC",
		"root": {
			"Tag": "workspace_creature",
			"TemplateResRef": "nw_crea_human",
			"TestList": [
				{"Text": "alpha"},
				{"Text": "beta"},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
				{
					"name": "TestList",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 1,
							"fields": [
								{"name": "Text", "type": GFFParser.FIELD_CEXOSTRING},
							],
						},
					],
				},
			],
		},
	})
	return resource


func _build_are_resource() -> AREResource:
	var resource := AREResource.new()
	resource.setup_from_parser_result({
		"file_type": "ARE",
		"root": {
			"Tag": "workspace_area",
			"Name": {
				"strref": 0xFFFFFFFF,
				"strings": {0: "Test Area"},
			},
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "Name", "type": GFFParser.FIELD_CEXOLOCSTR},
			],
		},
	})
	return resource


func _cleanup() -> void:
	for path in [
		_utc_saved_path,
		_are_saved_path,
		_install_root.path_join("override").path_join("test_creature.utc"),
		_install_root.path_join("override").path_join("test_area.are"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)


# === Q7 Array Mutation Tests ===

func _test_array_insert_basic() -> void:
	# Test: Insert new struct into CreatureActions array
	var resource = _build_creature_with_actions()
	var initial_count = (resource.root.get("CreatureActions", []) as Array).size()
	
	var new_action := {
		"ActionID": 99,
		"Comment": "Test insert",
		"Flags": 0,
	}
	
	# Create document and perform insert
	var document = resource.create_document()
	document.insert_struct_at_array("CreatureActions", 0, new_action)
	
	var updated_array = document.get_field("CreatureActions") as Array
	assert(updated_array.size() == initial_count + 1, "Array size should increase by 1")
	assert(updated_array[0].get("ActionID") == 99, "New action should be at index 0")


func _test_array_remove_basic() -> void:
	# Test: Remove struct from CreatureActions array
	var resource = _build_creature_with_actions()
	var initial_count = (resource.root.get("CreatureActions", []) as Array).size()
	
	var document = resource.create_document()
	var removed_action_id = (document.get_field("CreatureActions") as Array)[0].get("ActionID")
	
	document.remove_struct_from_array("CreatureActions", 0)
	
	var updated_array = document.get_field("CreatureActions") as Array
	assert(updated_array.size() == initial_count - 1, "Array size should decrease by 1")
	assert(updated_array[0].get("ActionID") != removed_action_id, "Removed action should be gone")


func _test_array_reorder_basic() -> void:
	# Test: Reorder struct in CreatureActions array
	var resource = _build_creature_with_actions()
	var document = resource.create_document()
	
	var array = document.get_field("CreatureActions") as Array
	var action_id_at_0 = array[0].get("ActionID")
	var action_id_at_1 = array[1].get("ActionID")
	
	document.reorder_array_item("CreatureActions", 0, 1)
	
	var reordered_array = document.get_field("CreatureActions") as Array
	assert(reordered_array[0].get("ActionID") == action_id_at_1, "Second action should be first")
	assert(reordered_array[1].get("ActionID") == action_id_at_0, "First action should be second")


func _test_array_insert_empty_list() -> void:
	# Test: Insert into empty array (from-scratch creation)
	var resource = _build_creature_empty()
	var document = resource.create_document()
	
	var new_action := {
		"ActionID": 0,
		"Comment": "Only action",
		"Flags": 0,
	}
	
	document.insert_struct_at_array("CreatureActions", 0, new_action)
	
	var array = document.get_field("CreatureActions") as Array
	assert(array.size() == 1, "Array should have one item")
	assert(array[0].get("ActionID") == 0, "Action should be inserted")


func _test_array_remove_last_item() -> void:
	# Test: Remove the final item from array (down to empty)
	var resource = _build_creature_with_single_action()
	var document = resource.create_document()
	
	document.remove_struct_from_array("CreatureActions", 0)
	
	var array = document.get_field("CreatureActions") as Array
	assert(array.size() == 0, "Array should be empty after removing last item")


func _test_array_undo_redo_round_trip() -> void:
	# Test: Insert → Undo → Redo sequence preserves state
	# Note: Requires editor context with EditorUndoRedoManager
	# This test documents the expected behavior; full testing requires headless editor
	pass


func _test_array_validation_required_field() -> void:
	# Test: Required field validation (Operator, Script, ActionID)
	assert(TypedFieldHelpers.is_required_field("Operator"))
	assert(TypedFieldHelpers.is_required_field("Script"))
	assert(TypedFieldHelpers.is_required_field("ActionID"))
	
	assert(TypedFieldHelpers.validate_required_field("Operator", 0))
	assert(TypedFieldHelpers.validate_required_field("Operator", 1))
	assert(TypedFieldHelpers.validate_required_field("Operator", 2))
	assert(not TypedFieldHelpers.validate_required_field("Operator", 3))
	
	assert(TypedFieldHelpers.validate_required_field("Script", "valid_script"))
	assert(not TypedFieldHelpers.validate_required_field("Script", ""))
	
	assert(TypedFieldHelpers.validate_required_field("ActionID", -1))
	assert(TypedFieldHelpers.validate_required_field("ActionID", 0))


func _test_array_validation_optional_field() -> void:
	# Test: Optional field warnings (Comment, EventID, Parameter)
	var comment_warning = TypedFieldHelpers.get_validation_warning("Comment", "")
	assert(comment_warning.is_empty() or comment_warning.contains("empty"), "Empty comment may warn (optional)")
	
	var eventid_warning = TypedFieldHelpers.get_validation_warning("EventID", 0)
	assert(eventid_warning.contains("EventID"), "EventID=0 should warn")
	
	var param_warning = TypedFieldHelpers.get_validation_warning("Parameter", 0)
	assert(param_warning.contains("Parameter"), "Parameter=0 should warn")


func _build_creature_with_actions():
	# Build UTC with 2 CreatureActions
	var gff_data := {
		"Tag": "test_creature",
		"TemplateResRef": "c_commoner",
		"CreatureActions": [
			{"ActionID": 0, "Comment": "Action 1", "Flags": 0},
			{"ActionID": 1, "Comment": "Action 2", "Flags": 0},
		],
	}
	var resource := UTCResource.new()
	resource.root = gff_data
	resource.file_type = "UTC "
	return resource


func _build_creature_empty():
	# Build UTC with empty CreatureActions
	var gff_data := {
		"Tag": "test_creature_empty",
		"TemplateResRef": "c_commoner",
		"CreatureActions": [],
	}
	var resource := UTCResource.new()
	resource.root = gff_data
	resource.file_type = "UTC "
	return resource


func _build_creature_with_single_action():
	# Build UTC with 1 CreatureAction
	var gff_data := {
		"Tag": "test_creature_single",
		"TemplateResRef": "c_commoner",
		"CreatureActions": [
			{"ActionID": 0, "Comment": "Only action", "Flags": 0},
		],
	}
	var resource := UTCResource.new()
	resource.root = gff_data
	resource.file_type = "UTC "
	return resource
