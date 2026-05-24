@tool
extends VBoxContainer
class_name KotorValidationPanel

var _report: TextEdit


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	_ensure_report()


func clear_report() -> void:
	_ensure_report()
	_report.text = ""


func set_success(summary: String, details: Array[String] = []) -> void:
	var lines: Array[String] = [summary]
	for detail in details:
		var text := detail.strip_edges()
		if not text.is_empty():
			lines.append("- %s" % text)
	_set_report_text("\n".join(lines))


func set_issues(title: String, issues: Array[String]) -> void:
	var lines: Array[String] = [title]
	for issue in issues:
		var text := issue.strip_edges()
		if not text.is_empty():
			lines.append("- %s" % text)
	_set_report_text("\n".join(lines))


func get_report_text() -> String:
	_ensure_report()
	return _report.text


func _set_report_text(text: String) -> void:
	_ensure_report()
	_report.text = text


func _ensure_report() -> void:
	if _report != null:
		return
	var label := Label.new()
	label.text = "Validation"
	add_child(label)
	_report = TextEdit.new()
	_report.editable = false
	_report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_report.custom_minimum_size = Vector2(0, 140)
	_report.placeholder_text = "Validation output appears here."
	add_child(_report)
