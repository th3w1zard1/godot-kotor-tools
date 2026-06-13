@tool
extends "./kotor_workspace_editor.gd"
class_name KotorSavegameWorkspaceEditor

signal member_open_requested(resref: String, extension: String, payload: PackedByteArray)

const ERFParser := preload("../../../formats/erf_parser.gd")
const SavegameInspector := preload("../../../formats/savegame_inspector.gd")
const SavegameInspectorResource := preload("../../../resources/savegame_inspector_resource.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _metadata_label: Label
var _tree: Tree
var _mutation_service: RefCounted
var _preflight_dialog: KotorPreflightDialog
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_entry_index := -1

var _resource: SavegameInspectorResource
var _parsed_archive: Dictionary = {}
var _source_path := ""
var _file_name := "savegame.sav"
var _status_text := ""
var _document_key := ""
var _skip_preflight_for_testing := false

var _pending_source_path := ""
var _pending_file_name := ""
var _pending_bytes: PackedByteArray = PackedByteArray()


static func savegame_extension_allowed(extension: String) -> bool:
	return extension.strip_edges().to_lower() == "sav"


func _on_workspace_setup() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_mutation_service = _resolve_mutation_service()
	_build_ui()
	if not _pending_bytes.is_empty():
		var pending_bytes := _pending_bytes
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_bytes = PackedByteArray()
		_pending_source_path = ""
		_pending_file_name = ""
		open_save_bytes(pending_file_name, pending_bytes, pending_source_path)


func get_resource() -> SavegameInspectorResource:
	return _resource


func open_save_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_save_bytes(path.get_file(), bytes, path)


func open_save_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	if not is_node_ready():
		_pending_bytes = data
		_pending_source_path = source_path
		_pending_file_name = label
		return
	_parsed_archive = ERFParser.parse_bytes(data)
	if _parsed_archive.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "savegame.sav"))
		return
	_resource = SavegameInspectorResource.from_bytes(
		data,
		source_path if source_path.is_absolute_path() else "",
		_guess_loaded_file_name(label, "savegame.sav")
	)
	if not _resource.is_valid():
		_clear_document_state(_resource.get_error())
		return
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = _guess_loaded_file_name(label, "savegame.sav")
	_status_text = "Loaded %s (%d members)" % [_current_file_name(), int(_resource.inspection.get("entry_count", 0))]
	_register_controller_document()
	_refresh_view()


func get_selected_entry_index() -> int:
	if _tree == null:
		return -1
	var item := _tree.get_selected()
	if item == null:
		return -1
	return int(item.get_metadata(0))


func get_entry_payload(entry_index: int) -> PackedByteArray:
	var entries: Array = _parsed_archive.get("entries", [])
	if entry_index < 0 or entry_index >= entries.size():
		return PackedByteArray()
	var entry := entries[entry_index] as ERFParser.ERFEntry
	if entry == null:
		return PackedByteArray()
	return entry.read_data()


func install_selected_member_to_override() -> Dictionary:
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select a save member first."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	return install_member_to_override(index)


func install_member_to_override(entry_index: int) -> Dictionary:
	if _resource == null or not _resource.is_valid() or entry_index < 0:
		return {}
	var preview: Dictionary = _apply_member_install_to_override(entry_index, false)
	if preview.is_empty():
		return preview
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var result: Dictionary = _apply_member_install_to_override(entry_index, true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_refresh_gamefs()
		_refresh_status()
		return result
	_preflight_pending_preview = preview
	_preflight_pending_entry_index = entry_index
	_show_preflight_dialog(preview)
	return {}


func _apply_member_install_to_override(entry_index: int, proceed: bool) -> Dictionary:
	var entries: Array = _parsed_archive.get("entries", [])
	if entry_index < 0 or entry_index >= entries.size():
		return {}
	var entry := entries[entry_index] as ERFParser.ERFEntry
	if entry == null or entry.resref.strip_edges().is_empty():
		return _mutation_service.preview_install_to_override(_resolve_gamefs(), "", PackedByteArray())
	var file_name := _entry_file_name(entry_index)
	var payload := get_entry_payload(entry_index)
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		file_name,
		payload
	)
	if not preview.get("ok", false):
		return preview
	if preview.get("action", "") == "noop":
		preview["applied"] = false
		return preview
	if not proceed:
		return preview
	return _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		file_name,
		payload,
		true
	)


func _entry_file_name(entry_index: int) -> String:
	var entries: Array = _parsed_archive.get("entries", [])
	if entry_index < 0 or entry_index >= entries.size():
		return ""
	var entry := entries[entry_index] as ERFParser.ERFEntry
	if entry == null:
		return ""
	return "%s.%s" % [entry.resref, entry.extension]


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open Save..."
	open_btn.pressed.connect(_open_save_dialog)
	_toolbar.add_child(open_btn)

	var open_member_btn := Button.new()
	open_member_btn.text = "Open Member"
	open_member_btn.pressed.connect(_open_selected_member)
	_toolbar.add_child(open_member_btn)

	var install_btn := Button.new()
	install_btn.text = "Extract to Override"
	install_btn.pressed.connect(install_selected_member_to_override)
	_toolbar.add_child(install_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_metadata_label = Label.new()
	_metadata_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_metadata_label)

	_tree = Tree.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 3
	_tree.set_column_title(0, "ResRef")
	_tree.set_column_title(1, "Type")
	_tree.set_column_title(2, "Size")
	_tree.column_titles_visible = true
	_tree.item_activated.connect(_open_selected_member)
	add_child(_tree)

	_refresh_status()


