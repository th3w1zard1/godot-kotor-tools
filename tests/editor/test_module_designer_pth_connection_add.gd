@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const PTHResource := preload("../../resources/typed/pth_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_pth_connection_add_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_path_connection_add_and_install()
	_cleanup()
	print("✓ Module designer PTH connection add tests passed")
	quit()


func _test_path_connection_add_and_install() -> void:
	var pth_path := _install_root.path_join("override").path_join("tar_m02aa.pth")
	var seed_file := FileAccess.open(pth_path, FileAccess.WRITE)
	seed_file.store_buffer(_build_pth_bytes())
	seed_file.close()

	var editor := _build_editor()
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	await process_frame

	assert(editor._path_resource.get_connection_records().size() == 2)
	editor._map_view.path_point_selected.emit(0)
	await process_frame
	editor._map_view.path_connection_add_requested.emit(0, 2)
	await process_frame

	assert(not editor._map_view.is_add_path_connection_armed())
	assert(editor.is_document_dirty())
	assert(editor._path_resource.get_connection_records().size() == 3)
	assert(editor._map_view._selected_path_connection_index >= 0)

	var added_connection: Dictionary = {}
	for connection_record in editor._path_resource.get_connection_records():
		if (
			int(connection_record.get("source_index", -1)) == 0
			and int(connection_record.get("target_index", -1)) == 2
		):
			added_connection = connection_record
			break
	assert(not added_connection.is_empty())
	assert(editor._detail_label.text.find("Source: Point 1") >= 0)
	assert(editor._detail_label.text.find("Target: Point 3") >= 0)
	print("✓ PTH connection add updates detail and overlays passed")

	DirAccess.remove_absolute(pth_path)
	var result := editor.install_pth_to_override()
	assert(result.get("ok", false))
	assert(result.get("applied", false))

	var file := FileAccess.open(pth_path, FileAccess.READ)
	var parsed := GFFParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	var resource := GFFResourceFactory.create_from_parser_result(parsed) as PTHResource
	assert(resource.get_connection_records().size() == 3)
	var installed := false
	for connection_record in resource.get_connection_records():
		if (
			int(connection_record.get("source_index", -1)) == 0
			and int(connection_record.get("target_index", -1)) == 2
		):
			installed = true
			break
	assert(installed)
	print("✓ PTH connection add install roundtrip passed")


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
