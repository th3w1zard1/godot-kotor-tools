@tool
extends Control

const KotorEditorShell := preload("../../editor/shell/kotor_editor_shell.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTargetContext := preload("../../editor/workspace/kotor_target_context.gd")
const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorModdingPipeline := preload("../../editor/modding/kotor_modding_pipeline.gd")
const KotorDLGWorkspaceEditor := preload("./editors/dlg_workspace_editor.gd")
const KotorTwoDaWorkspaceEditor := preload("./editors/twoda_workspace_editor.gd")
const KotorTLKWorkspaceEditor := preload("./editors/tlk_workspace_editor.gd")
const KotorScriptWorkspaceEditor := preload("./editors/script_workspace_editor.gd")
const KotorGFFWorkspaceEditor := preload("./editors/gff_workspace_editor.gd")
const KotorModuleDesignerWorkspaceEditor := preload("./editors/module_designer_workspace_editor.gd")
const KotorIndoorBuilderWorkspaceEditor := preload("./editors/indoor_builder_workspace_editor.gd")
const KotorResourceBrowserPanel := preload("./panels/resource_browser_panel.gd")
const KotorTransactionHistoryPanel := preload("./panels/transaction_history_panel.gd")

var _controller: RefCounted
var _tabs: TabContainer
var _target_context: RefCounted
var _mutation_service: RefCounted
var _resource_browser: Control
var _transaction_history: Control
var _shell: Control
var _dlg_editor: Control
var _twoda_editor: Control
var _tlk_editor: Control
var _script_editor: Control
var _gff_editor: Control
var _module_designer: Control
var _indoor_builder: Control


func _init(controller: RefCounted = null) -> void:
	_controller = controller
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(controller: RefCounted) -> void:
	_controller = controller
	if is_node_ready():
		_ensure_shell()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ensure_shell()


func _ensure_shell() -> void:
	if _tabs != null:
		return
	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_tabs)

	_target_context = KotorTargetContext.new().setup(_resolve_editor_state(), _controller)
	if _controller != null:
		_mutation_service = _controller.get("mutation_service")
	if _mutation_service == null:
		_mutation_service = KotorMutationService.new()

	_resource_browser = KotorResourceBrowserPanel.new()
	_resource_browser.name = "Resources"
	_resource_browser.setup(_target_context)
	_resource_browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_resource_browser.resource_requested.connect(_open_workspace_entry)
	_resource_browser.install_requested.connect(_on_resource_browser_install)
	_resource_browser.compare_requested.connect(_on_resource_browser_compare)
	_resource_browser.export_requested.connect(_on_resource_browser_export)
	_tabs.add_child(_resource_browser)

	_transaction_history = KotorTransactionHistoryPanel.new()
	_transaction_history.name = "Transactions"
	_transaction_history.setup(_controller)
	_transaction_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transaction_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_transaction_history.restore_completed.connect(_on_restore_completed)
	_tabs.add_child(_transaction_history)

	_shell = KotorEditorShell.new()
	_shell.name = "Legacy Workspace"
	_shell.setup(_resolve_editor_state(), _mutation_service)
	_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_shell)
	_wire_legacy_dock_workspace_routing()

	_dlg_editor = KotorDLGWorkspaceEditor.new()
	_dlg_editor.name = "DLG Pilot"
	_dlg_editor.setup(_resolve_editor_state(), _controller)
	_dlg_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dlg_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_dlg_editor)

	_twoda_editor = KotorTwoDaWorkspaceEditor.new()
	_twoda_editor.name = "2DA Editor"
	_twoda_editor.setup(_resolve_editor_state(), _controller)
	_twoda_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_twoda_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_twoda_editor)

	_tlk_editor = KotorTLKWorkspaceEditor.new()
	_tlk_editor.name = "TLK Editor"
	_tlk_editor.setup(_resolve_editor_state(), _controller)
	_tlk_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tlk_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_tlk_editor)

	_script_editor = KotorScriptWorkspaceEditor.new()
	_script_editor.name = "Script Editor"
	_script_editor.setup(_resolve_editor_state(), _controller)
	_script_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_script_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_script_editor)

	_gff_editor = KotorGFFWorkspaceEditor.new()
	_gff_editor.name = "GFF Entity Editor"
	_gff_editor.setup(_resolve_editor_state(), _controller)
	_gff_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gff_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_gff_editor)

	_module_designer = KotorModuleDesignerWorkspaceEditor.new()
	_module_designer.name = "Module Designer"
	_module_designer.setup(_resolve_editor_state(), _controller)
	_module_designer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_module_designer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_module_designer)

	_indoor_builder = KotorIndoorBuilderWorkspaceEditor.new()
	_indoor_builder.name = "Indoor Builder"
	_indoor_builder.setup(_resolve_editor_state(), _controller)
	_indoor_builder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_indoor_builder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_indoor_builder)
	_restore_workspace_session()


