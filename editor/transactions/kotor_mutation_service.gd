@tool
extends RefCounted
class_name KotorMutationService

const KotorModdingPipeline := preload("../modding/kotor_modding_pipeline.gd")
const KotorTransactionStore := preload("kotor_transaction_store.gd")

var _transaction_store: KotorTransactionStore


func _init(transaction_store: KotorTransactionStore = null) -> void:
	_transaction_store = transaction_store if transaction_store != null else KotorTransactionStore.new()


func get_transaction_store() -> KotorTransactionStore:
	return _transaction_store


func preview_install_to_override(gamefs: RefCounted, file_name: String, payload: Variant) -> Dictionary:
	if gamefs == null:
		return _invalid_result("install", "Game install is not available")
	file_name = file_name.get_file()
	if file_name.is_empty():
		return _invalid_result("install", "A target file name is required")
	var override_dir: String = gamefs.ensure_override_path()
	if override_dir.is_empty():
		return _invalid_result("install", "Could not create the override directory")
	var target_path: String = override_dir.path_join(file_name)
	return _preview_mutation("install", target_path, file_name, payload)


func apply_install_to_override(gamefs: RefCounted, file_name: String, payload: Variant, proceed: bool = true) -> Dictionary:
	var preview := preview_install_to_override(gamefs, file_name, payload)
	if not preview.get("ok", false) or not proceed:
		preview["applied"] = false
		return preview
	if preview.get("action", "") == "noop":
		preview["applied"] = false
		return preview
	var result: Dictionary = KotorModdingPipeline.install_payload_to_override(gamefs, file_name, payload)
	return _finalize_mutation("install", preview, result)


func preview_export_to_path(target_path: String, payload: Variant) -> Dictionary:
	return _preview_mutation("export", target_path, target_path.get_file(), payload)


func apply_export_to_path(target_path: String, payload: Variant, proceed: bool = true) -> Dictionary:
	var preview := preview_export_to_path(target_path, payload)
	if not preview.get("ok", false) or not proceed:
		preview["applied"] = false
		return preview
	if preview.get("action", "") == "noop":
		preview["applied"] = false
		return preview
	var result: Dictionary = KotorModdingPipeline.export_payload_to_path(target_path, payload, target_path.get_file())
	return _finalize_mutation("export", preview, result)


func preview_remove_override(gamefs: RefCounted, file_name: String) -> Dictionary:
	if gamefs == null:
		return _invalid_result("remove", "Game install is not available")
	var override_dir: String = gamefs.ensure_override_path()
	if override_dir.is_empty():
		return _invalid_result("remove", "Could not create the override directory")
	var target_path: String = override_dir.path_join(file_name.get_file())
	if not FileAccess.file_exists(target_path):
		return {
			"ok": true,
			"kind": "remove",
			"action": "noop",
			"target_path": target_path,
			"file_name": file_name.get_file(),
			"rollback_available": false,
			"message": "%s is already absent" % file_name.get_file(),
		}
	var before_bytes := KotorModdingPipeline.read_file_bytes(target_path)
	return {
		"ok": true,
		"kind": "remove",
		"action": "remove",
		"target_path": target_path,
		"file_name": file_name.get_file(),
		"rollback_available": true,
		"rollback_mode": "restore_bytes",
		"before_bytes": before_bytes,
		"after_bytes": PackedByteArray(),
		"target_exists_after": false,
		"message": "Will remove %s" % file_name.get_file(),
	}


func apply_remove_override(gamefs: RefCounted, file_name: String, proceed: bool = true) -> Dictionary:
	var preview := preview_remove_override(gamefs, file_name)
	if not preview.get("ok", false) or not proceed:
		preview["applied"] = false
		return preview
	if preview.get("action", "") == "noop":
		preview["applied"] = false
		return preview
	var target_path := str(preview.get("target_path", ""))
	var remove_err := DirAccess.remove_absolute(target_path)
	var result := {
		"ok": remove_err == OK,
		"status": "written" if remove_err == OK else "io_error",
		"message": "Removed %s" % target_path.get_file() if remove_err == OK else "Failed to remove %s" % target_path.get_file(),
		"target_path": target_path,
		"backup_path": "",
	}
	return _finalize_mutation("remove", preview, result)


