@tool
extends Control
class_name IndoorBuilderMapView

signal room_selected(index: int)
signal room_drag_updated(index: int, x: float, y: float)
signal room_drag_finished(index: int, old_x: float, old_y: float, new_x: float, new_y: float)
signal room_rotate_updated(index: int, rotation: float)
signal room_rotate_finished(index: int, old_rotation: float, new_rotation: float)

const KotorIndoorDocument := preload("../../../resources/documents/kotor_indoor_document.gd")

var _records: Array[Dictionary] = []
var _bounds := Rect2(-10, -10, 20, 20)
var _selected_index := -1
var _padding_pixels := 24.0
var _drag_active := false
var _drag_index := -1
var _drag_start_world := Vector2.ZERO
var _drag_current_world := Vector2.ZERO
var _rotate_active := false
var _rotate_index := -1
var _rotate_start_rotation := 0.0
var _rotate_preview_rotation := 0.0


func set_rooms(records: Array, bounds: Rect2) -> void:
	_records.clear()
	for raw_record in records:
		if typeof(raw_record) == TYPE_DICTIONARY:
			_records.append(raw_record)
	_bounds = bounds if bounds.size.x > 0.0 and bounds.size.y > 0.0 else Rect2(-10, -10, 20, 20)
	_cancel_drag()
	_cancel_rotate()
	queue_redraw()


func set_selection(index: int) -> void:
	_selected_index = index
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.11, 0.14))
	_draw_grid()
	for record in _records:
		_draw_room(record)
	if _selected_index >= 0:
		var selected := _find_record(_selected_index)
		if not selected.is_empty():
			var corners := _record_world_corners(selected)
			if corners.size() >= 3:
				var screen_corners := PackedVector2Array()
				for corner in corners:
					screen_corners.append(_world_to_screen(corner))
				screen_corners.append(screen_corners[0])
				draw_polyline(screen_corners, Color(1.0, 1.0, 1.0), 2.0)


func _draw_grid() -> void:
	var grid_color := Color(0.22, 0.24, 0.28)
	var step_count := 8
	for step in range(step_count + 1):
		var t := float(step) / float(step_count)
		var x := lerpf(_padding_pixels, size.x - _padding_pixels, t)
		var y := lerpf(_padding_pixels, size.y - _padding_pixels, t)
		draw_line(Vector2(x, _padding_pixels), Vector2(x, size.y - _padding_pixels), grid_color, 1.0)
		draw_line(Vector2(_padding_pixels, y), Vector2(size.x - _padding_pixels, y), grid_color, 1.0)


func _draw_room(record: Dictionary) -> void:
	var index := int(record.get("index", -1))
	var world_corners := _record_world_corners(record)
	if world_corners.size() < 3:
		return
	var screen_corners := PackedVector2Array()
	for corner in world_corners:
		screen_corners.append(_world_to_screen(corner))
	var fill := Color(0.28, 0.45, 0.62, 0.55)
	if index == _selected_index:
		fill = Color(0.38, 0.62, 0.82, 0.72)
	draw_colored_polygon(screen_corners, fill)
	draw_polyline(screen_corners, fill.lightened(0.25), 1.5, true)

	var center := _record_center(record)
	var center_screen := _world_to_screen(center)
	var rotation := float(record.get("rotation", 0.0))
	if _rotate_active and index == _rotate_index:
		rotation = _rotate_preview_rotation
	if absf(rotation) > 0.001:
		var direction := Vector2.RIGHT.rotated(-rotation) * 10.0
		draw_line(center_screen, center_screen + direction, Color(0.9, 0.9, 0.85), 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				var picked := _pick_room(mouse_event.position)
				if picked.is_empty():
					return
				var index := int(picked.get("index", -1))
				room_selected.emit(index)
				_rotate_active = true
				_rotate_index = index
				_rotate_start_rotation = float(picked.get("rotation", 0.0))
				_rotate_preview_rotation = _rotate_start_rotation
				accept_event()
				return
			if _rotate_active:
				_finish_rotate()
				accept_event()
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			var picked := _pick_room(mouse_event.position)
			if picked.is_empty():
				return
			var index := int(picked.get("index", -1))
			room_selected.emit(index)
			_drag_active = true
			_drag_index = index
			_drag_start_world = _record_center(picked)
			_drag_current_world = _drag_start_world
			accept_event()
			return
		if _drag_active:
			_finish_drag()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _rotate_active:
			var record := _find_record(_rotate_index)
			if record.is_empty():
				_cancel_rotate()
				return
			var center := _record_center(record)
			var cursor_world := _screen_to_world(motion.position)
			_rotate_preview_rotation = _bearing_from_world_point(center, cursor_world)
			room_rotate_updated.emit(_rotate_index, _rotate_preview_rotation)
			queue_redraw()
			accept_event()
			return
		if not _drag_active:
			return
		_drag_current_world = _screen_to_world(motion.position)
		room_drag_updated.emit(_drag_index, _drag_current_world.x, _drag_current_world.y)
		queue_redraw()
		accept_event()


func _pick_room(screen_point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for record in _records:
		var corners := _record_world_corners(record)
		var screen_corners := PackedVector2Array()
		for corner in corners:
			screen_corners.append(_world_to_screen(corner))
		if screen_corners.size() >= 3 and Geometry2D.is_point_in_polygon(screen_point, screen_corners):
			var center := _world_to_screen(_record_center(record))
			var distance := center.distance_to(screen_point)
			if distance < best_distance:
				best_distance = distance
				best = record
	return best


func _record_center(record: Dictionary) -> Vector2:
	var index := int(record.get("index", -1))
	if _drag_active and index == _drag_index:
		return _drag_current_world
	return Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))


func _record_world_corners(record: Dictionary) -> PackedVector2Array:
	var working := record.duplicate(true)
	if int(working.get("index", -1)) == _drag_index and _drag_active:
		working["x"] = _drag_current_world.x
		working["y"] = _drag_current_world.y
	if int(working.get("index", -1)) == _rotate_index and _rotate_active:
		working["rotation"] = _rotate_preview_rotation
	return KotorIndoorDocument._room_world_corners(working)


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
		room_drag_finished.emit(
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
	_drag_index = -1
	_drag_start_world = Vector2.ZERO
	_drag_current_world = Vector2.ZERO


func _finish_rotate() -> void:
	if not _rotate_active:
		return
	var changed := absf(_rotate_preview_rotation - _rotate_start_rotation) > 0.001
	if changed:
		room_rotate_finished.emit(
			_rotate_index,
			_rotate_start_rotation,
			_rotate_preview_rotation
		)
	_cancel_rotate()
	queue_redraw()


func _cancel_rotate() -> void:
	_rotate_active = false
	_rotate_index = -1
	_rotate_start_rotation = 0.0
	_rotate_preview_rotation = 0.0


static func _bearing_from_world_point(instance_world: Vector2, cursor_world: Vector2) -> float:
	var offset := cursor_world - instance_world
	if offset.length_squared() < 0.000001:
		return 0.0
	return atan2(offset.y, offset.x)


func _find_record(index: int) -> Dictionary:
	for record in _records:
		if int(record.get("index", -1)) == index:
			return record
	return {}
