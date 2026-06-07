@tool
extends Control
class_name ModuleDesignerMapView

const KotorWorldCoordinates := preload("../../../editor/module/kotor_world_coordinates.gd")

signal instance_selected(category: String, index: int)
signal path_point_selected(index: int)
signal path_connection_selected(index: int)
signal instance_drag_updated(category: String, index: int, x: float, y: float)
signal instance_drag_finished(
	category: String,
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
)
signal path_point_drag_finished(index: int, old_x: float, old_y: float, new_x: float, new_y: float)
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
var _selected_path_point_index := -1
var _selected_path_connection_index := -1
var _padding_pixels := 24.0
var _drag_active := false
var _drag_category := ""
var _drag_index := -1
var _drag_start_world := Vector2.ZERO
var _drag_current_world := Vector2.ZERO
var _path_drag_active := false
var _path_drag_index := -1
var _path_drag_start_world := Vector2.ZERO
var _path_drag_current_world := Vector2.ZERO
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
	_cancel_path_drag()
	_cancel_rotate()
	queue_redraw()


func set_selection(category: String, index: int) -> void:
	_selected_category = category
	_selected_index = index
	if not category.is_empty() and index >= 0:
		_selected_path_point_index = -1
		_selected_path_connection_index = -1
	queue_redraw()


func set_path_point_selection(index: int) -> void:
	_selected_path_point_index = index
	if index >= 0:
		_selected_category = ""
		_selected_index = -1
		_selected_path_connection_index = -1
	queue_redraw()


func set_path_connection_selection(index: int) -> void:
	_selected_path_connection_index = index
	if index >= 0:
		_selected_category = ""
		_selected_index = -1
		_selected_path_point_index = -1
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
		var source := _world_to_screen(_path_edge_endpoint_world(edge_record, true))
		var target := _world_to_screen(_path_edge_endpoint_world(edge_record, false))
		var highlighted := _path_edge_highlighted(edge_record)
		draw_line(
			source,
			target,
			path_color.lightened(0.25) if highlighted else path_color,
			2.5 if highlighted else 1.5
		)


func _draw_path_points() -> void:
	var path_color := Color(0.2, 0.95, 0.95, 0.95)
	for point_record in _path_points:
		var point := _world_to_screen(_path_point_world(point_record))
		var highlighted := _path_point_highlighted(point_record)
		var fill := path_color.lightened(0.25) if highlighted else path_color
		draw_circle(point, 4.75 if highlighted else 3.5, fill)
		draw_arc(point, 7.0 if highlighted else 5.5, 0.0, TAU, 18, fill.darkened(0.35), 1.75 if highlighted else 1.5)


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
			if not picked.is_empty():
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
			var picked_point := _pick_path_point(mouse_event.position)
			if not picked_point.is_empty():
				var point_index := int(picked_point.get("index", -1))
				path_point_selected.emit(point_index)
				_path_drag_active = true
				_path_drag_index = point_index
				_path_drag_start_world = _path_point_world(picked_point)
				_path_drag_current_world = _path_drag_start_world
				accept_event()
				return
			var picked_connection := _pick_path_connection(mouse_event.position)
			if not picked_connection.is_empty():
				path_connection_selected.emit(int(picked_connection.get("index", -1)))
				accept_event()
				return
		if _drag_active:
			_finish_drag()
			accept_event()
		elif _path_drag_active:
			_finish_path_drag()
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
		if _path_drag_active:
			_path_drag_current_world = _screen_to_world(motion.position)
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


func _pick_path_point(screen_point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 10.0
	var best_index := 0x7fffffff
	for point_record in _path_points:
		var point := _world_to_screen(_path_point_world(point_record))
		var distance := point.distance_to(screen_point)
		var point_index := int(point_record.get("index", 0x7fffffff))
		if distance < best_distance or (distance == best_distance and point_index < best_index):
			best_distance = distance
			best_index = point_index
			best = point_record
	return best if best_distance <= 10.0 else {}


func _pick_path_connection(screen_point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 8.0
	var best_index := 0x7fffffff
	for edge_record in _path_edges:
		var source := _world_to_screen(Vector2(float(edge_record.get("source_x", 0.0)), float(edge_record.get("source_y", 0.0))))
		var target := _world_to_screen(Vector2(float(edge_record.get("target_x", 0.0)), float(edge_record.get("target_y", 0.0))))
		var distance := _point_to_segment_distance(screen_point, source, target)
		var edge_index := int(edge_record.get("index", 0x7fffffff))
		if distance < best_distance or (is_equal_approx(distance, best_distance) and edge_index < best_index):
			best_distance = distance
			best_index = edge_index
			best = edge_record
	return best if best_distance <= 8.0 else {}


func _path_edge_highlighted(edge_record: Dictionary) -> bool:
	if int(edge_record.get("index", -1)) == _selected_path_connection_index:
		return true
	return (
		int(edge_record.get("source_index", -1)) == _selected_path_point_index
		or int(edge_record.get("target_index", -1)) == _selected_path_point_index
	)


func _path_point_highlighted(point_record: Dictionary) -> bool:
	var point_index := int(point_record.get("index", -1))
	if point_index == _selected_path_point_index:
		return true
	if _selected_path_connection_index < 0:
		return false
	var connection_record := _path_connection_record_by_index(_selected_path_connection_index)
	return (
		point_index == int(connection_record.get("source_index", -2))
		or point_index == int(connection_record.get("target_index", -2))
	)


func _path_connection_record_by_index(index: int) -> Dictionary:
	for edge_record in _path_edges:
		if int(edge_record.get("index", -1)) == index:
			return edge_record
	return {}


static func _point_to_segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_sq := segment.length_squared()
	if is_zero_approx(length_sq):
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_sq, 0.0, 1.0)
	var closest := start + segment * t
	return point.distance_to(closest)


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


func _finish_path_drag() -> void:
	if not _path_drag_active:
		return
	var moved := _path_drag_current_world.distance_to(_path_drag_start_world) > 0.001
	if moved:
		path_point_drag_finished.emit(
			_path_drag_index,
			_path_drag_start_world.x,
			_path_drag_start_world.y,
			_path_drag_current_world.x,
			_path_drag_current_world.y
		)
	_cancel_path_drag()
	queue_redraw()


func _cancel_path_drag() -> void:
	_path_drag_active = false
	_path_drag_index = -1
	_path_drag_start_world = Vector2.ZERO
	_path_drag_current_world = Vector2.ZERO


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


func _path_point_world(point_record: Dictionary) -> Vector2:
	var point_index := int(point_record.get("index", -1))
	if _path_drag_active and point_index == _path_drag_index:
		return _path_drag_current_world
	return Vector2(float(point_record.get("x", 0.0)), float(point_record.get("y", 0.0)))


func _path_edge_endpoint_world(edge_record: Dictionary, use_source: bool) -> Vector2:
	var point_index := int(edge_record.get("source_index", -1)) if use_source else int(edge_record.get("target_index", -1))
	if _path_drag_active and point_index == _path_drag_index:
		return _path_drag_current_world
	var x_key := "source_x" if use_source else "target_x"
	var y_key := "source_y" if use_source else "target_y"
	return Vector2(float(edge_record.get(x_key, 0.0)), float(edge_record.get(y_key, 0.0)))