func restore_transaction(transaction_id: String) -> Dictionary:
	var transaction := _transaction_store.get_transaction(transaction_id)
	if transaction.is_empty():
		return _invalid_result("restore", "Unknown transaction %s" % transaction_id)
	if not bool(transaction.get("rollback_available", false)):
		return _invalid_result("restore", "Rollback is not available for %s" % transaction_id)
	var target_path := str(transaction.get("target_path", ""))
	var current_bytes := KotorModdingPipeline.read_file_bytes(target_path)
	var after_bytes: PackedByteArray = transaction.get("after_bytes", PackedByteArray())
	if FileAccess.file_exists(target_path) != bool(transaction.get("target_exists_after", false)) or not KotorModdingPipeline.bytes_equal(current_bytes, after_bytes):
		return {
			"ok": false,
			"kind": "restore",
			"status": "conflict",
			"message": "Cannot restore %s because the target changed again." % target_path.get_file(),
			"target_path": target_path,
		}
	var rollback_mode := str(transaction.get("rollback_mode", ""))
	if rollback_mode == "delete_created":
		var remove_err := DirAccess.remove_absolute(target_path)
		return {
			"ok": remove_err == OK,
			"kind": "restore",
			"status": "restored" if remove_err == OK else "io_error",
			"message": "Restored %s" % target_path.get_file() if remove_err == OK else "Failed to restore %s" % target_path.get_file(),
			"target_path": target_path,
		}
	var before_bytes: PackedByteArray = transaction.get("before_bytes", PackedByteArray())
	var write_err := KotorModdingPipeline.write_bytes(target_path, before_bytes)
	return {
		"ok": write_err == OK,
		"kind": "restore",
		"status": "restored" if write_err == OK else "io_error",
		"message": "Restored %s" % target_path.get_file() if write_err == OK else "Failed to restore %s" % target_path.get_file(),
		"target_path": target_path,
	}


func _preview_mutation(kind: String, target_path: String, file_name: String, payload: Variant) -> Dictionary:
	if target_path.is_empty() or not target_path.is_absolute_path():
		return _invalid_result(kind, "Target path must be absolute")
	var serialized := KotorModdingPipeline.serialize_payload(file_name, payload)
	if not serialized.get("ok", false):
		return serialized
	var before_exists := FileAccess.file_exists(target_path)
	var before_bytes := KotorModdingPipeline.read_file_bytes(target_path)
	var after_bytes: PackedByteArray = serialized.get("payload", PackedByteArray())
	var action := "create"
	var rollback_mode := "delete_created"
	if before_exists:
		if KotorModdingPipeline.bytes_equal(before_bytes, after_bytes):
			action = "noop"
			rollback_mode = ""
		else:
			action = "overwrite"
			rollback_mode = "restore_bytes"
	var rollback_available := action == "create" or action == "overwrite"
	var message := "Will create %s" % file_name
	if action == "overwrite":
		message = "Will overwrite %s" % file_name
	elif action == "noop":
		message = "%s is already up to date" % file_name
	return {
		"ok": true,
		"kind": kind,
		"action": action,
		"target_path": target_path,
		"file_name": file_name,
		"rollback_available": rollback_available,
		"rollback_mode": rollback_mode,
		"before_bytes": before_bytes,
		"after_bytes": after_bytes,
		"target_exists_after": action != "remove",
		"message": message,
	}


func _finalize_mutation(kind: String, preview: Dictionary, result: Dictionary) -> Dictionary:
	var envelope := preview.duplicate(true)
	envelope["kind"] = kind
	envelope["result"] = result
	envelope["applied"] = result.get("ok", false)
	envelope["message"] = String(result.get("message", preview.get("message", "")))
	if not result.get("ok", false) or preview.get("action", "") == "noop":
		return envelope
	var transaction := _transaction_store.record_transaction({
		"kind": kind,
		"action": preview.get("action", ""),
		"target_path": preview.get("target_path", ""),
		"file_name": preview.get("file_name", ""),
		"rollback_available": preview.get("rollback_available", false),
		"rollback_mode": preview.get("rollback_mode", ""),
		"before_bytes": preview.get("before_bytes", PackedByteArray()),
		"after_bytes": preview.get("after_bytes", PackedByteArray()),
		"target_exists_after": preview.get("target_exists_after", true),
	})
	envelope["transaction"] = transaction
	return envelope


func _invalid_result(kind: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"kind": kind,
		"status": "invalid",
		"message": message,
	}
