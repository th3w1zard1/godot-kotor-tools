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
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("modules"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_archive_member_listing()
	await _test_extract_member_to_override()
	_test_invalid_extract_file_name()
	await _test_add_member_and_save_archive()
	await _test_remove_member_and_save_archive()
	await _test_replace_member()
	await _test_compare_member_toolbar_buttons()
	await _test_compare_member_with_override()
	await _test_install_archive_to_modules()
	_test_install_sav_to_modules_blocked()
	await _test_extract_all_members_to_override()
	await _test_extract_all_skips_invalid_members()
	await _test_extract_all_members_to_folder()
	await _test_extract_all_members_to_folder_skips_invalid()
	await _test_export_selected_member_to_path()
	_test_export_selected_member_requires_selection()
	_test_resolve_game_archive_dialog_dir()
	_test_open_game_archive_blocked_without_game_path()
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


func _test_add_member_and_save_archive() -> void:
	var editor := _build_editor()
	var mod_bytes := _build_test_mod_bytes()
	editor.open_archive_bytes("test_module.mod", mod_bytes, "")
	assert(not editor.is_document_dirty())

	var member_path := _install_root.path_join("extra_are.are")
	var member_file := FileAccess.open(member_path, FileAccess.WRITE)
	member_file.store_buffer(_build_empty_are_bytes())
	member_file.close()

	var add_result := editor.add_member_from_file(member_path)
	assert(add_result.get("ok", false), str(add_result))
	assert(editor.get_document().get_entry_count() == 2)
	assert(editor.is_document_dirty())

	var saved_path := _install_root.path_join("saved_module.mod")
	if FileAccess.file_exists(saved_path):
		DirAccess.remove_absolute(saved_path)
	var save_result := editor.save_archive_to_path(saved_path)
	assert(save_result.get("applied", false), str(save_result))
	assert(not editor.is_document_dirty())
	assert(FileAccess.file_exists(saved_path))

	var reopened := _build_editor()
	reopened.open_archive_file(saved_path)
	await process_frame
	assert(reopened.get_document().get_entry_count() == 2)
	assert(reopened.get_document().find_entry_index("extra_are", "are") >= 0)
	print("✓ ERF add member and save archive passed")


func _test_remove_member_and_save_archive() -> void:
	var editor := _build_editor()
	editor.open_archive_bytes("test_module.mod", _build_test_mod_bytes(), "")
	await process_frame
	editor._tree.get_root().get_first_child().select(0)
	await process_frame

	var remove_result := editor.remove_selected_member()
	assert(remove_result.get("ok", false), str(remove_result))
	assert(editor.get_document().get_entry_count() == 0)
	assert(editor.is_document_dirty())

	var saved_path := _install_root.path_join("removed_module.mod")
	if FileAccess.file_exists(saved_path):
		DirAccess.remove_absolute(saved_path)
	var save_result := editor.save_archive_to_path(saved_path)
	assert(save_result.get("applied", false), str(save_result))
	assert(FileAccess.file_exists(saved_path))

	var reopened := _build_editor()
	reopened.open_archive_file(saved_path)
	await process_frame
	assert(reopened.get_document().get_entry_count() == 0)
	print("✓ ERF remove member and save archive passed")


func _test_replace_member() -> void:
	var editor := _build_editor()
	editor.open_archive_bytes("test_module.mod", _build_test_mod_bytes(), "")
	await process_frame
	editor._tree.get_root().get_first_child().select(0)
	await process_frame

	var replacement_path := _install_root.path_join("replacement_are.are")
	var replacement_file := FileAccess.open(replacement_path, FileAccess.WRITE)
	replacement_file.store_buffer(_build_empty_are_bytes())
	replacement_file.close()

	var replace_result := editor.replace_member_from_file(replacement_path)
	assert(replace_result.get("ok", false), str(replace_result))
	assert(editor.get_document().entry_file_name(0) == "tar_m02aa.git")
	assert(editor.get_document().get_entry_payload(0) == _build_empty_are_bytes())
	print("✓ ERF replace member passed")


func _test_compare_member_toolbar_buttons() -> void:
	var editor := _build_editor()
	assert(_find_button(editor, "Compare Member with Override...") != null)
	assert(_find_button(editor, "Export Compare Report...") != null)
	print("✓ ERF compare toolbar buttons passed")


func _test_compare_member_with_override() -> void:
	var modules_dir := _install_root.path_join("modules")
	DirAccess.make_dir_recursive_absolute(modules_dir)
	var core_git := _build_empty_git_bytes()
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": core_git},
	])
	var mod_path := modules_dir.path_join("test_area.mod")
	var mod_file := FileAccess.open(mod_path, FileAccess.WRITE)
	mod_file.store_buffer(mod_bytes)
	mod_file.close()

	var override_path := _install_root.path_join("override").path_join("tar_m02aa.git")
	var override_file := FileAccess.open(override_path, FileAccess.WRITE)
	override_file.store_buffer(_build_empty_are_bytes())
	override_file.close()

	var editor := _build_editor()
	editor._editor_state.refresh_gamefs()
	editor.open_archive_file(mod_path)
	await process_frame
	editor._tree.get_root().get_first_child().select(0)
	await process_frame

	var compare_result := editor.compare_selected_member_with_override()
	assert(compare_result.get("ok", false), str(compare_result))
	assert(str(compare_result.get("status", "")) == "different")

	var report_path := _install_root.path_join("tar_m02aa-compare-report")
	if FileAccess.file_exists("%s.txt" % report_path):
		DirAccess.remove_absolute("%s.txt" % report_path)
	var export_result := editor.export_compare_report_to_path(report_path)
	assert(export_result.get("ok", false), str(export_result))
	assert(FileAccess.file_exists("%s.txt" % report_path))
	print("✓ ERF compare member with override passed")


