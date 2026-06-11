@tool
extends SceneTree

const KotorDock := preload("../../ui/kotor_dock.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")


var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://script_compile_install_test")
	DirAccess.make_dir_recursive_absolute(_install_root)
	call_deferred("_run_tests")


func _run_tests() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()

	var controller := KotorWorkspaceController.new(state)
	var dock := KotorDock.new()
	dock.setup(state, controller.mutation_service)
	dock._skip_preflight_for_testing = true
	root.add_child(dock)
	dock._ready()

	_test_install_button_disabled_without_script(dock)
	_test_nss_install_still_works(dock, state)
	_test_ncs_bytes_install(dock, state)
	_test_ncs_override_name_ignores_cache_timestamp(dock)

	_cleanup()
	print("✓ Script compile install tests passed")
	quit()


func _test_install_button_disabled_without_script(dock: KotorDock) -> void:
	dock._script_file_name = ""
	dock._script_bytes = PackedByteArray()
	dock._refresh_script_tool_buttons()
	assert(dock._script_install_btn != null)
	assert(dock._script_install_btn.disabled)


func _test_nss_install_still_works(dock: KotorDock, state: KotorEditorState) -> void:
	dock._load_script_bytes(
		"mod_script.nss",
		"void main() {}\n".to_ascii_buffer(),
		"nss"
	)
	dock._refresh_script_tool_buttons()
	assert(not dock._script_install_btn.disabled)
	dock._install_script_to_override()
	var override_path: String = str(state.gamefs.ensure_override_path()).path_join("mod_script.nss")
	assert(FileAccess.file_exists(override_path))
	var file := FileAccess.open(override_path, FileAccess.READ)
	assert(file != null)
	assert(file.get_as_text() == "void main() {}\n")
	file.close()
	DirAccess.remove_absolute(override_path)


func _test_ncs_bytes_install(dock: KotorDock, state: KotorEditorState) -> void:
	var ncs_bytes := PackedByteArray([0x4E, 0x43, 0x53, 0x20, 0x01, 0x02])
	dock._load_script_bytes("mod_script.ncs", ncs_bytes, "ncs")
	dock._refresh_script_tool_buttons()
	assert(dock._script_install_btn.text == "Install NCS to Override")
	assert(not dock._script_install_btn.disabled)
	dock._install_script_to_override()
	var override_path: String = str(state.gamefs.ensure_override_path()).path_join("mod_script.ncs")
	assert(FileAccess.file_exists(override_path))
	var file := FileAccess.open(override_path, FileAccess.READ)
	assert(file != null)
	assert(file.get_buffer(file.get_length()) == ncs_bytes)
	file.close()
	DirAccess.remove_absolute(override_path)


func _test_ncs_override_name_ignores_cache_timestamp(dock: KotorDock) -> void:
	var ncs_bytes := PackedByteArray([0x4E, 0x43, 0x53, 0x20])
	dock._load_script_bytes("/tmp/kotor_tools_script_tools/mod_script_1847293847.ncs", ncs_bytes, "ncs")
	dock._script_file_name = "mod_script.ncs"
	assert(dock._current_ncs_override_file_name() == "mod_script.ncs")


func _cleanup() -> void:
	for path in [
		_install_root.path_join("override").path_join("mod_script.nss"),
		_install_root.path_join("override").path_join("mod_script.ncs"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for directory in [_install_root.path_join("override"), _install_root]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
