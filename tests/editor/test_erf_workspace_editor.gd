@tool
extends SceneTree

const ERFWriter := preload("../../formats/erf_writer.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorErfWorkspaceEditor := preload("../../ui/workspace/editors/erf_workspace_editor.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://erf_workspace_editor_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_archive_member_listing()
	await _test_extract_member_to_override()
	_test_invalid_extract_file_name()
	_cleanup()
	print("✓ ERF workspace editor tests passed")
	quit()


func _test_archive_member_listing() -> void:
	var editor := _build_editor()
	var mod_bytes := _build_test_mod_bytes()
	editor.open_archive_bytes("test_module.mod", mod_bytes, "")
	assert(editor.get_document() != null)
	assert(editor.get_document().get_entry_count() == 1)
	assert(editor.get_document().entry_file_name(0) == "tar_m02aa.git")
	print("✓ ERF archive member listing passed")


func _test_extract_member_to_override() -> void:
	var mod_path := _install_root.path_join("test_module.mod")
	var mod_file := FileAccess.open(mod_path, FileAccess.WRITE)
	mod_file.store_buffer(_build_test_mod_bytes())
	mod_file.close()

	var editor := _build_editor()
	editor.open_archive_file(mod_path)
	await process_frame
	editor._tree.get_root().get_first_child().select(0)
	await process_frame
	assert(editor.get_selected_entry_index() == 0)

	var target_path := _install_root.path_join("override").path_join("tar_m02aa.git")
	if FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(target_path)

	var result := editor.install_selected_entry_to_override()
	assert(result.get("applied", false), "Extract failed: %s" % str(result))
	assert(FileAccess.file_exists(target_path))
	var file := FileAccess.open(target_path, FileAccess.READ)
	var parsed := GFFParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(not parsed.is_empty())
	print("✓ ERF extract member to override passed")


func _test_invalid_extract_file_name() -> void:
	var editor := _build_editor()
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	editor.open_archive_bytes("invalid.mod", mod_bytes, "")
	var result := editor.install_entry_to_override(0)
	assert(not result.get("ok", true))
	print("✓ ERF invalid extract file name blocked passed")


func _build_editor() -> KotorErfWorkspaceEditor:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorErfWorkspaceEditor.new()
	editor.setup(editor_state, controller)
	editor._skip_preflight_for_testing = true
	root.add_child(editor)
	return editor


func _build_test_mod_bytes() -> PackedByteArray:
	return ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
	])


func _build_empty_git_bytes() -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(_build_git_parsed()))


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


func _cleanup() -> void:
	if _install_root.is_empty():
		return
	_remove_dir_recursive(_install_root)


static func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var child := "%s/%s" % [path, name]
			if dir.current_is_dir():
				_remove_dir_recursive(child)
			else:
				DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
