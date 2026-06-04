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
