@tool
extends "./kotor_workspace_editor.gd"
class_name KotorErfWorkspaceEditor

signal member_open_requested(resref: String, extension: String, payload: PackedByteArray)

const ERFParser := preload("../../../formats/erf_parser.gd")
const KotorErfDocument := preload("../../../resources/documents/kotor_erf_document.gd")
const KotorIndoorModuleInstaller := preload("../../../resources/indoor/kotor_indoor_module_installer.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorModdingPipeline := preload("../../../editor/modding/kotor_modding_pipeline.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")

const ARCHIVE_EXTENSIONS := ["erf", "rim", "mod", "sav"]
const MODULE_INSTALL_EXTENSIONS := ["erf", "rim", "mod"]

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
var _last_compare_result: Dictionary = {}


static func archive_extension_allowed(extension: String) -> bool:
	return ARCHIVE_EXTENSIONS.has(extension.strip_edges().to_lower())


static func modules_install_allowed(extension: String) -> bool:
	return MODULE_INSTALL_EXTENSIONS.has(extension.strip_edges().to_lower())


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


func export_selected_member_to_path(path: String) -> Dictionary:
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select an archive member first."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	return export_member_to_path(index, path)


func export_member_to_path(entry_index: int, path: String) -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No archive is loaded."}
	if entry_index < 0:
		return {"ok": false, "message": "Select an archive member first."}
	var entry := _document.get_entry(entry_index)
	if entry == null or entry.resref.strip_edges().is_empty():
		_status_text = "Archive member has an invalid file name."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	var target_path := path.strip_edges()
	if target_path.is_empty():
		_status_text = "Choose a destination file."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	var payload := _document.get_entry_payload(entry_index)
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, payload)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var result: Dictionary = _mutation_service.apply_export_to_path(target_path, payload, true)
		_status_text = _mutation_message(result)
		_refresh_status()
		return result
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export_member"
	_preflight_pending_entry_index = entry_index
	_show_preflight_dialog(preview)
	return {}


func extract_all_members_to_override() -> Dictionary:
	if _document == null:
		_status_text = "No archive is loaded."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	if _document.is_empty():
		_status_text = "Archive has no members to extract."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	var applied := 0
	var unchanged := 0
	var skipped := 0
	var failed := 0
	for index in range(_document.get_entry_count()):
		var result := _apply_entry_install_to_override(index, true)
		if result.is_empty():
			skipped += 1
			continue
		if not result.get("ok", false):
			if _document.get_entry(index) != null and _document.get_entry(index).resref.strip_edges().is_empty():
				skipped += 1
			else:
				failed += 1
			continue
		if result.get("applied", false):
			applied += 1
		elif result.get("action", "") == "noop":
			unchanged += 1
		else:
			failed += 1
	if applied > 0:
		_refresh_gamefs()
	_status_text = "Extracted %d member(s) to override (%d unchanged, %d skipped, %d failed)." % [
		applied,
		unchanged,
		skipped,
		failed,
	]
	_refresh_status()
	return {
		"ok": failed == 0,
		"applied": applied,
		"unchanged": unchanged,
		"skipped": skipped,
		"failed": failed,
		"message": _status_text,
	}


func extract_all_members_to_folder(dest_dir: String) -> Dictionary:
	if _document == null:
		_status_text = "No archive is loaded."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	if _document.is_empty():
		_status_text = "Archive has no members to extract."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	var folder := dest_dir.strip_edges()
	if folder.is_empty():
		_status_text = "Choose a destination folder."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	DirAccess.make_dir_recursive_absolute(folder)
	var written := 0
	var skipped := 0
	var failed := 0
	for index in range(_document.get_entry_count()):
		var entry := _document.get_entry(index)
		if entry == null or entry.resref.strip_edges().is_empty():
			skipped += 1
			continue
		var out_path := folder.path_join(_document.entry_file_name(index))
		var payload := _document.get_entry_payload(index)
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file == null:
			failed += 1
			continue
		file.store_buffer(payload)
		file.close()
		written += 1
	_status_text = "Extracted %d member(s) to folder (%d skipped, %d failed)." % [
		written,
		skipped,
		failed,
	]
	_refresh_status()
	return {
		"ok": failed == 0,
		"written": written,
		"skipped": skipped,
		"failed": failed,
		"message": _status_text,
	}


func is_document_dirty() -> bool:
	return _document != null and _document.is_dirty()


