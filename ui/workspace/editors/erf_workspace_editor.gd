@tool
extends "./kotor_workspace_editor.gd"
class_name KotorErfWorkspaceEditor

signal member_open_requested(resref: String, extension: String, payload: PackedByteArray)

const ERFParser := preload("../../../formats/erf_parser.gd")
const KotorErfDocument := preload("../../../resources/documents/kotor_erf_document.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

const ARCHIVE_EXTENSIONS := ["erf", "rim", "mod"]

var _toolbar: HBoxContainer
var _path_label: Label
var _summary_label: Label
var _tree: Tree
var _preflight_dialog: KotorPreflightDialog

var _mutation_service: RefCounted
var _document: KotorErfDocument
var _source_path := ""
var _file_name := "archive.mod"
var _status_text := ""
var _document_key := ""

var _pending_source_path := ""
var _pending_file_name := ""
var _pending_bytes: PackedByteArray = PackedByteArray()

var _preflight_pending_path := ""
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_kind := ""
var _preflight_pending_entry_index := -1
var _skip_preflight_for_testing := false


static func archive_extension_allowed(extension: String) -> bool:
	return ARCHIVE_EXTENSIONS.has(extension.strip_edges().to_lower())


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
		open_archive_bytes(pending_file_name, pending_bytes, pending_source_path)


func get_document() -> KotorErfDocument:
	return _document


func open_archive_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_text = "Failed to open %s" % path.get_file()
		_refresh_status()
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_archive_bytes(path.get_file(), bytes, path)


func open_archive_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	if not is_node_ready():
		_pending_bytes = data
		_pending_source_path = source_path
		_pending_file_name = label
		return
	_document = KotorErfDocument.from_bytes(source_path, data)
	if _document == null:
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "archive.mod"))
		return
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = _guess_loaded_file_name(label, "archive.mod")
	_status_text = "Loaded %s (%d members)" % [_current_file_name(), _document.get_entry_count()]
	_register_controller_document()
	_refresh_view()


func set_status_message(text: String) -> void:
	_status_text = text
	_refresh_status()


func get_selected_entry_index() -> int:
	if _tree == null:
		return -1
	var item := _tree.get_selected()
	if item == null:
		return -1
	return int(item.get_metadata(0))


func install_selected_entry_to_override() -> Dictionary:
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select an archive member first."
		_refresh_status()
		return {}
	return install_entry_to_override(index)


