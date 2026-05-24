@tool
extends SceneTree

const KotorGFFWorkspaceEditor := preload("../../ui/workspace/editors/gff_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const UTCResource := preload("../../resources/typed/utc_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")

var _install_root := ""
var _saved_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://gff_workspace_editor_test_install")
	_saved_path = _install_root.path_join("test_creature.utc")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_assert_editor_behavior")


func _assert_editor_behavior() -> void:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)

	var editor := KotorGFFWorkspaceEditor.new()
	editor._skip_preflight_for_testing = true
	editor.setup(editor_state, controller)
	root.add_child(editor)

	var resource := _build_utc_resource()
	editor.open_resource(resource, "", "test_creature.utc")
	assert(editor.has_document())
	assert(editor.get_document().get_tag() == "workspace_creature")

	editor.get_document().set_string("Tag", "edited_creature")
	assert(editor.is_document_dirty())

	var save_result := editor.save_document_to_path(_saved_path)
	assert(save_result.get("ok", false))
	assert(FileAccess.file_exists(_saved_path))
	assert(not editor.is_document_dirty())

	var install_result := editor.install_document_to_override()
	assert(install_result.get("ok", false))
	assert(FileAccess.file_exists(_install_root.path_join("override").path_join("test_creature.utc")))

	var documents: Array[Dictionary] = controller.document_registry.list_documents()
	assert(documents.size() == 1)
	assert(str(documents[0].get("editor_kind", "")) == "gff")
	assert(controller.document_registry.get_document_entry("gff:%s" % _saved_path).get("dirty", false) == false)

	_cleanup()
	quit()


func _build_utc_resource() -> UTCResource:
	var resource := UTCResource.new()
	resource.setup_from_parser_result({
		"file_type": "UTC",
		"root": {
			"Tag": "workspace_creature",
			"TemplateResRef": "nw_crea_human",
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
				{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
			],
		},
	})
	return resource


func _cleanup() -> void:
	for path in [
		_saved_path,
		_install_root.path_join("override").path_join("test_creature.utc"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