func compare_selected_member_with_override() -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No archive is loaded."}
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select an archive member to compare."
		_refresh_status()
		return {"ok": false, "message": "Select an archive member to compare."}
	var entry := _document.get_entry(index)
	if entry == null:
		return {"ok": false, "message": "Selected archive member is unavailable."}
	var gamefs := _resolve_gamefs()
	if gamefs == null:
		_status_text = "Configure a valid game install before compare."
		_refresh_status()
		return {"ok": false, "message": "Configure a valid game install before compare."}
	var resource_type := -1
	if gamefs.has_method("resource_type_for_extension"):
		resource_type = int(gamefs.call("resource_type_for_extension", entry.extension))
	var result := KotorModdingPipeline.compare_gamefs_resource(gamefs, entry.resref, resource_type)
	_last_compare_result = result
	_status_text = KotorModdingPipeline.format_compare_result_text(result)
	_refresh_status()
	return result


func export_compare_report_to_path(path: String) -> Dictionary:
	if _last_compare_result.is_empty():
		_status_text = "Run Compare Member with Override first."
		_refresh_status()
		return {"ok": false, "message": "No compare result is available."}
	var target_path := path
	if target_path.get_extension().to_lower() != "txt":
		target_path = "%s.txt" % target_path
	var export_result := KotorModdingPipeline.export_compare_result_to_path(target_path, _last_compare_result)
	_status_text = str(export_result.get("message", "Export failed."))
	_refresh_status()
	return export_result


func remove_selected_member() -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No archive is loaded."}
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select an archive member to remove."
		_refresh_status()
		return {"ok": false, "message": "Select an archive member to remove."}
	var before_snapshot := _members_snapshot()
	var result := _document.remove_member_at(index)
	if not result.get("ok", false):
		_status_text = result.get("message", "Failed to remove member.")
		_refresh_status()
		return result
	_commit_members_mutation_undo("Remove archive member", before_snapshot)
	_status_text = result.get("message", "Member removed.")
	_refresh_view()
	return result


func replace_member_from_file(path: String) -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No archive is loaded."}
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select an archive member to replace."
		_refresh_status()
		return {"ok": false, "message": "Select an archive member to replace."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Failed to read %s" % path.get_file()}
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var before_snapshot := _members_snapshot()
	var result := _document.replace_member_at(index, bytes)
	if not result.get("ok", false):
		_status_text = result.get("message", "Failed to replace member.")
		_refresh_status()
		return result
	_commit_members_mutation_undo("Replace archive member", before_snapshot)
	_status_text = result.get("message", "Member replaced.")
	_refresh_view()
	return result


func add_member_from_file(path: String) -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No archive is loaded."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Failed to read %s" % path.get_file()}
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var resref := path.get_file().get_basename().to_lower().left(16)
	var extension := path.get_extension().to_lower()
	var before_snapshot := _members_snapshot()
	var result := _document.add_member(resref, extension, bytes)
	if result.get("ok", false):
		_commit_members_mutation_undo("Add archive member", before_snapshot)
		_status_text = result.get("message", "Member added.")
		_refresh_view()
	else:
		_status_text = result.get("message", "Failed to add member.")
		_refresh_status()
	return result


func install_archive_to_modules() -> Dictionary:
	if _document == null:
		return {"ok": false, "message": "No archive is loaded."}
	var file_name := _current_file_name()
	var extension := file_name.get_extension().to_lower()
	if not modules_install_allowed(extension):
		_status_text = "Only MOD, ERF, and RIM archives can be installed to modules."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	var editor_state := get_editor_state()
	var game_path := ""
	if editor_state != null:
		game_path = str(editor_state.get("game_path"))
	var modules_path := KotorIndoorModuleInstaller.resolve_modules_path(game_path)
	if modules_path.is_empty():
		_status_text = "Configure a valid game install with a modules folder."
		_refresh_status()
		return {"ok": false, "message": _status_text}
	var target_path := modules_path.path_join(file_name)
	var payload: Dictionary = _document.serialize_for_pipeline()
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, payload)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "Archive is already up to date in modules")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var result: Dictionary = _mutation_service.apply_export_to_path(target_path, payload, true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_refresh_gamefs()
		_refresh_status()
		return result
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install_modules"
	_show_preflight_dialog(preview)
	return {}


func save_archive_to_path(path: String) -> Dictionary:
	if _document == null:
		return {}
	var target_path := _ensure_archive_extension(path)
	var payload: Dictionary = _document.serialize_for_pipeline()
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, payload)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		var previous_key := _document_key
		var result: Dictionary = _mutation_service.apply_export_to_path(target_path, payload, true)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_source_path = target_path
			_file_name = target_path.get_file()
			_document.mark_clean()
			_register_controller_document()
			_remove_previous_controller_document(previous_key)
		_update_controller_dirty_state()
		_refresh_status()
		return result
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_show_preflight_dialog(preview)
	return {}


