@tool
extends SubViewportContainer
class_name MdlPreviewViewport

const MDLParser := preload("../../../formats/mdl_parser.gd")
const MdlMeshSurfaceBuilder := preload("../../../editor/tools/mdl_mesh_surface_builder.gd")
const KotorWorldCoordinates := preload("../../../editor/module/kotor_world_coordinates.gd")

var _viewport: SubViewport
var _camera: Camera3D
var _mesh_root: Node3D
var _mesh_instance: MeshInstance3D
var _parsed: Dictionary = {}
var _orbit_yaw := 0.6
var _orbit_pitch := -0.45
var _orbit_distance := 8.0
var _orbit_focus := Vector3.ZERO
var _dragging := false
var _last_mouse := Vector2.ZERO


func _init() -> void:
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(320, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_scene()


func _build_scene() -> void:
	_viewport = SubViewport.new()
	_viewport.handle_input_locally = true
	_viewport.size = Vector2i(640, 480)
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)

	var world := Node3D.new()
	_viewport.add_child(world)

	_camera = Camera3D.new()
	_camera.current = true
	world.add_child(_camera)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	world.add_child(sun)

	_mesh_root = Node3D.new()
	_mesh_root.name = "ModelMesh"
	world.add_child(_mesh_root)


func _ready() -> void:
	_update_camera_transform()


func set_mdl_bytes(mdl_bytes: PackedByteArray, mdx_bytes: PackedByteArray = PackedByteArray()) -> void:
	_parsed = MDLParser.parse_bytes(mdl_bytes, mdx_bytes)
	_rebuild_mesh()
	_fit_camera_to_mesh()


func clear_preview() -> void:
	_parsed = {}
	_rebuild_mesh()
	_orbit_focus = Vector3.ZERO
	_orbit_distance = 8.0
	_update_camera_transform()


func has_valid_mesh() -> bool:
	return _mesh_instance != null and _mesh_instance.mesh != null


func get_triangle_count() -> int:
	return MdlMeshSurfaceBuilder.triangle_count(_parsed)


func get_orbit_distance() -> float:
	return _orbit_distance


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse_button.pressed
			_last_mouse = mouse_button.position
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_orbit_distance = maxf(1.0, _orbit_distance * 0.9)
			_update_camera_transform()
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_orbit_distance = minf(500.0, _orbit_distance * 1.1)
			_update_camera_transform()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		var delta := motion.position - _last_mouse
		_last_mouse = motion.position
		_orbit_yaw -= delta.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch - delta.y * 0.01, -1.4, 1.4)
		_update_camera_transform()


func _rebuild_mesh() -> void:
	if _mesh_root == null:
		return
	for child in _mesh_root.get_children():
		child.queue_free()
	_mesh_instance = null
	if _parsed.is_empty():
		return

	var mesh := MdlMeshSurfaceBuilder.build_from_parsed(_parsed)
	if mesh == null:
		return
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "MdlPreviewMesh"
	_mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.72, 0.95, 0.9)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = material
	_mesh_root.add_child(_mesh_instance)


func _fit_camera_to_mesh() -> void:
	if _parsed.is_empty():
		_orbit_focus = Vector3.ZERO
		_orbit_distance = 8.0
		_update_camera_transform()
		return
	var kotor_bounds := MDLParser.compute_bounds(_parsed)
	if kotor_bounds.size == Vector3.ZERO:
		_orbit_focus = Vector3.ZERO
		_orbit_distance = 8.0
		_update_camera_transform()
		return
	var corners := [
		kotor_bounds.position,
		kotor_bounds.position + Vector3(kotor_bounds.size.x, 0.0, 0.0),
		kotor_bounds.position + Vector3(0.0, kotor_bounds.size.y, 0.0),
		kotor_bounds.position + Vector3(0.0, 0.0, kotor_bounds.size.z),
		kotor_bounds.end,
	]
	var min_pos := Vector3(INF, INF, INF)
	var max_pos := Vector3(-INF, -INF, -INF)
	for corner in corners:
		var godot_pos := KotorWorldCoordinates.kotor_to_godot(corner)
		min_pos = min_pos.min(godot_pos)
		max_pos = max_pos.max(godot_pos)
	_orbit_focus = (min_pos + max_pos) * 0.5
	var span := (max_pos - min_pos).length()
	_orbit_distance = maxf(4.0, span * 1.8)
	_update_camera_transform()


func _update_camera_transform() -> void:
	if _camera == null:
		return
	var offset := Vector3(
		cos(_orbit_pitch) * sin(_orbit_yaw),
		sin(_orbit_pitch),
		cos(_orbit_pitch) * cos(_orbit_yaw)
	) * _orbit_distance
	_camera.position = _orbit_focus + offset
	_camera.look_at(_orbit_focus, Vector3.UP)
