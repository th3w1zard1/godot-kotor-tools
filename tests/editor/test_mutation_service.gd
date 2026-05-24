@tool
extends SceneTree

const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://mutation_service_install")
	DirAccess.make_dir_recursive_absolute(_install_root)
	call_deferred("_assert_mutation_service")


func _assert_mutation_service() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()
	var service := KotorMutationService.new()

	var preview_create := service.preview_install_to_override(state.gamefs, "test_script.nss", "void main() {}\n")
	assert(preview_create.get("ok", false))
	assert(preview_create.get("action", "") == "create")

	var install_create := service.apply_install_to_override(state.gamefs, "test_script.nss", "void main() {}\n")
	assert(install_create.get("applied", false))
	assert(FileAccess.file_exists(_install_root.path_join("override").path_join("test_script.nss")))

	var noop_result := service.apply_install_to_override(state.gamefs, "test_script.nss", "void main() {}\n")
	assert(noop_result.get("action", "") == "noop")

	var overwrite_preview := service.preview_install_to_override(state.gamefs, "test_script.nss", "void main() { SpeakString(\"hi\"); }\n")
	assert(overwrite_preview.get("action", "") == "overwrite")
	assert(overwrite_preview.get("rollback_available", false))

	var overwrite_result := service.apply_install_to_override(state.gamefs, "test_script.nss", "void main() { SpeakString(\"hi\"); }\n")
	assert(overwrite_result.get("applied", false))
	assert(str((overwrite_result.get("transaction", {}) as Dictionary).get("id", "")) != "")

	var export_path := _install_root.path_join("exports").path_join("copy.nss")
	var export_result := service.apply_export_to_path(export_path, "void main() { }\n")
	assert(export_result.get("applied", false))
	assert(FileAccess.file_exists(export_path))

	var remove_preview := service.preview_remove_override(state.gamefs, "test_script.nss")
	assert(remove_preview.get("action", "") == "remove")
	var remove_result := service.apply_remove_override(state.gamefs, "test_script.nss")
	assert(remove_result.get("applied", false))
	assert(not FileAccess.file_exists(_install_root.path_join("override").path_join("test_script.nss")))

	_cleanup()
	quit()


func _cleanup() -> void:
	for path in [
		_install_root.path_join("override").path_join("test_script.nss"),
		_install_root.path_join("override").path_join("test_script.nss.bak"),
		_install_root.path_join("exports").path_join("copy.nss"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for directory in [
		_install_root.path_join("override"),
		_install_root.path_join("exports"),
		_install_root,
	]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
