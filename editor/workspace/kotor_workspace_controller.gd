@tool
extends RefCounted
class_name KotorWorkspaceController

const KotorEditorState := preload("../core/kotor_editor_state.gd")
const KotorDocumentRegistry := preload("kotor_document_registry.gd")
const KotorWorkspaceSession := preload("kotor_workspace_session.gd")
const KotorStaleStateRegistry := preload("kotor_stale_state_registry.gd")
const KotorMutationService := preload("../transactions/kotor_mutation_service.gd")

var editor_state: RefCounted
var document_registry: RefCounted
var workspace_session: RefCounted
var stale_state_registry: RefCounted
var mutation_service: RefCounted
var restored_session_state: Dictionary = {}


func _init(state: RefCounted = null) -> void:
	editor_state = state if state != null else KotorEditorState.new()
	if state == null and editor_state.has_method("load_settings"):
		editor_state.load_settings()
	document_registry = KotorDocumentRegistry.new()
	workspace_session = KotorWorkspaceSession.new()
	stale_state_registry = KotorStaleStateRegistry.new()
	mutation_service = KotorMutationService.new()
	restored_session_state = workspace_session.load_state()
	if editor_state.has_signal("gamefs_reindexed"):
		editor_state.gamefs_reindexed.connect(_on_gamefs_reindexed)


func setup(state: RefCounted) -> void:
	editor_state = state if state != null else editor_state
	if editor_state.has_signal("gamefs_reindexed") and not editor_state.gamefs_reindexed.is_connected(_on_gamefs_reindexed):
		editor_state.gamefs_reindexed.connect(_on_gamefs_reindexed)


func register_document(
		editor_kind: String,
		resource: Variant,
		document: Variant,
		source_path: String = "",
		file_name: String = "",
		selection: Dictionary = {}
) -> Dictionary:
	var entry: Dictionary = document_registry.register_document(
		editor_kind,
		resource,
		document,
		source_path,
		file_name,
		selection
	)
	document_registry.activate_document(str(entry.get("key", "")), true)
	persist_session()
	return entry


func update_document_dirty(key: String, dirty: bool) -> void:
	document_registry.update_dirty(key, dirty)
	persist_session()


func update_document_selection(key: String, selection: Dictionary) -> void:
	document_registry.update_selection(key, selection)
	persist_session()


func activate_document(key: String, allow_dirty_switch: bool = false) -> Dictionary:
	var result: Dictionary = document_registry.activate_document(key, allow_dirty_switch)
	persist_session()
	return result


func discard_document(key: String) -> Dictionary:
	var result: Dictionary = document_registry.discard_document(key)
	persist_session()
	return result


func remove_document(key: String) -> void:
	document_registry.remove_document(key)
	persist_session()


func restore_workspace_session() -> Dictionary:
	return restored_session_state.duplicate(true)


func register_missing_session_entry(entry: Dictionary) -> void:
	document_registry.register_missing_entry(entry)
	persist_session()


func persist_session() -> void:
	if workspace_session != null:
		workspace_session.save_registry(document_registry)


func get_transaction_store() -> RefCounted:
	return mutation_service.get_transaction_store()


func list_transactions() -> Array[Dictionary]:
	return mutation_service.get_transaction_store().list_transactions()


func get_transaction_metadata(transaction_id: String) -> Dictionary:
	var store = mutation_service.get_transaction_store()
	var tx = store.get_transaction(transaction_id)
	if tx.is_empty():
		return {}
	return store.get_transactions_for_session().filter(func(t): return t.get("id") == transaction_id)[0] if store.get_transactions_for_session().any(func(t): return t.get("id") == transaction_id) else {}


func restore_transaction_from_history(transaction_id: String) -> Dictionary:
	return mutation_service.restore_transaction(transaction_id)


func _on_gamefs_reindexed(status_text: String) -> void:
	var reason := "Target reindexed: %s" % status_text
	for entry in document_registry.list_documents():
		var key := str(entry.get("key", ""))
		if key.is_empty():
			continue
		stale_state_registry.mark_stale(key, reason)
		document_registry.mark_stale(key, reason)
	persist_session()