func install_entry_to_override(entry_index: int) -> Dictionary:
	if _document == null or entry_index < 0:
		return {}
	var preview: Dictionary = _apply_entry_install_to_override(entry_index, false)
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
		var result: Dictionary = _apply_entry_install_to_override(entry_index, true)
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


func _apply_entry_install_to_override(entry_index: int, proceed: bool) -> Dictionary:
	if _document == null or entry_index < 0:
		return {}
	var entry := _document.get_entry(entry_index)
	if entry == null or entry.resref.strip_edges().is_empty():
		return _mutation_service.preview_install_to_override(_resolve_gamefs(), "", PackedByteArray())
	var file_name := _document.entry_file_name(entry_index)
	var payload := _document.get_entry_payload(entry_index)
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

	var export_member_btn := Button.new()
	export_member_btn.text = "Export Selected..."
	export_member_btn.pressed.connect(_export_selected_member_dialog)
	_toolbar.add_child(export_member_btn)

	var extract_all_btn := Button.new()
	extract_all_btn.text = "Extract All to Override"
	extract_all_btn.pressed.connect(extract_all_members_to_override)
	_toolbar.add_child(extract_all_btn)

	var extract_folder_btn := Button.new()
	extract_folder_btn.text = "Extract All to Folder..."
	extract_folder_btn.pressed.connect(_extract_all_to_folder_dialog)
	_toolbar.add_child(extract_folder_btn)

	var add_member_btn := Button.new()
	add_member_btn.text = "Add Member..."
	add_member_btn.pressed.connect(_add_member_dialog)
	_toolbar.add_child(add_member_btn)

	var save_btn := Button.new()
	save_btn.text = "Save Archive..."
	save_btn.pressed.connect(_save_archive_dialog)
	_toolbar.add_child(save_btn)

	var remove_member_btn := Button.new()
	remove_member_btn.text = "Remove Member"
	remove_member_btn.pressed.connect(remove_selected_member)
	_toolbar.add_child(remove_member_btn)

	var replace_member_btn := Button.new()
	replace_member_btn.text = "Replace Member..."
	replace_member_btn.pressed.connect(_replace_member_dialog)
	_toolbar.add_child(replace_member_btn)

	var compare_btn := Button.new()
	compare_btn.text = "Compare Member with Override..."
	compare_btn.pressed.connect(compare_selected_member_with_override)
	_toolbar.add_child(compare_btn)

	var export_compare_btn := Button.new()
	export_compare_btn.text = "Export Compare Report..."
	export_compare_btn.pressed.connect(_export_compare_report_dialog)
	_toolbar.add_child(export_compare_btn)

	var install_modules_btn := Button.new()
	install_modules_btn.text = "Install Archive to Modules"
	install_modules_btn.pressed.connect(install_archive_to_modules)
	_toolbar.add_child(install_modules_btn)

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


