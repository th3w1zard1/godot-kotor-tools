## PyKotor-compatible indoor door-hook position and connection rebuild (headless).
class_name KotorIndoorHookConnections

const SNAP_DISTANCE := 0.001


static func hook_local_position(hook: Dictionary) -> Vector3:
	if hook.has("position"):
		var raw: Variant = hook.get("position", [])
		if typeof(raw) == TYPE_ARRAY:
			var values: Array = raw
			return Vector3(
				float(values[0]) if values.size() > 0 else 0.0,
				float(values[1]) if values.size() > 1 else 0.0,
				float(values[2]) if values.size() > 2 else 0.0
			)
	return Vector3(
		float(hook.get("x", 0.0)),
		float(hook.get("y", 0.0)),
		float(hook.get("z", 0.0))
	)


static func hook_world_position(room: Dictionary, hook: Dictionary) -> Vector3:
	var pos := hook_local_position(hook)
	if bool(room.get("flip_x", false)):
		pos.x = -pos.x
	if bool(room.get("flip_y", false)):
		pos.y = -pos.y
	var rotation_deg := float(room.get("rotation", 0.0))
	var cos_r := cos(deg_to_rad(rotation_deg))
	var sin_r := sin(deg_to_rad(rotation_deg))
	var rotated := Vector3(
		pos.x * cos_r - pos.y * sin_r,
		pos.x * sin_r + pos.y * cos_r,
		pos.z
	)
	var room_pos := _read_room_position(room)
	return rotated + room_pos


static func rebuild_connections(rooms: Array, hooks_for_room: Callable) -> Array:
	var per_room: Array = []
	for room_index in rooms.size():
		var room: Dictionary = rooms[room_index] if typeof(rooms[room_index]) == TYPE_DICTIONARY else {}
		var hooks: Array = hooks_for_room.call(room_index, room) if hooks_for_room.is_valid() else []
		var connections: Array = []
		for _hook_index in hooks.size():
			connections.append(-1)
		per_room.append(connections)

	for room_index in rooms.size():
		var room: Dictionary = rooms[room_index] if typeof(rooms[room_index]) == TYPE_DICTIONARY else {}
		var hooks: Array = hooks_for_room.call(room_index, room) if hooks_for_room.is_valid() else []
		var room_connections: Array = per_room[room_index]
		for hook_index in hooks.size():
			if typeof(hooks[hook_index]) != TYPE_DICTIONARY:
				continue
			var hook: Dictionary = hooks[hook_index]
			var hook_pos := hook_world_position(room, hook)
			for other_index in rooms.size():
				if other_index == room_index:
					continue
				var other_room: Dictionary = (
					rooms[other_index] if typeof(rooms[other_index]) == TYPE_DICTIONARY else {}
				)
				var other_hooks: Array = (
					hooks_for_room.call(other_index, other_room) if hooks_for_room.is_valid() else []
				)
				for other_hook in other_hooks:
					if typeof(other_hook) != TYPE_DICTIONARY:
						continue
					var other_pos := hook_world_position(other_room, other_hook as Dictionary)
					if hook_pos.distance_to(other_pos) < SNAP_DISTANCE:
						room_connections[hook_index] = other_index
						break
				if int(room_connections[hook_index]) >= 0:
					break
	return per_room


static func count_connected_hooks(per_room_connections: Array) -> Dictionary:
	var connected := 0
	var open := 0
	for raw_connections in per_room_connections:
		if typeof(raw_connections) != TYPE_ARRAY:
			continue
		for target in raw_connections:
			if int(target) >= 0:
				connected += 1
			else:
				open += 1
	return {"connected": connected, "open": open}


static func _read_room_position(room: Dictionary) -> Vector3:
	var raw: Variant = room.get("position", [0.0, 0.0, 0.0])
	if typeof(raw) != TYPE_ARRAY:
		return Vector3.ZERO
	var values: Array = raw
	return Vector3(
		float(values[0]) if values.size() > 0 else 0.0,
		float(values[1]) if values.size() > 1 else 0.0,
		float(values[2]) if values.size() > 2 else 0.0
	)