func _refresh_view() -> void:
	_refresh_metadata()
	_refresh_tree()
	_refresh_status()


func _refresh_metadata() -> void:
	if _summary_label == null or _metadata_label == null:
		return
	if _resource == null or not _resource.is_valid():
		_summary_label.text = ""
		_metadata_label.text = ""
		return
	_summary_label.text = _resource.build_summary_text()
	var lines: Array[String] = []
	var savenfo: Dictionary = _resource.inspection.get("savenfo", {})
	if bool(savenfo.get("present", false)):
		lines.append(
			"savenfo: %s" % ("parsed" if bool(savenfo.get("parse_ok", false)) else "unparsed")
		)
	var partytable: Dictionary = _resource.inspection.get("partytable", {})
	if bool(partytable.get("present", false)):
		lines.append(
			"partytable: %s" % ("parsed" if bool(partytable.get("parse_ok", false)) else "unparsed")
		)
	var globalvars: Dictionary = _resource.inspection.get("globalvars", {})
	if bool(globalvars.get("present", false)):
		lines.append(
			"globalvars: %s" % ("parsed" if bool(globalvars.get("parse_ok", false)) else "unparsed")
		)
	_metadata_label.text = "\n".join(lines)


func _refresh_tree() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _resource == null or not _resource.is_valid():
		return
	var root_item := _tree.create_item()
	var entries: Array = _parsed_archive.get("entries", [])
	for index in range(entries.size()):
		var entry := entries[index] as ERFParser.ERFEntry
		if entry == null:
			continue
		var item := _tree.create_item(root_item)
		item.set_text(0, entry.resref)
		item.set_text(1, entry.extension)
		item.set_text(2, "%d B" % entry.size)
		item.set_metadata(0, index)


func _open_selected_member() -> void:
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select a save member to open."
		_refresh_status()
		return
	var entries: Array = _parsed_archive.get("entries", [])
	if index >= entries.size():
		return
	var entry := entries[index] as ERFParser.ERFEntry
	if entry == null:
		return
	var payload := get_entry_payload(index)
	if payload.is_empty():
		_status_text = "Save member %s.%s is empty or unreadable." % [entry.resref, entry.extension]
		_refresh_status()
		return
	member_open_requested.emit(entry.resref, entry.extension, payload)


func report_member_open_result(resref: String, extension: String, opened: bool) -> void:
	if opened:
		_status_text = "Opened member %s.%s" % [resref, extension]
	else:
		_status_text = "No workspace editor for %s.%s" % [resref, extension]
	_refresh_status()


func _open_save_dialog() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.sav ; KotOR Savegames"]),
		"Open Savegame"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_save_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _clear_document_state(message: String) -> void:
	_resource = null
	_parsed_archive = {}
	_source_path = ""
	_file_name = "savegame.sav"
	_status_text = message
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _summary_label != null:
		_summary_label.text = ""
	if _metadata_label != null:
		_metadata_label.text = ""
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"savegame",
		_resource,
		null,
		_source_path,
		_current_file_name(),
		{}
	)
	_document_key = str(entry.get("key", ""))


func _refresh_status() -> void:
	if _path_label != null:
		_path_label.text = _current_file_name()
	_emit_status_text(_status_text)


func _current_file_name() -> String:
	return _file_name.get_file() if not _file_name.is_empty() else "savegame.sav"


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var candidate := label.get_file()
	return candidate if not candidate.is_empty() else fallback


func _make_dialog(
	mode: EditorFileDialog.FileMode,
	filters: PackedStringArray,
	title: String
) -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = mode
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.filters = filters
	dialog.title = title
	return dialog


func _resolve_mutation_service() -> RefCounted:
	var controller := get_controller()
	if controller != null:
		var service = controller.get("mutation_service")
		if service != null:
			return service
	return KotorMutationService.new()


func _resolve_gamefs() -> RefCounted:
	var editor_state := get_editor_state()
	if editor_state == null:
		return null
	return editor_state.get("gamefs") as RefCounted


func _refresh_gamefs() -> void:
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.has_method("refresh_gamefs"):
		editor_state.call("refresh_gamefs")


func _mutation_message(result: Dictionary) -> String:
	return str(result.get("message", "Install complete"))


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancel.connect(_on_preflight_cancelled)
		EditorInterface.get_editor_main_screen().add_child(_preflight_dialog)
	_preflight_dialog.show_preflight(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_entry_index >= 0:
		var result: Dictionary = _apply_member_install_to_override(_preflight_pending_entry_index, true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_refresh_gamefs()
	_clear_preflight_state()
	_refresh_status()


func _on_preflight_cancelled() -> void:
	_clear_preflight_state()
	_status_text = "Extract cancelled."
	_refresh_status()


func _clear_preflight_state() -> void:
	_preflight_pending_preview = {}
	_preflight_pending_entry_index = -1
