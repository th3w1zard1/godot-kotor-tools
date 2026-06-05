@tool
extends SceneTree

const KotorWorldCoordinates := preload("../../editor/module/kotor_world_coordinates.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_bearing_from_kotor_xy_offset()
	_test_bearing_cardinal_directions()
	_test_godot_ray_to_kotor_xy()
	_test_godot_ray_parallel_returns_nan()
	print("✓ GIT viewport bearing tests passed")
	quit()


func _test_bearing_from_kotor_xy_offset() -> void:
	var bearing := KotorWorldCoordinates.bearing_from_kotor_xy_offset(
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0)
	)
	assert(is_equal_approx(bearing, 0.0))
	print("✓ Viewport bearing offset passed")


func _test_bearing_cardinal_directions() -> void:
	var north := KotorWorldCoordinates.bearing_from_kotor_xy_offset(
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0)
	)
	assert(is_equal_approx(north, PI * 0.5))
	print("✓ Viewport bearing cardinal passed")


func _test_godot_ray_to_kotor_xy() -> void:
	var kotor_pos := Vector3(10.0, 20.0, 3.0)
	var godot_pos := KotorWorldCoordinates.kotor_to_godot(kotor_pos)
	var hit := KotorWorldCoordinates.godot_ray_to_kotor_xy(
		godot_pos + Vector3(0.0, 5.0, 0.0),
		Vector3(0.0, -1.0, 0.0),
		godot_pos.y
	)
	assert(is_equal_approx(hit.x, kotor_pos.x))
	assert(is_equal_approx(hit.y, kotor_pos.y))
	print("✓ Viewport godot ray to kotor xy passed")


func _test_godot_ray_parallel_returns_nan() -> void:
	var hit := KotorWorldCoordinates.godot_ray_to_kotor_xy(
		Vector3.ZERO,
		Vector3(1.0, 0.0, 0.0),
		0.0
	)
	assert(is_nan(hit.x))
	print("✓ Viewport godot ray parallel passed")
