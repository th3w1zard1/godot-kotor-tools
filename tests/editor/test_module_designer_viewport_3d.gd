@tool
extends SceneTree

const KotorWorldCoordinates := preload("../../editor/module/kotor_world_coordinates.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")
const LYTParser := preload("../../formats/lyt_parser.gd")
const ModuleDesignerViewport3D := preload("../../ui/workspace/panels/module_designer_viewport_3d.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_viewport_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_world_coordinates()
	_test_layout_parsing()
	_test_viewport_markers()
	_test_editor_has_viewport()
	_cleanup()
	print("✓ Module designer 3D viewport tests passed")
	quit()


func _test_world_coordinates() -> void:
	var kotor := Vector3(10.0, -4.0, 2.5)
	var godot := KotorWorldCoordinates.kotor_to_godot(kotor)
	assert(is_equal_approx(godot.x, 10.0))
	assert(is_equal_approx(godot.y, 2.5))
	assert(is_equal_approx(godot.z, 4.0))
	var roundtrip := KotorWorldCoordinates.godot_to_kotor(godot)
	assert(roundtrip.is_equal_approx(kotor))
	print("✓ World coordinate mapping passed")


func _test_layout_parsing() -> void:
	var lyt_text := "beginlayout\nroomcount 1\nroommodel room001 0.0 0.0 0.0\ndonelayout\n"
	var parsed := LYTParser.parse_bytes(lyt_text.to_utf8_buffer())
	assert(parsed.get("rooms", []).size() == 1)
	var lyt_path := _install_root.path_join("override").path_join("tar_m02aa.lyt")
	var file := FileAccess.open(lyt_path, FileAccess.WRITE)
	file.store_string(lyt_text)
	file.close()
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var bundle := KotorModuleContext.find_module_bundle(editor_state.gamefs, "tar_m02aa")
	assert(not bundle.get("lyt", {}).is_empty())
	var layout := KotorModuleContext.load_parsed_layout(editor_state.gamefs, bundle)
	assert(layout.get("rooms", []).size() == 1)
	print("✓ Layout bundle + parse passed")


func _test_viewport_markers() -> void:
	var viewport := ModuleDesignerViewport3D.new()
	root.add_child(viewport)
	var records := [
		{
			"category": "Creatures",
			"index": 0,
			"x": 1.0,
			"y": 2.0,
			"z": 0.5,
			"bearing": 0.0,
			"template": "npc_test",
			"tag": "",
		},
	]
	var layout := {
		"rooms": [
			{"model": "room001", "position": Vector3(0.0, 0.0, 0.0)},
		],
	}
	viewport.set_instances(records, layout)
	assert(viewport.get_child_count() >= 1)
	viewport.set_selection("Creatures", 0)
	print("✓ Viewport marker build passed")


func _test_editor_has_viewport() -> void:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorModuleDesignerWorkspaceEditor.new()
	editor.setup(editor_state, controller)
	root.add_child(editor)
	var resource := _build_git_resource()
	editor.open_resource(resource, "", "tar_m02aa.git")
	assert(editor._viewport_3d != null)
	print("✓ Module designer editor wires 3D viewport passed")


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
			],
		},
	}


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(_install_root):
		_remove_dir_recursive(_install_root)


func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var child := path.path_join(name)
			if DirAccess.dir_exists_absolute(child):
				_remove_dir_recursive(child)
			else:
				DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