func install_entry_to_override(entry_index: int) -> Dictionary:
	if _document == null or entry_index < 0:
		return {}
	var entry := _document.get_entry(entry_index)
	if entry == null or entry.resref.strip_edges().is_empty():
		var invalid: Dictionary = _mutation_service.preview_install_to_override(_resolve_gamefs(), "", PackedByteArray())
		_status_text = invalid.get("message", "Archive member has an invalid override file name.")
		_refresh_status()
		return invalid
	var file_name := _document.entry_file_name(entry_index)
	var payload := _document.get_entry_payload(entry_index)
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		file_name,
		payload
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var result: Dictionary = _mutation_service.apply_install_to_override(
			_resolve_gamefs(),
			file_name,
			payload,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_refresh_gamefs()
		_refresh_status()
		return result
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install_entry"
	_preflight_pending_entry_index = entry_index
	_show_preflight_dialog(preview)
	return {}


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open Archive..."
	open_btn.pressed.connect(_open_archive_dialog)
	_toolbar.add_child(open_btn)

	var open_member_btn := Button.new()
	open_member_btn.text = "Open Member"
	open_member_btn.pressed.connect(_open_selected_member)
	_toolbar.add_child(open_member_btn)

	var install_btn := Button.new()
	install_btn.text = "Extract to Override"
	install_btn.pressed.connect(install_selected_entry_to_override)
	_toolbar.add_child(install_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	_toolbar.add_child(_path_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

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
	_refresh_tree()
	_refresh_status()


func _refresh_tree() -> void:
	if _tree == null:
		return
	_tree.clear()
	if _document == null:
		return
	var root_item := _tree.create_item()
	for index in range(_document.get_entry_count()):
		var entry := _document.get_entry(index)
		if entry == null:
			continue
		var item := _tree.create_item(root_item)
		item.set_text(0, entry.resref)
		item.set_text(1, entry.extension)
		item.set_text(2, "%d B" % entry.size)
		item.set_metadata(0, index)
	if _summary_label != null:
		_summary_label.text = "%s archive with %d members." % [
			_document.file_type.strip_edges(),
			_document.get_entry_count(),
		]


func _open_selected_member() -> void:
	var index := get_selected_entry_index()
	if index < 0 or _document == null:
		_status_text = "Select an archive member to open."
		_refresh_status()
		return
	var entry := _document.get_entry(index)
	if entry == null:
		return
	var payload := _document.get_entry_payload(index)
	if payload.is_empty():
		_status_text = "Archive member %s is empty or unreadable." % _document.entry_file_name(index)
		_refresh_status()
		return
	member_open_requested.emit(entry.resref, entry.extension, payload)
	_status_text = "Opened member %s.%s" % [entry.resref, entry.extension]
	_refresh_status()


func _open_archive_dialog() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.erf,*.rim,*.mod ; KotOR Archives"]),
		"Open Archive"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		open_archive_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancel.connect(_on_preflight_cancelled)
		EditorInterface.get_editor_main_screen().add_child(_preflight_dialog)
	_preflight_dialog.show_preflight(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "install_entry" and _preflight_pending_entry_index >= 0 and _document != null:
		var file_name := _document.entry_file_name(_preflight_pending_entry_index)
		var payload := _document.get_entry_payload(_preflight_pending_entry_index)
		var result: Dictionary = _mutation_service.apply_install_to_override(
			_resolve_gamefs(),
			file_name,
			payload,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_refresh_gamefs()
	_update_controller_dirty_state()
	_clear_preflight_state()
	_refresh_status()


func _on_preflight_cancelled() -> void:
	_clear_preflight_state()
	_status_text = "Extract cancelled."
	_refresh_status()


func _clear_preflight_state() -> void:
	_preflight_pending_path = ""
	_preflight_pending_preview = {}
	_preflight_pending_kind = ""
	_preflight_pending_entry_index = -1


func _clear_document_state(message: String) -> void:
	_document = null
	_source_path = ""
	_file_name = "archive.mod"
	_status_text = message
	_document_key = ""
	if _tree != null:
		_tree.clear()
	if _summary_label != null:
		_summary_label.text = ""
	_refresh_status()


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"erf",
		null,
		_document,
		_source_path,
		_current_file_name(),
		{}
	)
	_document_key = str(entry.get("key", ""))


func _update_controller_dirty_state() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_dirty"):
		return
	controller.call("update_document_dirty", _document_key, false)


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


func _current_file_name() -> String:
	return _file_name.get_file() if not _file_name.is_empty() else "archive.mod"


func _make_dialog(
		file_mode: EditorFileDialog.FileMode,
		filters: PackedStringArray,
		title: String,
		start_dir: String = "",
		current_file: String = ""
) -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = file_mode
	dialog.title = title
	dialog.filters = filters
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.has_method("resolve_dialog_start_dir"):
		dialog.current_dir = editor_state.call("resolve_dialog_start_dir", start_dir)
	elif not start_dir.is_empty():
		dialog.current_dir = start_dir
	if not current_file.is_empty():
		dialog.current_file = current_file
	return dialog


func _refresh_status() -> void:
	if _path_label == null:
		return
	if _document == null:
		_path_label.text = _status_text
		_emit_status_text(_status_text)
		return
	var line := _current_file_name()
	if not _status_text.is_empty():
		line += " — %s" % _status_text
	_path_label.text = line
	_emit_dirty_state(false)
	_emit_status_text(_status_text)


func _mutation_message(result: Dictionary) -> String:
	if result.get("applied", false):
		return str(result.get("message", "Changes applied."))
	return str(result.get("message", "Mutation failed."))


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var candidate := label.get_file()
	if candidate.is_empty():
		return fallback
	var extension := candidate.get_extension().to_lower()
	if archive_extension_allowed(extension):
		return candidate
	return fallback
