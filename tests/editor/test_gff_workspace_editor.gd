@tool
extends SceneTree

const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const UTCResource := preload("../../resources/typed/utc_resource.gd")
const AREResource := preload("../../resources/typed/are_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")

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
