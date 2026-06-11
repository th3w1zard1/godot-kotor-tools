@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_git_instance_crud_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_instance_add_remove_and_install()
	_cleanup()
	print("✓ Module designer GIT instance CRUD tests passed")
	quit()


func _test_instance_add_remove_and_install() -> void:
	var git_path := _install_root.path_join("override").path_join("tar_m02aa.git")
	var seed_file := FileAccess.open(git_path, FileAccess.WRITE)
	seed_file.store_buffer(_build_empty_git_bytes())
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	await process_frame

	assert(editor.get_document().get_total_instance_count() == 0)
	assert(_find_toolbar_button(editor, "Add Instance…") != null)
	assert(_find_toolbar_button(editor, "Remove Instance") != null)

	editor._pending_add_instance_category = "Creatures"
	editor._pending_add_instance_template = "n_malak"
	editor._map_view.set_add_instance_armed(true)
	editor._map_view.instance_add_requested.emit(8.0, -12.0)
	await process_frame

	assert(not editor._map_view.is_add_instance_armed())
	assert(editor.is_document_dirty())
	assert(editor.get_document().get_total_instance_count() == 1)
	var record := editor.get_document().find_instance_record("Creatures", 0)
	assert(str(record.get("template", "")) == "n_malak")
	assert(is_equal_approx(float(record.get("x", 0.0)), 8.0))
	assert(is_equal_approx(float(record.get("y", 0.0)), -12.0))
	assert(editor._map_view._selected_category == "Creatures")
	assert(editor._map_view._selected_index == 0)
	print("✓ GIT instance add updates selection and detail passed")

	editor._remove_selected_instance()
	await process_frame
	assert(editor.get_document().get_total_instance_count() == 0)
	print("✓ GIT instance remove passed")

	editor._pending_add_instance_category = "Placeables"
	editor._pending_add_instance_template = "plc_mssn"
	editor._map_view.set_add_instance_armed(true)
	editor._map_view.instance_add_requested.emit(1.0, 2.0)
	await process_frame
	assert(editor.get_document().get_total_instance_count() == 1)

	var result := editor.install_document_to_override()
	assert(result.get("applied", false), "Install failed: %s" % str(result))
	assert(not editor.is_document_dirty())
	assert(FileAccess.file_exists(git_path))

	var file := FileAccess.open(git_path, FileAccess.READ)
	var parsed := GFFParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	var resource := GFFResourceFactory.create_from_parser_result(parsed) as GITResource
	var document := resource.create_document()
	assert(document.get_struct_list("Placeable List").size() == 1)
	var placeable: Dictionary = document.get_struct_list("Placeable List")[0]
	assert(str(placeable.get("TemplateResRef", "")) == "plc_mssn")
	assert(is_equal_approx(float(placeable.get("XPosition", 0.0)), 1.0))
	assert(is_equal_approx(float(placeable.get("YPosition", 0.0)), 2.0))
	print("✓ GIT instance add install roundtrip passed")


func _find_toolbar_button(editor: KotorModuleDesignerWorkspaceEditor, label: String) -> Button:
	if editor._toolbar == null:
		return null
	for child in editor._toolbar.get_children():
		if child is Button and (child as Button).text == label:
			return child as Button
	return null


func _build_editor() -> KotorModuleDesignerWorkspaceEditor:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	editor._skip_preflight_for_testing = true
	editor.setup(editor_state, controller)
	root.add_child(editor)
	return editor


func _build_git_resource() -> GITResource:
	return GFFResourceFactory.create_from_parser_result(_build_git_parsed()) as GITResource


func _build_git_parsed() -> Dictionary:
	var instance_fields: Array = [
		{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
		{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
		{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
		{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
	]
	var schema_fields: Array = []
	var root := {}
	for list_field in [
		"Creature List",
		"Door List",
		"Encounter List",
		"Placeable List",
		"SoundList",
		"StoreList",
		"TriggerList",
		"WaypointList",
	]:
		root[list_field] = []
		schema_fields.append({
			"name": list_field,
			"type": GFFParser.FIELD_LIST,
			"items": [
				{
					"struct_type": 1,
					"fields": instance_fields,
				},
			],
		})
	return {
		"file_type": "GIT",
		"root": root,
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": schema_fields,
		},
	}


func _build_empty_git_bytes() -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(_build_git_parsed()))


func _cleanup() -> void:
	var git_path := _install_root.path_join("override").path_join("tar_m02aa.git")
	if FileAccess.file_exists(git_path):
		DirAccess.remove_absolute(git_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
