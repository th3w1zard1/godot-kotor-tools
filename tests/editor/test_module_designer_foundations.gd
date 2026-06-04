@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")
const KotorGITDocument := preload("../../resources/documents/kotor_git_document.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_foundations_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_extension_routing()
	_test_module_context_helpers()
	_test_git_document_instances()
	_test_module_designer_editor()
	_test_install_roundtrip()
	_cleanup()
	print("✓ Module designer foundations tests passed")
	quit()


func _test_extension_routing() -> void:
	assert(KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed("git"))
	assert(not KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed("utc"))
	assert(not KotorGFFWorkspaceEditor.workspace_gff_extension_allowed("git"))
	print("✓ Module designer extension routing passed")


func _test_module_context_helpers() -> void:
	assert(KotorModuleContext.module_resref_from_file_name("tar_m02aa.git") == "tar_m02aa")
	assert(KotorModuleContext.module_resref_from_file_name("/mods/custom/tar_m02aa.git") == "tar_m02aa")
	var partial_bundle := {
		"module_resref": "tar_m02aa",
		"git": {},
		"are": {},
		"ifo": {},
	}
	assert(KotorModuleContext.describe_bundle(partial_bundle).contains("missing"))
	assert(KotorModuleContext.describe_bundle({}) == "No module bundle")
	print("✓ Module context helpers passed")


func _test_git_document_instances() -> void:
	var document := _build_git_document()
	var records := document.get_instance_records()
	assert(records.size() == 2)
	assert(document.find_instance_record("Creatures", 0).get("template") == "n_malak")
	assert(document.find_instance_record("Doors", 0).get("template") == "door021")
	var bounds := document.get_layout_bounds()
	assert(bounds.size.x > 0.0)
	assert(bounds.size.y > 0.0)
	assert(bounds.has_point(Vector2(10.0, -4.0)))
	print("✓ GIT document instance extraction passed")


func _test_module_designer_editor() -> void:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	editor._skip_preflight_for_testing = true
	editor.setup(editor_state, controller)
	root.add_child(editor)

	var resource := _build_git_resource()
	editor.open_resource(resource, "", "tar_m02aa.git")
	assert(editor.has_document())
	assert(editor.get_document().get_total_instance_count() == 2)
	assert(editor.get_document().get_display_name().contains("2 placed objects"))
	print("✓ Module designer editor open/load passed")


func _test_install_roundtrip() -> void:
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	editor._skip_preflight_for_testing = true
	editor.setup(editor_state, controller)
	root.add_child(editor)

	var resource := _build_git_resource()
	editor.open_resource(resource, "", "tar_m02aa.git")
	var result: Dictionary = editor.install_document_to_override()
	if not (result.get("applied", false) and result.get("ok", false)):
		push_error("Install roundtrip failed: %s" % str(result))
		quit(1)

	var installed_path := _install_root.path_join("override").path_join("tar_m02aa.git")
	assert(FileAccess.file_exists(installed_path))
	print("✓ Module designer install roundtrip passed")


func _cleanup() -> void:
	var installed_path := _install_root.path_join("override").path_join("tar_m02aa.git")
	if FileAccess.file_exists(installed_path):
		DirAccess.remove_absolute(installed_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)


func _build_git_parsed() -> Dictionary:
	var instance_fields: Array = [
		{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
		{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
		{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
	]
	var door_fields: Array = [
		{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
		{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
	]
	return {
		"file_type": "GIT",
		"root": {
			"Creature List": [
				{
					"TemplateResRef": "n_malak",
					"Tag": "malak",
					"XPosition": 10.0,
					"YPosition": -4.0,
					"ZPosition": 0.0,
					"Bearing": 1.57,
				},
			],
			"Door List": [
				{
					"TemplateResRef": "door021",
					"XPosition": 2.0,
					"YPosition": 3.0,
					"ZPosition": 0.0,
				},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{
					"name": "Creature List",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 1,
							"fields": instance_fields,
						},
					],
				},
				{
					"name": "Door List",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 2,
							"fields": door_fields,
						},
					],
				},
			],
		},
	}


func _build_git_resource() -> GITResource:
	return GFFResourceFactory.create_from_parser_result(_build_git_parsed()) as GITResource


func _build_git_document() -> KotorGITDocument:
	return _build_git_resource().create_document() as KotorGITDocument
