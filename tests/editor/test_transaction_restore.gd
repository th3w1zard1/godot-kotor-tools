@tool
extends SceneTree

const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorTransactionStore := preload("../../editor/transactions/kotor_transaction_store.gd")
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
	assert(transaction.get("action", "") == "overwrite")
	assert(transaction.get("restore_eligible", false) == true)

	var restore_result := service.restore_transaction(str(transaction.get("id", "")))
	assert(restore_result.get("ok", false))
	assert(KotorModdingPipeline.read_file_bytes(_target_path).get_string_from_ascii().contains("before"))

	var second_install := service.apply_install_to_override(state.gamefs, "restore_script.nss", "void main() { SpeakString(\"new\"); }\n")
	var second_transaction: Dictionary = second_install.get("transaction", {})
	assert(KotorModdingPipeline.write_bytes(_target_path, "void main() { SpeakString(\"manual\"); }\n".to_ascii_buffer()) == OK)
	var conflict_result := service.restore_transaction(str(second_transaction.get("id", "")))
	assert(conflict_result.get("status", "") == "conflict")
	
	# Verify transaction history is properly maintained with metadata
	var store = service.get_transaction_store()
	var all_txs = store.list_transactions()
	assert(all_txs.size() >= 2, "Expected at least 2 transactions")
	
	# Verify metadata list is queryable without full payloads
	var metadata = store.get_transactions_for_session()
	assert(metadata.size() >= 2)
	for tx_meta in metadata:
		assert(tx_meta.has("id"))
		assert(tx_meta.has("action"))
		assert(tx_meta.has("status"))
		assert(tx_meta.has("restore_eligible"))
		# These fields must be present for UI but not payloads
		assert(tx_meta.has("target_path"))
		assert(tx_meta.has("file_name"))
		assert(not tx_meta.has("before_bytes"))
		assert(not tx_meta.has("after_bytes"))

	var editor_settings := EditorInterface.get_editor_settings()
	if Engine.is_editor_hint() and editor_settings != null:
		# History should be readable on a new store instance without requiring a new write first.
		editor_settings.set_setting(
			KotorTransactionStore.TRANSACTIONS_SETTINGS_KEY,
			JSON.stringify([
				{
					"id": "tx-0100",
					"kind": "install",
					"action": "overwrite",
					"target_path": _target_path,
					"file_name": "restore_script.nss",
					"rollback_available": true,
					"rollback_mode": "restore_bytes",
					"status": "applied",
					"restore_eligible": true,
					"timestamp": 123456,
				},
			])
		)
		var persisted_store := KotorTransactionStore.new()
		assert(not persisted_store.get_transaction("tx-0100").is_empty())
		assert(persisted_store.list_transactions().size() == 1)

		# Clearing history should persist so stale transactions do not reappear.
		persisted_store.clear_transactions()
		var persisted_value := String(editor_settings.get_setting(KotorTransactionStore.TRANSACTIONS_SETTINGS_KEY))
		var parsed = JSON.parse_string(persisted_value)
		assert(parsed is Array)
		assert((parsed as Array).is_empty())

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
