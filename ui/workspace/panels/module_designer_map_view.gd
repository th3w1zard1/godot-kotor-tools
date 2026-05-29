@tool
extends Control
class_name ModuleDesignerMapView

signal instance_selected(category: String, index: int)

const KotorGITDocument := preload("../../../resources/documents/kotor_git_document.gd")

var _records: Array[Dictionary] = []
var _bounds := Rect2(-10, -10, 20, 20)
var _selected_category := ""
var _selected_index := -1
var _padding_pixels := 24.0


func set_instances(records: Array, bounds: Rect2) -> void:
	_records.clear()
	for raw_record in records:
		if typeof(raw_record) == TYPE_DICTIONARY:
			_records.append(raw_record)
	_bounds = bounds if bounds.size.x > 0.0 and bounds.size.y > 0.0 else Rect2(-10, -10, 20, 20)
	queue_redraw()


func set_selection(category: String, index: int) -> void:
	_selected_category = category
	_selected_index = index
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.13, 0.15))
	_draw_grid()
	for record in _records:
		_draw_instance(record)
	if not _selected_category.is_empty() and _selected_index >= 0:
		var selected := _find_record(_selected_category, _selected_index)
		if not selected.is_empty():
			var point := _world_to_screen(Vector2(float(selected.get("x", 0.0)), float(selected.get("y", 0.0))))
			draw_arc(point, 8.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0), 2.0)


func _draw_grid() -> void:
	var grid_color := Color(0.25, 0.27, 0.3)
	var step_count := 8
	for step in range(step_count + 1):
		var t := float(step) / float(step_count)
		var x := lerpf(_padding_pixels, size.x - _padding_pixels, t)
		var y := lerpf(_padding_pixels, size.y - _padding_pixels, t)
		draw_line(Vector2(x, _padding_pixels), Vector2(x, size.y - _padding_pixels), grid_color, 1.0)
		draw_line(Vector2(_padding_pixels, y), Vector2(size.x - _padding_pixels, y), grid_color, 1.0)


func _draw_instance(record: Dictionary) -> void:
	var category := str(record.get("category", ""))
	var index := int(record.get("index", -1))
	var point := _world_to_screen(Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0))))
	var color := KotorGITDocument.category_color(category)
	if category == _selected_category and index == _selected_index:
		color = color.lightened(0.35)
	draw_circle(point, 4.0, color)
	var bearing := float(record.get("bearing", 0.0))
	if absf(bearing) > 0.001:
		var direction := Vector2.RIGHT.rotated(-bearing) * 8.0
		draw_line(point, point + direction, color.lightened(0.2), 1.5)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var picked := _pick_instance(mouse_event.position)
			if not picked.is_empty():
				instance_selected.emit(str(picked.get("category", "")), int(picked.get("index", -1)))


func _pick_instance(screen_point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 12.0
	var best_index := 0x7fffffff
	for record in _records:
		var point := _world_to_screen(Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0))))
		var distance := point.distance_to(screen_point)
		var record_index := int(record.get("index", 0x7fffffff))
		if distance < best_distance or (distance == best_distance and record_index < best_index):
			best_distance = distance
			best_index = record_index
			best = record
	return best if best_distance <= 12.0 else {}


func _world_to_screen(world: Vector2) -> Vector2:
	var usable := Vector2(
		maxf(size.x - _padding_pixels * 2.0, 1.0),
		maxf(size.y - _padding_pixels * 2.0, 1.0)
	)
	var normalized := Vector2(
		(world.x - _bounds.position.x) / maxf(_bounds.size.x, 0.001),
		(world.y - _bounds.position.y) / maxf(_bounds.size.y, 0.001)
	)
	return Vector2(
		_padding_pixels + normalized.x * usable.x,
		size.y - _padding_pixels - normalized.y * usable.y
	)


func _find_record(category: String, index: int) -> Dictionary:
	for record in _records:
		if str(record.get("category", "")) == category and int(record.get("index", -1)) == index:
			return record
	return {}