func _resolve_editor_state() -> RefCounted:
	if _controller != null:
		var controller_state = _controller.get("editor_state")
		if controller_state != null:
			return controller_state
	var fallback := KotorEditorState.new()
	fallback.load_settings()
	return fallback


func get_editor_shell() -> Control:
	return _shell


func get_dlg_workspace_editor() -> Control:
	return _dlg_editor


func get_resource_browser() -> Control:
	return _resource_browser


func get_transaction_history_panel() -> Control:
	return _transaction_history


func get_mutation_service() -> RefCounted:
	return _mutation_service


func get_twoda_workspace_editor() -> Control:
	return _twoda_editor


func get_tlk_workspace_editor() -> Control:
	return _tlk_editor


func get_script_workspace_editor() -> Control:
	return _script_editor


func get_gff_workspace_editor() -> Control:
	return _gff_editor


func get_module_designer_workspace_editor() -> Control:
	return _module_designer


func get_indoor_builder_workspace_editor() -> Control:
	return _indoor_builder


func _restore_workspace_session() -> void:
	if _controller == null or _dlg_editor == null or not _controller.has_method("restore_workspace_session"):
		return
	var state: Dictionary = _controller.call("restore_workspace_session")
	var active_key := str(state.get("active_key", ""))
	var documents = state.get("documents", [])
	if typeof(documents) != TYPE_ARRAY:
		return
	for entry in documents:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var document_entry: Dictionary = entry
		var source_path := str(document_entry.get("source_path", ""))
		if source_path.is_empty():
			continue
		if not FileAccess.file_exists(source_path):
			if _controller.has_method("register_missing_session_entry"):
				_controller.call("register_missing_session_entry", document_entry)
			continue
		match str(document_entry.get("editor_kind", "")):
			"dlg":
				_dlg_editor.call("open_dlg_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _dlg_editor.get_index()
			"twoda":
				_twoda_editor.call("open_2da_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _twoda_editor.get_index()
			"tlk":
				_tlk_editor.call("open_tlk_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _tlk_editor.get_index()
			"script":
				_script_editor.call("open_script_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _script_editor.get_index()
			"gff":
				_gff_editor.call("open_gff_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _gff_editor.get_index()
			"module":
				_module_designer.call("open_git_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _module_designer.get_index()
			"indoor":
				_indoor_builder.call("open_indoor_file", source_path)
				if str(document_entry.get("key", "")) == active_key:
					_tabs.current_tab = _indoor_builder.get_index()
			_:
				pass


func _wire_legacy_dock_workspace_routing() -> void:
	if _shell == null or not _shell.has_method("get_dock"):
		return
	var dock: Control = _shell.call("get_dock")
	if dock != null and dock.has_method("set_workspace_entry_opener"):
		dock.call("set_workspace_entry_opener", Callable(self, "_open_workspace_entry"))


func _open_workspace_entry(entry: Dictionary) -> void:
	if entry.is_empty() or _target_context == null:
		return
	var extension := str(entry.get("extension", "")).to_lower()
	var absolute_path := str(entry.get("absolute_path", ""))
	var source_path := absolute_path if absolute_path.get_extension().to_lower() == extension else ""
	if extension == "dlg":
		var bytes: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		var label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		_dlg_editor.call("open_dlg_bytes", label, bytes, source_path)
		_tabs.current_tab = _dlg_editor.get_index()
		return
	if extension == "2da":
		var twoda_bytes: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		var twoda_label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		_twoda_editor.call("open_2da_bytes", twoda_label, twoda_bytes, source_path)
		_tabs.current_tab = _twoda_editor.get_index()
		return
	if extension == "tlk":
		var tlk_bytes: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		var tlk_label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		_tlk_editor.call("open_tlk_bytes", tlk_label, tlk_bytes, source_path)
		_tabs.current_tab = _tlk_editor.get_index()
		return
	if extension == "nss" or extension == "ncs":
		var script_bytes: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		var script_label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		_script_editor.call("open_script_bytes", script_label, script_bytes, extension, source_path)
		_tabs.current_tab = _script_editor.get_index()
		return
	if KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed(extension):
		var git_bytes: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		var git_label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		_module_designer.call("open_git_bytes", git_label, git_bytes, source_path)
		_tabs.current_tab = _module_designer.get_index()
		return
	if KotorGFFWorkspaceEditor.workspace_gff_extension_allowed(extension):
		var gff_bytes: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		var gff_label := "%s [%s]" % [
			"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
			entry.get("source", ""),
		]
		_gff_editor.call("open_gff_bytes", gff_label, gff_bytes, source_path)
		_tabs.current_tab = _gff_editor.get_index()
		return
	if _shell != null and _shell.has_method("open_gamefs_entry"):
		_shell.call("open_gamefs_entry", entry)
		_tabs.current_tab = _shell.get_index()


func _on_restore_completed(result: Dictionary) -> void:
	if not result.get("ok", false):
		return
	var editor_state := _resolve_editor_state()
	if editor_state != null and editor_state.has_method("refresh_gamefs"):
		editor_state.call("refresh_gamefs")


func _on_resource_browser_install(entry: Dictionary) -> void:
	if _mutation_service == null or entry.is_empty():
		return
	var editor_state := _resolve_editor_state()
	if editor_state == null:
		return
	var gamefs = editor_state.get("gamefs")
	if gamefs == null:
		return
	var file_name := "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]
	var payload: PackedByteArray = _target_context.call("load_entry_bytes", entry)
	var result: Dictionary = _mutation_service.apply_install_to_override(gamefs, file_name, payload, true)
	if result.get("ok", false):
		editor_state.call("refresh_gamefs")
	_resource_browser.call("_set_detail_text", result.get("message", "Install failed"))


func _on_resource_browser_compare(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var editor_state := _resolve_editor_state()
	if editor_state == null:
		return
	var gamefs = editor_state.get("gamefs")
	if gamefs == null:
		return
	var result: Dictionary = KotorModdingPipeline.compare_gamefs_resource(
		gamefs,
		str(entry.get("resref", "")),
		int(entry.get("resource_type", -1))
	)
	var detail: String = str(result.get("message", "Compare unavailable"))
	if result.has("details"):
		detail += "\n" + str(result.get("details", ""))
	_resource_browser.call("_set_detail_text", detail)


func _on_resource_browser_export(entry: Dictionary) -> void:
	if entry.is_empty() or not Engine.is_editor_hint():
		return
	var file_name := "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.title = "Export %s" % file_name
	dialog.current_file = file_name
	dialog.file_selected.connect(func(path: String) -> void:
		var payload: PackedByteArray = _target_context.call("load_entry_bytes", entry)
		KotorModdingPipeline.export_payload_to_path(path, payload, file_name)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)

