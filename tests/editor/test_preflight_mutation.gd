@tool
extends SceneTree

const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")

var _install_root := ""
var _target_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://preflight_mutation_install")
	_target_path = _install_root.path_join("override").path_join("preflight_script.nss")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_assert_preflight_contract")


func _assert_preflight_contract() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()
	var service := KotorMutationService.new()

	var preview: Dictionary = service.preview_install_to_override(
		state.gamefs,
		"preflight_script.nss",
		"void main() { SpeakString(\"new\"); }\n"
	)
	assert(preview.get("ok", false))
	assert(preview.get("action", "") == "create")

	var cancelled: Dictionary = service.apply_install_to_override(
		state.gamefs,
		"preflight_script.nss",
		"void main() { SpeakString(\"new\"); }\n",
		false
	)
	assert(not cancelled.get("applied", false))
	assert(not FileAccess.file_exists(_target_path))

	var applied: Dictionary = service.apply_install_to_override(
		state.gamefs,
		"preflight_script.nss",
		"void main() { SpeakString(\"new\"); }\n",
		true
	)
	assert(applied.get("applied", false))
	assert(FileAccess.file_exists(_target_path))

	var noop_preview: Dictionary = service.preview_install_to_override(
		state.gamefs,
		"preflight_script.nss",
		"void main() { SpeakString(\"new\"); }\n"
	)
	assert(noop_preview.get("action", "") == "noop")

	_cleanup()
	quit()


func _cleanup() -> void:
	if FileAccess.file_exists(_target_path):
		DirAccess.remove_absolute(_target_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
