@tool
extends RefCounted
class_name KotorWorldCoordinates

## Maps KotOR world space (X/Y horizontal, Z vertical) to Godot 3D (Y up).


static func kotor_to_godot(position: Vector3) -> Vector3:
	return Vector3(position.x, position.z, -position.y)


static func godot_to_kotor(position: Vector3) -> Vector3:
	return Vector3(position.x, -position.z, position.y)


static func kotor_bearing_to_yaw(bearing: float) -> float:
	# KotOR GIT bearing is radians in the XY plane; Godot yaw rotates around Y.
	return -bearing


static func bearing_from_kotor_xy_offset(from_xy: Vector2, to_xy: Vector2) -> float:
	var offset := to_xy - from_xy
	if offset.length_squared() < 0.000001:
		return 0.0
	return atan2(offset.y, offset.x)


static func godot_ray_to_kotor_xy(
	ray_origin: Vector3,
	ray_direction: Vector3,
	plane_height_godot_y: float
) -> Vector2:
	if absf(ray_direction.y) < 0.000001:
		return Vector2(NAN, NAN)
	var t := (plane_height_godot_y - ray_origin.y) / ray_direction.y
	if t < 0.0:
		return Vector2(NAN, NAN)
	var hit := ray_origin + ray_direction * t
	var kotor := godot_to_kotor(hit)
	return Vector2(kotor.x, kotor.y)
