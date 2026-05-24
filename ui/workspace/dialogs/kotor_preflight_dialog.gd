@tool
extends ConfirmationDialog
class_name KotorPreflightDialog

signal preflight_proceed
signal preflight_cancel

var _content: VBoxContainer


func _init() -> void:
	title = "Confirm Action"
	size = Vector2(600, 300)
	min_size = Vector2(400, 200)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content)


func _ready() -> void:
	confirmed.connect(_on_ok)
	canceled.connect(_on_cancelled)


func show_preflight(preview: Dictionary) -> void:
	if not preview.get("ok", false):
		_show_error(preview)
		return

	var action: String = str(preview.get("action", ""))
	var file_name: String = str(preview.get("file_name", "unknown"))
	var message: String = str(preview.get("message", ""))
	var rollback_available: bool = bool(preview.get("rollback_available", false))

	match action:
		"noop":
			_show_noop(file_name, message)
		"create":
			_show_create(file_name, message, rollback_available)
		"overwrite":
			_show_overwrite(file_name, message, rollback_available)
		"remove":
			_show_remove(file_name, message, rollback_available)
		_:
			_show_error({"message": "Unknown action: %s" % action})

	popup_centered()


func _show_error(preview: Dictionary) -> void:
	title = "Action Failed"
	ok_button_text = "OK"
	get_cancel_button().hide()
	clear_content()
	_content.add_child(_make_body_label("Error: %s" % str(preview.get("message", "An error occurred."))))
	preflight_cancel.emit()


func _show_noop(file_name: String, message: String) -> void:
	title = "No Changes"
	ok_button_text = "OK"
	get_cancel_button().hide()
	clear_content()
	_content.add_child(_make_body_label("%s\n\nNo changes to apply." % message))
	preflight_cancel.emit()


func _show_create(file_name: String, message: String, rollback_available: bool) -> void:
	title = "Create New File"
	ok_button_text = "Proceed"
	get_cancel_button().show()
	get_cancel_button().text = "Cancel"
	clear_content()
	_content.add_child(_make_body_label("Action: Create new file"))
	_content.add_child(_make_body_label("Target: %s" % file_name))
	_content.add_child(_make_body_label(message))
	if rollback_available:
		_content.add_child(_make_body_label("Rollback available."))
	else:
		_content.add_child(_make_body_label("No rollback (cannot undo after proceed)."))


func _show_overwrite(file_name: String, message: String, rollback_available: bool) -> void:
	title = "Overwrite Existing File"
	ok_button_text = "Proceed"
	get_cancel_button().show()
	get_cancel_button().text = "Cancel"
	clear_content()
	_content.add_child(_make_body_label("Action: Overwrite existing file"))
	_content.add_child(_make_body_label("Target: %s" % file_name))
	_content.add_child(_make_body_label(message))
	if rollback_available:
		_content.add_child(_make_body_label("Rollback available."))
	else:
		_content.add_child(_make_body_label("No rollback (cannot undo after proceed)."))


func _show_remove(file_name: String, message: String, rollback_available: bool) -> void:
	title = "Remove File"
	ok_button_text = "Proceed"
	get_cancel_button().show()
	get_cancel_button().text = "Cancel"
	clear_content()
	_content.add_child(_make_body_label("Action: Remove file"))
	_content.add_child(_make_body_label("Target: %s" % file_name))
	_content.add_child(_make_body_label(message))
	if rollback_available:
		_content.add_child(_make_body_label("Rollback available."))
	else:
		_content.add_child(_make_body_label("No rollback (cannot undo after proceed)."))


func _make_body_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func clear_content() -> void:
	for child in _content.get_children():
		child.queue_free()


func _on_ok() -> void:
	preflight_proceed.emit()


func _on_cancelled() -> void:
	preflight_cancel.emit()
