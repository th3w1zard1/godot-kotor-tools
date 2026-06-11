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
	_install_root = ProjectSettings.globalize_path("user://module_designer_pth_connection_overlay_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_connection_overlay_wiring()
	_cleanup()
	print("✓ Module designer PTH connection overlay tests passed")
	quit()


func _test_connection_overlay_wiring() -> void:
	var pth_path := _install_root.path_join("override").path_join("tar_m02aa.pth")
	var seed_file := FileAccess.open(pth_path, FileAccess.WRITE)
	seed_file.store_buffer(_build_pth_bytes())
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	await process_frame

	assert(editor._path_resource != null)
	assert(editor._path_resource.get_connection_count() == 2)
	assert(editor._summary_label.text.find("2 connection(s)") >= 0)
	assert(editor._map_view._path_edges.size() == 2)

	var path_root := editor._viewport_3d._path_root
	assert(path_root != null)
	assert(path_root.get_node_or_null("PathEdges") != null)
	assert(path_root.get_child_count() == 4)
	print("✓ PTH connection map + viewport overlays passed")


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
	var parsed := {
		"file_type": "GIT ",
		"root": {
			"Creature List": [],
			"Door List": [],
			"Encounter List": [],
			"Placeable List": [],
			"SoundList": [],
			"StoreList": [],
			"TriggerList": [],
			"WaypointList": [],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	}
	return GFFResourceFactory.create_from_parser_result(parsed) as GITResource


func _build_pth_bytes() -> PackedByteArray:
	var parsed := {
		"file_type": "PTH",
		"root": {
			"Tag": "module_paths",
			"Path_Points": [
				{"ID": 1, "X": 40.0, "Y": -35.0, "Z": 0.0, "Conections": 1, "First_Conection": 0},
				{"ID": 2, "X": 45.0, "Y": -30.0, "Z": 1.0, "Conections": 1, "First_Conection": 1},
				{"ID": 3, "X": 42.0, "Y": -28.0, "Z": 0.5, "Conections": 0, "First_Conection": 2},
			],
			"Path_Conections": [
				{"Destination": 1},
				{"Destination": 2},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
				{
					"name": "Path_Points",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{"name": "ID", "type": GFFParser.FIELD_INT},
								{"name": "X", "type": GFFParser.FIELD_FLOAT},
								{"name": "Y", "type": GFFParser.FIELD_FLOAT},
								{"name": "Z", "type": GFFParser.FIELD_FLOAT},
								{"name": "Conections", "type": GFFParser.FIELD_INT},
								{"name": "First_Conection", "type": GFFParser.FIELD_INT},
							],
						},
					],
				},
				{
					"name": "Path_Conections",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 0,
							"fields": [
								{"name": "Destination", "type": GFFParser.FIELD_INT},
							],
						},
					],
				},
			],
		},
	}
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(parsed))


func _cleanup() -> void:
	var pth_path := _install_root.path_join("override").path_join("tar_m02aa.pth")
	if FileAccess.file_exists(pth_path):
		DirAccess.remove_absolute(pth_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