func _test_install_archive_to_modules() -> void:
	var editor := _build_editor()
	editor.open_archive_bytes("deploy_module.mod", _build_test_mod_bytes(), "")
	await process_frame

	var target_path := _install_root.path_join("modules").path_join("deploy_module.mod")
	if FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(target_path)

	var result := editor.install_archive_to_modules()
	assert(result.get("applied", false), str(result))
	assert(FileAccess.file_exists(target_path))
	var file := FileAccess.open(target_path, FileAccess.READ)
	var bytes := file.get_buffer(file.get_length())
	file.close()
	assert(bytes.size() > 0)
	print("✓ ERF install archive to modules passed")


func _test_install_sav_to_modules_blocked() -> void:
	var editor := _build_editor()
	var sav_bytes := ERFWriter.build("SAV ", [
		{"resref": "save", "extension": "ifo", "bytes": PackedByteArray([0x01, 0x02])},
	])
	editor.open_archive_bytes("quicksave.sav", sav_bytes, "")
	var result := editor.install_archive_to_modules()
	assert(not result.get("ok", true))
	print("✓ ERF install SAV to modules blocked passed")


func _test_extract_all_members_to_override() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
		{"resref": "extra_are", "extension": "are", "bytes": _build_empty_are_bytes()},
	])
	var mod_path := _install_root.path_join("batch_module.mod")
	var mod_file := FileAccess.open(mod_path, FileAccess.WRITE)
	mod_file.store_buffer(mod_bytes)
	mod_file.close()

	var git_override := _install_root.path_join("override").path_join("tar_m02aa.git")
	var are_override := _install_root.path_join("override").path_join("extra_are.are")
	for path in [git_override, are_override]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	var editor := _build_editor()
	editor.open_archive_file(mod_path)
	await process_frame

	var result := editor.extract_all_members_to_override()
	assert(result.get("ok", false), str(result))
	assert(int(result.get("applied", 0)) == 2)
	assert(FileAccess.file_exists(git_override))
	assert(FileAccess.file_exists(are_override))
	print("✓ ERF extract all members to override passed")


func _test_extract_all_skips_invalid_members() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
		{"resref": "", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var mod_path := _install_root.path_join("batch_skip_module.mod")
	var mod_file := FileAccess.open(mod_path, FileAccess.WRITE)
	mod_file.store_buffer(mod_bytes)
	mod_file.close()

	var git_override := _install_root.path_join("override").path_join("tar_m02aa.git")
	if FileAccess.file_exists(git_override):
		DirAccess.remove_absolute(git_override)

	var editor := _build_editor()
	editor.open_archive_file(mod_path)
	await process_frame

	var result := editor.extract_all_members_to_override()
	assert(result.get("ok", false), str(result))
	assert(int(result.get("applied", 0)) == 1)
	assert(int(result.get("skipped", 0)) == 1)
	assert(int(result.get("failed", 0)) == 0)
	assert(FileAccess.file_exists(git_override))
	print("✓ ERF extract all skips invalid members passed")


func _test_extract_all_members_to_folder() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "tar_m02aa", "extension": "git", "bytes": _build_empty_git_bytes()},
		{"resref": "extra_are", "extension": "are", "bytes": _build_empty_are_bytes()},
	])
	var mod_path := _install_root.path_join("folder_module.mod")
	var mod_file := FileAccess.open(mod_path, FileAccess.WRITE)
	mod_file.store_buffer(mod_bytes)
	mod_file.close()

	var dest_dir := _install_root.path_join("extracted_folder")
	if DirAccess.dir_exists_absolute(dest_dir):
		_remove_dir_recursive(dest_dir)

	var editor := _build_editor()
	editor.open_archive_file(mod_path)
	await process_frame

	var result := editor.extract_all_members_to_folder(dest_dir)
	assert(result.get("ok", false), str(result))
	assert(int(result.get("written", 0)) == 2)
	assert(FileAccess.file_exists(dest_dir.path_join("tar_m02aa.git")))
	assert(FileAccess.file_exists(dest_dir.path_join("extra_are.are")))
	print("✓ ERF extract all members to folder passed")


