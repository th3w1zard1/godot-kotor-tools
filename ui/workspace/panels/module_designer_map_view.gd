@tool
extends Control
class_name ModuleDesignerMapView

const KotorWorldCoordinates := preload("../../../editor/module/kotor_world_coordinates.gd")

signal instance_selected(category: String, index: int)
signal instance_drag_updated(category: String, index: int, x: float, y: float)
signal instance_drag_finished(
	category: String,
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
)
signal instance_rotate_updated(category: String, index: int, bearing: float)
signal instance_rotate_finished(
	category: String,
	index: int,
	old_bearing: float,
	new_bearing: float
)

const KotorGITDocument := preload("../../../resources/documents/kotor_git_document.gd")

var _records: Array[Dictionary] = []
var _path_points: Array[Dictionary] = []
var _path_edges: Array[Dictionary] = []
var _bounds := Rect2(-10, -10, 20, 20)
var _selected_category := ""
var _selected_index := -1
var _padding_pixels := 24.0
var _drag_active := false
var _drag_category := ""
var _drag_index := -1
var _drag_start_world := Vector2.ZERO
var _drag_current_world := Vector2.ZERO
var _rotate_active := false
var _rotate_category := ""
var _rotate_index := -1
var _rotate_start_bearing := 0.0
var _rotate_preview_bearing := 0.0


func set_instances(records: Array, bounds: Rect2, path_points: Array = [], path_edges: Array = []) -> void:
	_records.clear()
	for raw_record in records:
		if typeof(raw_record) == TYPE_DICTIONARY:
			_records.append(raw_record)
	_path_points.clear()
	for raw_point in path_points:
		if typeof(raw_point) == TYPE_DICTIONARY:
			_path_points.append(raw_point)
	_path_edges.clear()
	for raw_edge in path_edges:
		if typeof(raw_edge) == TYPE_DICTIONARY:
			_path_edges.append(raw_edge)
	_bounds = bounds if bounds.size.x > 0.0 and bounds.size.y > 0.0 else Rect2(-10, -10, 20, 20)
	_cancel_drag()
	_cancel_rotate()
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
	_draw_path_edges()
	_draw_path_points()
	for record in _records:
		_draw_instance(record)
	if not _selected_category.is_empty() and _selected_index >= 0:
		var selected := _find_record(_selected_category, _selected_index)
		if not selected.is_empty():
			var point := _world_to_screen(Vector2(float(selected.get("x", 0.0)), float(selected.get("y", 0.0))))
			draw_arc(point, 8.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0), 2.0)


func _draw_path_edges() -> void:
	var path_color := Color(0.15, 0.75, 0.82, 0.85)
	for edge_record in _path_edges:
		var source := _world_to_screen(Vector2(float(edge_record.get("source_x", 0.0)), float(edge_record.get("source_y", 0.0))))
		var target := _world_to_screen(Vector2(float(edge_record.get("target_x", 0.0)), float(edge_record.get("target_y", 0.0))))
		draw_line(source, target, path_color, 1.5)


