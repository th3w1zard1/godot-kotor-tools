@tool
extends SceneTree

const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GITResource := preload("../../resources/typed/git_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModuleContext := preload("../../editor/module/kotor_module_context.gd")
const KotorModuleDesignerWorkspaceEditor := preload("../../ui/workspace/editors/module_designer_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_designer_bundle_utility_panel_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_bundle_resource_entries()
	var tree_ok := await _test_bundle_tree_populates_and_emits_open()
	_cleanup()
	if not tree_ok:
		push_error("Bundle utility tree tests failed")
		quit(1)
	print("✓ Module designer bundle utility panel tests passed")
	quit()


func _test_bundle_resource_entries() -> void:
	var bundle := {
		"module_resref": "tar_m02aa",
		"git": {"resref": "tar_m02aa", "extension": "git", "source": "override"},
		"are": {},
		"ifo": {},
		"pth": {"resref": "tar_m02aa", "extension": "pth", "source": "override"},
	}
	var records := KotorModuleContext.get_bundle_resource_entries(bundle)
	assert(records.size() == KotorModuleContext.MODULE_EXTENSIONS.size())
	assert(records[0].get("label") == "GIT")
	assert(records[0].get("available", false))
	assert(str(records[1].get("description", "")) == "missing")
	assert(records[5].get("available", false))
	print("✓ Bundle resource entry helper passed")


func _test_bundle_tree_populates_and_emits_open() -> bool:
	var override_dir := _install_root.path_join("override")
	var git_path := override_dir.path_join("tar_m02aa.git")
	var git_file := FileAccess.open(git_path, FileAccess.WRITE)
	git_file.store_buffer(_build_minimal_git_bytes())
	git_file.close()

	var pth_path := override_dir.path_join("tar_m02aa.pth")
	var seed_file := FileAccess.open(pth_path, FileAccess.WRITE)
	seed_file.store_buffer(_build_minimal_pth_bytes())
	seed_file.close()

	var editor := _build_editor()
	var opened: Array[Dictionary] = []
	editor.bundle_resource_open_requested.connect(func(entry: Dictionary) -> void:
		opened.append(entry)
	)
	editor.open_resource(_build_git_resource(), "", "tar_m02aa.git")
	await process_frame

	var root := editor._bundle_tree.get_root()
	assert(root != null)
	assert(root.get_child_count() == KotorModuleContext.MODULE_EXTENSIONS.size())
	var pth_item: TreeItem = null
	var child := root.get_first_child()
	while child != null:
		var record: Dictionary = child.get_metadata(0)
		if str(record.get("extension", "")) == "pth":
			pth_item = child
			break
		child = child.get_next()
	assert(pth_item != null)
	assert(str(pth_item.get_text(0)).find("override") >= 0)

	editor._bundle_tree.set_selected(pth_item, 0)
	editor._on_bundle_tree_item_activated()
	await process_frame
	assert(opened.size() == 1)
	assert(str(opened[0].get("extension", "")) == "pth")
	print("✓ Bundle utility tree populate and open signal passed")
	return true


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


func _build_minimal_git_bytes() -> PackedByteArray:
	const GFFParser := preload("../../formats/gff_parser.gd")
	const GFFWriter := preload("../../formats/gff_writer.gd")
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
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(parsed))


func _build_minimal_pth_bytes() -> PackedByteArray:
	const GFFParser := preload("../../formats/gff_parser.gd")
	const GFFWriter := preload("../../formats/gff_writer.gd")
	var parsed := {
		"file_type": "PTH",
		"root": {
			"Tag": "module_paths",
			"Path_Points": [
				{"ID": 1, "X": 1.0, "Y": 2.0, "Z": 0.0, "Conections": 0, "First_Conection": 0},
			],
			"Path_Conections": [],
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
	var override_dir := _install_root.path_join("override")
	var git_path := override_dir.path_join("tar_m02aa.git")
	if FileAccess.file_exists(git_path):
		DirAccess.remove_absolute(git_path)
	var pth_path := override_dir.path_join("tar_m02aa.pth")
	if FileAccess.file_exists(pth_path):
		DirAccess.remove_absolute(pth_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