func _test_extract_all_members_to_folder_skips_invalid() -> void:
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "valid_are", "extension": "are", "bytes": _build_empty_are_bytes()},
		{"resref": "", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	var dest_dir := _install_root.path_join("extracted_skip_folder")
	if DirAccess.dir_exists_absolute(dest_dir):
		_remove_dir_recursive(dest_dir)

	var editor := _build_editor()
	editor.open_archive_bytes("skip_test.mod", mod_bytes, "")
	await process_frame

	var result := editor.extract_all_members_to_folder(dest_dir)
	assert(result.get("ok", false), str(result))
	assert(int(result.get("written", 0)) == 1)
	assert(int(result.get("skipped", 0)) == 1)
	assert(FileAccess.file_exists(dest_dir.path_join("valid_are.are")))
	print("✓ ERF extract all members to folder skips invalid passed")


func _test_export_selected_member_to_path() -> void:
	var mod_path := _install_root.path_join("export_member_module.mod")
	var mod_file := FileAccess.open(mod_path, FileAccess.WRITE)
	mod_file.store_buffer(_build_test_mod_bytes())
	mod_file.close()

	var editor := _build_editor()
	editor.open_archive_file(mod_path)
	await process_frame
	editor._tree.get_root().get_first_child().select(0)
	await process_frame
	assert(editor.get_selected_entry_index() == 0)

	var export_btn := _find_button(editor, "Export Selected...")
	assert(export_btn != null, "Export Selected toolbar button missing")

	var target_path := _install_root.path_join("exported_tar_m02aa.git")
	if FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(target_path)

	var result := editor.export_selected_member_to_path(target_path)
	assert(result.get("applied", false), "Export failed: %s" % str(result))
	assert(FileAccess.file_exists(target_path))
	var file := FileAccess.open(target_path, FileAccess.READ)
	var parsed := GFFParser.parse_bytes(file.get_buffer(file.get_length()))
	file.close()
	assert(not parsed.is_empty())
	print("✓ ERF export selected member to path passed")


func _test_export_selected_member_requires_selection() -> void:
	var editor := _build_editor()
	editor.open_archive_bytes("no_sel.mod", _build_test_mod_bytes(), "")
	var result := editor.export_selected_member_to_path("/tmp/unused.git")
	assert(not result.get("ok", true))
	print("✓ ERF export selected member requires selection passed")


func _test_resolve_game_archive_dialog_dir() -> void:
	var editor := _build_editor()
	var expected := _install_root.path_join("modules")
	assert(editor.resolve_game_archive_dialog_dir() == expected)
	var open_game_btn := _find_button(editor, "Open Game Archive...")
	assert(open_game_btn != null, "Open Game Archive toolbar button missing")
	print("✓ ERF resolve game archive dialog dir passed")


func _test_open_game_archive_blocked_without_game_path() -> void:
	var editor_state := KotorEditorState.new()
	var controller := KotorWorkspaceController.new(editor_state)
	var editor := KotorErfWorkspaceEditor.new()
	editor.setup(editor_state, controller)
	var root := get_root()
	root.add_child(editor)
	assert(editor.resolve_game_archive_dialog_dir().is_empty())
	editor._open_game_archive_dialog()
	assert(editor._status_text.find("valid game install") >= 0)
	print("✓ ERF open game archive blocked without game path passed")


func _test_invalid_extract_file_name() -> void:
	var editor := _build_editor()
	var mod_bytes := ERFWriter.build("MOD ", [
		{"resref": "", "extension": "git", "bytes": _build_empty_git_bytes()},
	])
	editor.open_archive_bytes("invalid.mod", mod_bytes, "")
	var result := editor.install_entry_to_override(0)
	assert(not result.get("ok", true))
	print("✓ ERF invalid extract file name blocked passed")


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


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


func _build_empty_are_bytes() -> PackedByteArray:
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result({
		"file_type": "ARE ",
		"root": {},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	}))


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