func _draw_path_points() -> void:
	var path_color := Color(0.2, 0.95, 0.95, 0.95)
	for point_record in _path_points:
		var point := _world_to_screen(Vector2(float(point_record.get("x", 0.0)), float(point_record.get("y", 0.0))))
		draw_circle(point, 3.5, path_color)
		draw_arc(point, 5.5, 0.0, TAU, 18, path_color.darkened(0.35), 1.5)


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
	var world := Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))
	if _drag_active and category == _drag_category and index == _drag_index:
		world = _drag_current_world
	var point := _world_to_screen(world)
	var color := KotorGITDocument.category_color(category)
	if category == _selected_category and index == _selected_index:
		color = color.lightened(0.35)
	draw_circle(point, 4.0, color)
	var bearing := float(record.get("bearing", 0.0))
	if _rotate_active and category == _rotate_category and index == _rotate_index:
		bearing = _rotate_preview_bearing
	if absf(bearing) > 0.001:
		var direction := Vector2.RIGHT.rotated(-bearing) * 8.0
		draw_line(point, point + direction, color.lightened(0.2), 1.5)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				var picked := _pick_instance(mouse_event.position)
				if picked.is_empty():
					return
				var category := str(picked.get("category", ""))
				var index := int(picked.get("index", -1))
				instance_selected.emit(category, index)
				_rotate_active = true
				_rotate_category = category
				_rotate_index = index
				_rotate_start_bearing = float(picked.get("bearing", 0.0))
				_rotate_preview_bearing = _rotate_start_bearing
				accept_event()
				return
			if _rotate_active:
				_finish_rotate()
				accept_event()
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			var picked := _pick_instance(mouse_event.position)
			if picked.is_empty():
				return
			var category := str(picked.get("category", ""))
			var index := int(picked.get("index", -1))
			instance_selected.emit(category, index)
			_drag_active = true
			_drag_category = category
			_drag_index = index
			_drag_start_world = Vector2(float(picked.get("x", 0.0)), float(picked.get("y", 0.0)))
			_drag_current_world = _drag_start_world
			accept_event()
			return
		if _drag_active:
			_finish_drag()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _rotate_active:
			var record := _find_record(_rotate_category, _rotate_index)
			if record.is_empty():
				_cancel_rotate()
				return
			var instance_world := Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))
			var cursor_world := _screen_to_world(motion.position)
			_rotate_preview_bearing = _bearing_from_world_point(instance_world, cursor_world)
			instance_rotate_updated.emit(_rotate_category, _rotate_index, _rotate_preview_bearing)
			queue_redraw()
			accept_event()
			return
		if not _drag_active:
			return
		_drag_current_world = _screen_to_world(motion.position)
		instance_drag_updated.emit(_drag_category, _drag_index, _drag_current_world.x, _drag_current_world.y)
		queue_redraw()
		accept_event()


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


func _screen_to_world(screen: Vector2) -> Vector2:
	var usable := Vector2(
		maxf(size.x - _padding_pixels * 2.0, 1.0),
		maxf(size.y - _padding_pixels * 2.0, 1.0)
	)
	var normalized := Vector2(
		(screen.x - _padding_pixels) / usable.x,
		(size.y - _padding_pixels - screen.y) / usable.y
	)
	return Vector2(
		_bounds.position.x + normalized.x * _bounds.size.x,
		_bounds.position.y + normalized.y * _bounds.size.y
	)


func _finish_drag() -> void:
	if not _drag_active:
		return
	var moved := _drag_current_world.distance_to(_drag_start_world) > 0.001
	if moved:
		instance_drag_finished.emit(
			_drag_category,
			_drag_index,
			_drag_start_world.x,
			_drag_start_world.y,
			_drag_current_world.x,
			_drag_current_world.y
		)
	_cancel_drag()
	queue_redraw()


func _cancel_drag() -> void:
	_drag_active = false
	_drag_category = ""
	_drag_index = -1
	_drag_start_world = Vector2.ZERO
	_drag_current_world = Vector2.ZERO


func _finish_rotate() -> void:
	if not _rotate_active:
		return
	var changed := absf(_rotate_preview_bearing - _rotate_start_bearing) > 0.001
	if changed:
		instance_rotate_finished.emit(
			_rotate_category,
			_rotate_index,
			_rotate_start_bearing,
			_rotate_preview_bearing
		)
	_cancel_rotate()
	queue_redraw()


func _cancel_rotate() -> void:
	_rotate_active = false
	_rotate_category = ""
	_rotate_index = -1
	_rotate_start_bearing = 0.0
	_rotate_preview_bearing = 0.0


static func _bearing_from_world_point(instance_world: Vector2, cursor_world: Vector2) -> float:
	return KotorWorldCoordinates.bearing_from_kotor_xy_offset(instance_world, cursor_world)


func _find_record(category: String, index: int) -> Dictionary:
	for record in _records:
		if str(record.get("category", "")) == category and int(record.get("index", -1)) == index:
			return record
	return {}
