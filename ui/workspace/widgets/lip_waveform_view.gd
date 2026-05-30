@tool
extends Control
class_name LipWaveformView

signal seek_requested(time_seconds: float)

const _MARGIN := Vector2(4.0, 4.0)

var _peaks: PackedFloat32Array = PackedFloat32Array()
var _duration := 0.0
var _playhead := 0.0
var _keyframe_times: PackedFloat32Array = PackedFloat32Array()


func set_peaks(peaks: PackedFloat32Array, duration_seconds: float) -> void:
	_peaks = peaks
	_duration = maxf(duration_seconds, 0.0)
	queue_redraw()


func clear_peaks() -> void:
	_peaks = PackedFloat32Array()
	_duration = 0.0
	_playhead = 0.0
	_keyframe_times = PackedFloat32Array()
	queue_redraw()


func set_playhead(time_seconds: float) -> void:
	if _duration <= 0.0:
		_playhead = 0.0
	else:
		_playhead = clampf(time_seconds, 0.0, _duration)
	queue_redraw()


func set_keyframe_times(times: PackedFloat32Array) -> void:
	_keyframe_times = times
	queue_redraw()


func get_duration() -> float:
	return _duration


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_emit_seek_from_position(mouse.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_emit_seek_from_position(motion.position)


func _emit_seek_from_position(local_pos: Vector2) -> void:
	if _duration <= 0.0 or _peaks.is_empty():
		return
	var draw_rect := _draw_rect()
	if draw_rect.size.x <= 0.0:
		return
	var ratio := clampf((local_pos.x - draw_rect.position.x) / draw_rect.size.x, 0.0, 1.0)
	seek_requested.emit(ratio * _duration)


func _draw_rect() -> Rect2:
	return Rect2(
		_MARGIN,
		Vector2(maxf(size.x - _MARGIN.x * 2.0, 1.0), maxf(size.y - _MARGIN.y * 2.0, 1.0))
	)


func _draw() -> void:
	var rect := _draw_rect()
	draw_rect(rect, Color(0.12, 0.12, 0.14, 1.0), false, 1.0)

	if _peaks.is_empty() or _duration <= 0.0:
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(4.0, rect.size.y * 0.5),
			"Load a PCM WAV to show waveform",
			HORIZONTAL_ALIGNMENT_LEFT,
			int(rect.size.x),
			12,
			Color(0.65, 0.65, 0.7)
		)
		return

	var mid_y := rect.position.y + rect.size.y * 0.5
	var bar_width := rect.size.x / float(_peaks.size())
	var wave_color := Color(0.35, 0.75, 0.95, 0.95)
	for i in _peaks.size():
		var peak := clampf(_peaks[i], 0.0, 1.0)
		var x := rect.position.x + float(i) * bar_width
		var height := peak * rect.size.y * 0.45
		draw_line(Vector2(x, mid_y - height), Vector2(x, mid_y + height), wave_color, maxf(bar_width, 1.0))

	for time in _keyframe_times:
		var ratio := clampf(float(time) / _duration, 0.0, 1.0)
		var x := rect.position.x + ratio * rect.size.x
		draw_line(
			Vector2(x, rect.position.y),
			Vector2(x, rect.position.y + rect.size.y),
			Color(0.95, 0.85, 0.25, 0.85),
			1.0
		)

	if _playhead >= 0.0:
		var play_ratio := clampf(_playhead / _duration, 0.0, 1.0)
		var play_x := rect.position.x + play_ratio * rect.size.x
		draw_line(
			Vector2(play_x, rect.position.y),
			Vector2(play_x, rect.position.y + rect.size.y),
			Color(1.0, 0.35, 0.35, 1.0),
			2.0
		)
