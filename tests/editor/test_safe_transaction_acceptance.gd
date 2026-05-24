@tool
extends SceneTree

const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")

var _install_root := ""
var _target_path := ""
var _override_dir := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://safe_transaction_acceptance")
	_override_dir = _install_root.path_join("override")
	_target_path = _override_dir.path_join("acceptance_script.nss")
	DirAccess.make_dir_recursive_absolute(_override_dir)
	call_deferred("_assert_acceptance_examples")


func _assert_acceptance_examples() -> void:
	var state := KotorEditorState.new()
	state.game_path = _install_root
	state.refresh_gamefs()
	var service := KotorMutationService.new()
	var controller := KotorWorkspaceController.new(state)

	_assert_ae1_create_cancel(service, state)
	_assert_ae2_overwrite_records_transaction(service, state)
	_assert_ae3_restore_from_history(controller, state)
	_assert_ae4_backup_failure_blocks_apply(service, state)
	_assert_ae5_install_visible_in_workspace(controller, state)
	_assert_mixed_transaction_timeline(service, state)

	_cleanup()
	quit()


func _assert_ae1_create_cancel(service: RefCounted, state: RefCounted) -> void:
	var preview: Dictionary = service.preview_install_to_override(
		state.gamefs,
		"acceptance_script.nss",
		"void main() { SpeakString(\"ae1\"); }\n"
	)
	assert(preview.get("action", "") == "create")
	assert(preview.get("rollback_available", false))

	var cancelled: Dictionary = service.apply_install_to_override(
		state.gamefs,
		"acceptance_script.nss",
		"void main() { SpeakString(\"ae1\"); }\n",
		false
	)
	assert(not cancelled.get("applied", false))
	assert(not FileAccess.file_exists(_target_path))


func _assert_ae2_overwrite_records_transaction(service: RefCounted, state: RefCounted) -> void:
	assert(
		KotorModdingPipeline.export_payload_to_path(_target_path, "void main() {}\n", "acceptance_script.nss").get("ok", false)
	)

	var preview: Dictionary = service.preview_install_to_override(
		state.gamefs,
		"acceptance_script.nss",
		"void main() { SpeakString(\"ae2\"); }\n"
	)
	assert(preview.get("action", "") == "overwrite")
	assert(preview.get("rollback_available", false))

	var applied: Dictionary = service.apply_install_to_override(
		state.gamefs,
		"acceptance_script.nss",
		"void main() { SpeakString(\"ae2\"); }\n"
	)
	assert(applied.get("applied", false))
	var transaction: Dictionary = applied.get("transaction", {})
	assert(str(transaction.get("id", "")) != "")
	assert(transaction.get("action", "") == "overwrite")
	assert(transaction.get("rollback_available", false) == true)
	assert(transaction.get("rollback_mode", "") == "restore_bytes")
	assert(KotorModdingPipeline.read_file_bytes(_target_path).get_string_from_ascii().contains("ae2"))


func _assert_ae3_restore_from_history(controller: RefCounted, state: RefCounted) -> void:
	var install_result: Dictionary = controller.mutation_service.apply_install_to_override(
		state.gamefs,
		"acceptance_script.nss",
		"void main() { SpeakString(\"ae3-after\"); }\n"
	)
	var transaction_id := str(install_result.get("transaction", {}).get("id", ""))
	assert(not transaction_id.is_empty())

	var restore_result: Dictionary = controller.restore_transaction_from_history(transaction_id)
	assert(restore_result.get("ok", false))

	var history: Array = controller.list_transactions()
	assert(history.size() >= 1)
	var latest: Dictionary = history[history.size() - 1]
	assert(str(latest.get("id", "")) == transaction_id)
	assert(latest.get("restore_eligible", false) == true)


func _assert_ae4_backup_failure_blocks_apply(service: RefCounted, state: RefCounted) -> void:
	var ae4_path := _override_dir.path_join("ae4_backup_script.nss")
	assert(
		KotorModdingPipeline.export_payload_to_path(ae4_path, "void main() { SpeakString(\"before\"); }\n", "ae4_backup_script.nss").get("ok", false)
	)
	var backup_path := ae4_path + ".bak"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	DirAccess.make_dir_recursive_absolute(backup_path)

	var blocked: Dictionary = service.apply_install_to_override(
		state.gamefs,
		"ae4_backup_script.nss",
		"void main() { SpeakString(\"blocked\"); }\n"
	)

	if DirAccess.dir_exists_absolute(backup_path):
		DirAccess.remove_absolute(backup_path)

	assert(not blocked.get("applied", false))
	assert(str(blocked.get("status", "")) == "blocked")
	assert(KotorModdingPipeline.read_file_bytes(ae4_path).get_string_from_ascii().contains("before"))
	assert(not blocked.get("transaction", {}))


func _assert_ae5_install_visible_in_workspace(controller: RefCounted, state: RefCounted) -> void:
	var result: Dictionary = controller.mutation_service.apply_install_to_override(
		state.gamefs,
		"acceptance_script.nss",
		"void main() { SpeakString(\"ae5\"); }\n"
	)
	assert(result.get("applied", false))
	assert(FileAccess.file_exists(_target_path))

	state.refresh_gamefs()
	var variants: Array = state.gamefs.list_resource_variants("acceptance_script", "nss")
	var found_override := false
	for variant in variants:
		if str(variant.get("source", "")) == "override":
			found_override = true
			break
	assert(found_override)

	var metadata: Array = controller.list_transactions()
	assert(metadata.size() >= 1)
	var last_tx: Dictionary = metadata[metadata.size() - 1]
	assert(str(last_tx.get("status", "")) != "")
	assert(str(last_tx.get("file_name", "")) == "acceptance_script.nss")


func _assert_mixed_transaction_timeline(service: RefCounted, state: RefCounted) -> void:
	service.apply_install_to_override(state.gamefs, "timeline_a.nss", "void main() {}\n")
	service.apply_install_to_override(state.gamefs, "timeline_b.nss", "void main() { SpeakString(\"b\"); }\n")
	var store = service.get_transaction_store()
	var metadata: Array = store.get_transactions_for_session()
	assert(metadata.size() >= 3)
	var kinds: Array[String] = []
	for entry in metadata:
		kinds.append(str(entry.get("kind", "")))
	assert(kinds.has("install"))


func _cleanup() -> void:
	var backup_path := _target_path + ".bak"
	if DirAccess.dir_exists_absolute(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(_target_path):
		DirAccess.remove_absolute(_target_path)
	var ae4_backup_dir := _override_dir.path_join("ae4_backup_script.nss.bak")
	if DirAccess.dir_exists_absolute(ae4_backup_dir):
		DirAccess.remove_absolute(ae4_backup_dir)
	for extra in ["timeline_a.nss", "timeline_b.nss", "ae4_backup_script.nss"]:
		var path := _override_dir.path_join(extra)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_override_dir):
		DirAccess.remove_absolute(_override_dir)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
