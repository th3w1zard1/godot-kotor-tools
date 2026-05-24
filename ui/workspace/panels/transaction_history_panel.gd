@tool
extends VBoxContainer
class_name KotorTransactionHistoryPanel

signal restore_completed(result: Dictionary)

var _controller: RefCounted
var _list: ItemList
var _detail: TextEdit
var _status_label: Label
var _restore_button: Button
var _refresh_button: Button
var _transactions: Array[Dictionary] = []


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func setup(controller: RefCounted) -> void:
	_controller = controller
	if is_node_ready():
		refresh_transactions()


func _ready() -> void:
	_build_ui()
	if _controller != null:
		refresh_transactions()


func get_transaction_count() -> int:
	return _transactions.size()


func refresh_transactions() -> void:
	_transactions.clear()
	if _controller != null and _controller.has_method("list_transactions"):
		for entry in _controller.call("list_transactions"):
			if typeof(entry) == TYPE_DICTIONARY:
				_transactions.append(entry)
	_transactions.reverse()
	_populate_list()
	_clear_detail()


func _build_ui() -> void:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(header)

	var title := Label.new()
	title.text = "Transaction History"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_refresh_button = Button.new()
	_refresh_button.text = "Refresh"
	_refresh_button.pressed.connect(refresh_transactions)
	header.add_child(_refresh_button)

	_restore_button = Button.new()
	_restore_button.text = "Restore Selected"
	_restore_button.pressed.connect(_on_restore_pressed)
	header.add_child(_restore_button)

	_list = ItemList.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0, 160)
	_list.item_selected.connect(_on_item_selected)
	add_child(_list)

	_detail = TextEdit.new()
	_detail.editable = false
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.custom_minimum_size = Vector2(0, 120)
	_detail.placeholder_text = "Select a transaction to inspect details."
	add_child(_detail)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_status_label)


func _populate_list() -> void:
	if _list == null:
		return
	_list.clear()
	for entry in _transactions:
		var action := str(entry.get("action", ""))
		var file_name := str(entry.get("file_name", entry.get("target_path", "").get_file()))
		var status := str(entry.get("status", ""))
		var restore_flag := "restore" if bool(entry.get("restore_eligible", entry.get("rollback_available", false))) else "no-restore"
		_list.add_item("%s | %s | %s | %s" % [str(entry.get("id", "")), action, file_name, restore_flag])
		if status == "conflict" or status == "io_error":
			_list.set_item_custom_fg_color(_list.item_count - 1, Color(1.0, 0.35, 0.35))


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _transactions.size():
		return
	_show_transaction(_transactions[index])


func _show_transaction(entry: Dictionary) -> void:
	if _detail == null:
		return
	var lines: Array[String] = [
		"ID: %s" % str(entry.get("id", "")),
		"Kind: %s" % str(entry.get("kind", "")),
		"Action: %s" % str(entry.get("action", "")),
		"Target: %s" % str(entry.get("target_path", "")),
		"Status: %s" % str(entry.get("status", "")),
		"Rollback available: %s" % str(entry.get("rollback_available", false)),
		"Restore eligible: %s" % str(entry.get("restore_eligible", false)),
	]
	if entry.has("message"):
		lines.append("Message: %s" % str(entry.get("message", "")))
	_detail.text = "\n".join(lines)
	if _status_label != null:
		_status_label.text = ""


func _clear_detail() -> void:
	if _detail != null:
		_detail.text = ""
	if _status_label != null:
		_status_label.text = ""
	if _list != null and _list.item_count > 0:
		_list.select(0)
		_on_item_selected(0)


func _on_restore_pressed() -> void:
	if _controller == null or _list == null:
		return
	var selected := _list.get_selected_items()
	if selected.is_empty():
		_set_status("Select a transaction to restore.")
		return
	var index: int = selected[0]
	if index < 0 or index >= _transactions.size():
		return
	var transaction_id := str(_transactions[index].get("id", ""))
	if transaction_id.is_empty():
		_set_status("Selected transaction has no id.")
		return
	if not _controller.has_method("restore_transaction_from_history"):
		_set_status("Restore is not available.")
		return
	var result: Dictionary = _controller.call("restore_transaction_from_history", transaction_id)
	_set_status(str(result.get("message", "Restore finished.")))
	refresh_transactions()
	refresh_install_state()
	restore_completed.emit(result)


func refresh_install_state() -> void:
	if _controller == null:
		return
	var state = _controller.get("editor_state")
	if state != null and state.has_method("refresh_gamefs"):
		state.call("refresh_gamefs")


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
