@tool
extends SceneTree

const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")

var _install_root := ""
var _target_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://transaction_restore_install")
	_target_path = _install_root.path_join("override").path_join("restore_script.nss")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_assert_restore")


func _assert_restore() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()
	var service := KotorMutationService.new()

	assert(KotorModdingPipeline.export_payload_to_path(_target_path, "void main() { SpeakString(\"before\"); }\n", "restore_script.nss").get("ok", false))
	var install_result := service.apply_install_to_override(state.gamefs, "restore_script.nss", "void main() { SpeakString(\"after\"); }\n")
	var transaction: Dictionary = install_result.get("transaction", {})
	assert(str(transaction.get("id", "")) != "")

	var restore_result := service.restore_transaction(str(transaction.get("id", "")))
	assert(restore_result.get("ok", false))
	assert(KotorModdingPipeline.read_file_bytes(_target_path).get_string_from_ascii().contains("before"))

	var second_install := service.apply_install_to_override(state.gamefs, "restore_script.nss", "void main() { SpeakString(\"new\"); }\n")
	var second_transaction: Dictionary = second_install.get("transaction", {})
	assert(KotorModdingPipeline.write_bytes(_target_path, "void main() { SpeakString(\"manual\"); }\n".to_ascii_buffer()) == OK)
	var conflict_result := service.restore_transaction(str(second_transaction.get("id", "")))
	assert(conflict_result.get("status", "") == "conflict")

	_cleanup()
	quit()


func _cleanup() -> void:
	for path in [
		_target_path,
		_target_path + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for directory in [
		_install_root.path_join("override"),
		_install_root,
	]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
