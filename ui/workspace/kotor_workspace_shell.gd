@tool
extends Control

const KotorEditorShell := preload("../../editor/shell/kotor_editor_shell.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTargetContext := preload("../../editor/workspace/kotor_target_context.gd")
const KotorMutationService := preload("../../editor/transactions/kotor_mutation_service.gd")
const KotorDLGWorkspaceEditor := preload("./editors/dlg_workspace_editor.gd")
const KotorTwoDaWorkspaceEditor := preload("./editors/twoda_workspace_editor.gd")
const KotorTLKWorkspaceEditor := preload("./editors/tlk_workspace_editor.gd")
const KotorScriptWorkspaceEditor := preload("./editors/script_workspace_editor.gd")
const KotorResourceBrowserPanel := preload("./panels/resource_browser_panel.gd")

var _controller: RefCounted
var _tabs: TabContainer
var _target_context: RefCounted
var _mutation_service: RefCounted
var _resource_browser: Control
var _shell: Control
var _dlg_editor: Control
var _twoda_editor: Control
var _tlk_editor: Control
var _script_editor: Control


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
	_tabs.add_child(_resource_browser)

	_shell = KotorEditorShell.new()
	_shell.name = "Legacy Workspace"
	_shell.setup(_resolve_editor_state())
	_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_shell)

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


func get_mutation_service() -> RefCounted:
	return _mutation_service


func get_twoda_workspace_editor() -> Control:
	return _twoda_editor


func get_tlk_workspace_editor() -> Control:
	return _tlk_editor


func get_script_workspace_editor() -> Control:
	return _script_editor


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
			_:
				pass


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
	if _shell != null and _shell.has_method("open_gamefs_entry"):
		_shell.call("open_gamefs_entry", entry)
		_tabs.current_tab = _shell.get_index()
