@tool
extends SceneTree

const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTransactionHistoryPanel := preload("../../ui/workspace/panels/transaction_history_panel.gd")
const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")

var _install_root := ""
var _target_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://transaction_history_panel_install")
	_target_path = _install_root.path_join("override").path_join("history_script.nss")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_assert_history_panel")


func _assert_history_panel() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(state)
	var panel := KotorTransactionHistoryPanel.new()
	panel.setup(controller)
	root.add_child(panel)

	assert(KotorModdingPipeline.export_payload_to_path(_target_path, "void main() {}\n", "history_script.nss").get("ok", false))
	var install_result: Dictionary = controller.mutation_service.apply_install_to_override(
		state.gamefs,
		"history_script.nss",
		"void main() { SpeakString(\"v1\"); }\n"
	)
	assert(install_result.get("applied", false))

	panel.refresh_transactions()
	assert(panel.get_transaction_count() >= 1)

	var transaction_id := str(install_result.get("transaction", {}).get("id", ""))
	assert(not transaction_id.is_empty())

	var restore_result: Dictionary = controller.restore_transaction_from_history(transaction_id)
	assert(restore_result.get("ok", false))
	assert(KotorModdingPipeline.read_file_bytes(_target_path).get_string_from_ascii().contains("void main() {}"))

	panel.refresh_transactions()
	assert(panel._list.item_count >= 1)

	_cleanup()
	quit()


func _cleanup() -> void:
	if FileAccess.file_exists(_target_path):
		DirAccess.remove_absolute(_target_path)
	if DirAccess.dir_exists_absolute(_install_root.path_join("override")):
		DirAccess.remove_absolute(_install_root.path_join("override"))
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
