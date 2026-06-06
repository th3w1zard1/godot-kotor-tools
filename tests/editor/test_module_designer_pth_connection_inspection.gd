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
	_install_root = ProjectSettings.globalize_path("user://module_designer_pth_connection_inspection_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_path_connection_tree_and_selection()
	_cleanup()
	print("✓ Module designer PTH connection inspection tests passed")
	quit()


func _test_path_connection_tree_and_selection() -> void:
	var pth_path := _install_root.path_join("override").path_join("tar_m02aa.pth")
	var seed_file := FileAccess.open(pth_path, FileAccess.WRITE)
	seed_file.store_buffer(_build_pth_bytes())
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	await process_frame

	var connection_group := _find_tree_item(editor._instance_tree, "Path Connections (2)")
	assert(connection_group != null)
	var connection_item := _find_tree_item(editor._instance_tree, "Connection 1: 2 -> 3")
	assert(connection_item != null)
	connection_item.select(0)
	await process_frame

	assert(editor._detail_label.text.find("Path Connection #1") >= 0)
	assert(editor._detail_label.text.find("Source: Point 2") >= 0)
	assert(editor._detail_label.text.find("Target: Point 3") >= 0)
	assert(editor._map_view._selected_path_connection_index == 1)
	assert(editor._viewport_3d._selected_path_connection_index == 1)
	assert(editor._viewport_3d._path_root.get_node_or_null("SelectedPathEdge") != null)
	print("✓ PTH connection tree selection detail passed")

	editor._map_view.path_connection_selected.emit(0)
	await process_frame
	assert(editor._detail_label.text.find("Path Connection #0") >= 0)
	assert(editor._viewport_3d._selected_path_connection_index == 0)

	editor._viewport_3d.path_connection_selected.emit(1)
	await process_frame
	assert(editor._detail_label.text.find("Path Connection #1") >= 0)
	assert(editor._map_view._selected_path_connection_index == 1)
	print("✓ PTH connection map + viewport selection passed")


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


func _find_tree_item(tree: Tree, label: String) -> TreeItem:
	var root_item := tree.get_root()
	if root_item == null:
		return null
	return _find_tree_item_recursive(root_item, label)


func _find_tree_item_recursive(item: TreeItem, label: String) -> TreeItem:
	if item.get_text(0) == label:
		return item
	for child in item.get_children():
		var found := _find_tree_item_recursive(child, label)
		if found != null:
			return found
	return null


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