func _export_compare_report_dialog() -> void:
	if _last_compare_result.is_empty():
		_status_text = "Run Compare Member with Override first."
		_refresh_status()
		return
	var index := get_selected_entry_index()
	var resref := "member"
	if index >= 0 and _document != null:
		var entry := _document.get_entry(index)
		if entry != null:
			resref = entry.resref
	var start_dir := ""
	var editor_state := get_editor_state()
	if editor_state != null:
		start_dir = str(editor_state.game_path)
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.txt ; Text Report"]),
		"Export Compare Report",
		start_dir,
		"%s-compare-report.txt" % resref
	)
	dialog.file_selected.connect(func(path: String) -> void:
		export_compare_report_to_path(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	if Engine.is_editor_hint():
		EditorInterface.get_editor_main_screen().add_child(dialog)
	else:
		add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _replace_member_dialog() -> void:
	if _document == null:
		_status_text = "Open an archive before replacing members."
		_refresh_status()
		return
	if get_selected_entry_index() < 0:
		_status_text = "Select an archive member to replace."
		_refresh_status()
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.* ; All Files"]),
		"Replace Archive Member"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		replace_member_from_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _export_selected_member_dialog() -> void:
	if _document == null:
		_status_text = "Open an archive before exporting members."
		_refresh_status()
		return
	var index := get_selected_entry_index()
	if index < 0:
		_status_text = "Select an archive member first."
		_refresh_status()
		return
	var entry := _document.get_entry(index)
	if entry == null or entry.resref.strip_edges().is_empty():
		_status_text = "Archive member has an invalid file name."
		_refresh_status()
		return
	var default_name := _document.entry_file_name(index)
	var root_dir := ""
	var editor_state := get_editor_state()
	if editor_state != null:
		root_dir = str(editor_state.get("game_path"))
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(),
		"Export Archive Member",
		root_dir,
		default_name
	)
	dialog.file_selected.connect(func(path: String) -> void:
		export_selected_member_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _extract_all_to_folder_dialog() -> void:
	if _document == null:
		_status_text = "Open an archive before extracting members."
		_refresh_status()
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_DIR,
		PackedStringArray(),
		"Extract All To..."
	)
	dialog.dir_selected.connect(func(dir: String) -> void:
		extract_all_members_to_folder(dir)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _add_member_dialog() -> void:
	if _document == null:
		_status_text = "Open an archive before adding members."
		_refresh_status()
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.* ; All Files"]),
		"Add Archive Member"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		add_member_from_file(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _save_archive_dialog() -> void:
	if _document == null:
		_status_text = "Open an archive before saving."
		_refresh_status()
		return
	var extension := _current_file_name().get_extension().to_lower()
	if extension.is_empty():
		extension = "mod"
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.%s ; KotOR Archives" % extension]),
		"Save Archive",
		"",
		_current_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		save_archive_to_path(path)
	)
	EditorInterface.get_editor_main_screen().add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _open_archive_dialog() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.erf,*.rim,*.mod,*.sav ; KotOR Archives"]),
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
	if _preflight_pending_kind == "export" and not _preflight_pending_path.is_empty() and _document != null:
		var payload: Dictionary = _document.serialize_for_pipeline()
		var previous_key := _document_key
		var result: Dictionary = _mutation_service.apply_export_to_path(
			_preflight_pending_path,
			payload,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_source_path = _preflight_pending_path
			_file_name = _preflight_pending_path.get_file()
			_document.mark_clean()
			_register_controller_document()
			_remove_previous_controller_document(previous_key)
	elif _preflight_pending_kind == "install_modules" and not _preflight_pending_path.is_empty() and _document != null:
		var payload: Dictionary = _document.serialize_for_pipeline()
		var result: Dictionary = _mutation_service.apply_export_to_path(
			_preflight_pending_path,
			payload,
			true
		)
		_status_text = _mutation_message(result)
		if result.get("applied", false):
			_refresh_gamefs()
	elif _preflight_pending_kind == "install_entry" and _preflight_pending_entry_index >= 0 and _document != null:
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
	elif _preflight_pending_kind == "export_member" and _preflight_pending_entry_index >= 0 and not _preflight_pending_path.is_empty() and _document != null:
		var payload := _document.get_entry_payload(_preflight_pending_entry_index)
		var result: Dictionary = _mutation_service.apply_export_to_path(
			_preflight_pending_path,
			payload,
			true
		)
		_status_text = _mutation_message(result)
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
	controller.call("update_document_dirty", _document_key, is_document_dirty())


func _remove_previous_controller_document(previous_key: String) -> void:
	if previous_key.is_empty() or previous_key == _document_key:
		return
	var controller := get_controller()
	if controller == null or not controller.has_method("unregister_document"):
		return
	controller.call("unregister_document", previous_key)


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
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
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
	_emit_dirty_state(is_document_dirty())
	_emit_status_text(_status_text)


func _members_snapshot() -> Array:
	if _document == null:
		return []
	var payload: Dictionary = _document.serialize_for_pipeline()
	return payload.get("entries", []).duplicate(true)


func _apply_members_snapshot(snapshot: Array) -> void:
	if _document == null:
		return
	_document.restore_members(snapshot)
	_refresh_view()


func _commit_members_mutation_undo(action_name: String, before_snapshot: Array) -> void:
	var after_snapshot := _members_snapshot()
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action(action_name, UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_apply_members_snapshot", after_snapshot)
		ur.add_undo_method(self, "_apply_members_snapshot", before_snapshot)
		ur.commit_action()
	_update_controller_dirty_state()


func _get_undo_redo() -> EditorUndoRedoManager:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_undo_redo()
	return null


func _ensure_archive_extension(path: String) -> String:
	var extension := path.get_extension().to_lower()
	if archive_extension_allowed(extension):
		return path
	var fallback := _current_file_name().get_extension().to_lower()
	if fallback.is_empty():
		fallback = "mod"
	return "%s.%s" % [path.get_basename(), fallback]


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
