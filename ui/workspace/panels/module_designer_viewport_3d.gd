@tool
extends SubViewportContainer
class_name ModuleDesignerViewport3D

signal instance_selected(category: String, index: int)
signal instance_rotate_updated(category: String, index: int, bearing: float)
signal instance_rotate_finished(
	category: String,
	index: int,
	old_bearing: float,
	new_bearing: float
)

const KotorGITDocument := preload("../../../resources/documents/kotor_git_document.gd")
const KotorWorldCoordinates := preload("../../../editor/module/kotor_world_coordinates.gd")
const BWMParser := preload("../../../formats/bwm_parser.gd")
const MDLParser := preload("../../../formats/mdl_parser.gd")

var _viewport: SubViewport
var _camera: Camera3D
var _instances_root: Node3D
var _layout_root: Node3D
var _room_mesh_root: Node3D
var _walkmesh_root: Node3D
var _path_root: Node3D
var _records: Array[Dictionary] = []
var _path_points: Array[Dictionary] = []
var _parsed_layout: Dictionary = {}
var _room_meshes: Array = []
var _instance_mesh_by_key: Dictionary = {}
var _walkmesh: Dictionary = {}
var _selected_category := ""
var _selected_index := -1
var _marker_nodes: Dictionary = {}
var _orbit_yaw := 0.6
var _orbit_pitch := -0.45
var _orbit_distance := 40.0
var _orbit_focus := Vector3.ZERO
var _dragging := false
var _last_mouse := Vector2.ZERO
var _rotate_active := false
var _rotate_category := ""
var _rotate_index := -1
var _rotate_start_bearing := 0.0
var _rotate_preview_bearing := 0.0
var _rotate_gizmo_root: Node3D


func _init() -> void:
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(200, 160)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_scene()


func _build_scene() -> void:
	_viewport = SubViewport.new()
	_viewport.handle_input_locally = true
	_viewport.size = Vector2i(640, 360)
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

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -120, 0)
	fill.light_energy = 0.35
	world.add_child(fill)

	_instances_root = Node3D.new()
	_instances_root.name = "Instances"
	world.add_child(_instances_root)

	_layout_root = Node3D.new()
	_layout_root.name = "Layout"
	world.add_child(_layout_root)

	_room_mesh_root = Node3D.new()
	_room_mesh_root.name = "RoomMeshes"
	world.add_child(_room_mesh_root)

	_walkmesh_root = Node3D.new()
	_walkmesh_root.name = "Walkmesh"
	world.add_child(_walkmesh_root)

	_path_root = Node3D.new()
	_path_root.name = "PathGraph"
	world.add_child(_path_root)

	_rotate_gizmo_root = Node3D.new()
	_rotate_gizmo_root.name = "RotateGizmo"
	world.add_child(_rotate_gizmo_root)


func _ready() -> void:
	_update_camera_transform()


func set_instances(records: Array, layout: Dictionary = {}) -> void:
	_records.clear()
	for raw_record in records:
		if typeof(raw_record) == TYPE_DICTIONARY:
			_records.append(raw_record)
	_parsed_layout = layout if typeof(layout) == TYPE_DICTIONARY else {}
	_rebuild_markers()
	_fit_camera_to_content()
	queue_redraw()


func set_walkmesh(parsed: Dictionary) -> void:
	_walkmesh = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	_rebuild_walkmesh()
	_fit_camera_to_content()


func set_room_meshes(entries: Array) -> void:
	_room_meshes.clear()
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		_room_meshes.append(raw_entry)
	_rebuild_room_meshes()
	_rebuild_markers()
	_fit_camera_to_content()


func set_instance_meshes(entries: Array) -> void:
	_instance_mesh_by_key.clear()
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var mesh_dict: Dictionary = entry.get("mesh", {})
		if mesh_dict.is_empty():
			continue
		var key := "%s:%d" % [str(entry.get("category", "")), int(entry.get("index", -1))]
		_instance_mesh_by_key[key] = mesh_dict
	_rebuild_markers()
	_fit_camera_to_content()


func set_path_points(entries: Array) -> void:
	_path_points.clear()
	for raw_entry in entries:
		if typeof(raw_entry) == TYPE_DICTIONARY:
			_path_points.append(raw_entry)
	_rebuild_path_points()
	_fit_camera_to_content()


func set_selection(category: String, index: int) -> void:
	_selected_category = category
	_selected_index = index
	_refresh_marker_highlights()
	_rebuild_rotate_gizmo()


func set_preview_bearing(category: String, index: int, bearing: float) -> void:
	var key := "%s:%d" % [category, index]
	if not _marker_nodes.has(key):
		return
	var area: Area3D = _marker_nodes[key]
	area.rotation.y = KotorWorldCoordinates.kotor_bearing_to_yaw(bearing)
	_update_rotate_gizmo_rotation(bearing)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not stretch and _viewport != null:
		_viewport.size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))


func _gui_input(event: InputEvent) -> void:
	if _viewport == null or _camera == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var picked := _pick_instance(mouse_event.position)
			if not picked.is_empty():
				instance_selected.emit(str(picked.get("category", "")), int(picked.get("index", -1)))
				accept_event()
				return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed and mouse_event.shift_pressed and _has_selection():
				_begin_rotate(mouse_event.position)
				accept_event()
				return
			if not mouse_event.pressed and _rotate_active:
				_finish_rotate()
				accept_event()
				return
			_dragging = mouse_event.pressed and not _rotate_active
			_last_mouse = mouse_event.position
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_orbit_distance = maxf(5.0, _orbit_distance * 0.9)
			_update_camera_transform()
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_orbit_distance = minf(500.0, _orbit_distance * 1.1)
			_update_camera_transform()
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _rotate_active:
			_update_rotate_preview(motion.position)
			accept_event()
			return
		if _dragging:
			var delta := motion.position - _last_mouse
			_last_mouse = motion.position
			_orbit_yaw -= delta.x * 0.01
			_orbit_pitch = clampf(_orbit_pitch - delta.y * 0.01, -1.4, -0.1)
			_update_camera_transform()


func _rebuild_markers() -> void:
	if _instances_root == null or _layout_root == null:
		return
	for child in _instances_root.get_children():
		child.queue_free()
	for child in _layout_root.get_children():
		child.queue_free()
	_marker_nodes.clear()

	for room in _parsed_layout.get("rooms", []):
		if typeof(room) != TYPE_DICTIONARY:
			continue
		var room_dict: Dictionary = room
		var model_name := str(room_dict.get("model", "room"))
		if _room_mesh_for_model(model_name).is_empty():
			var position: Vector3 = room_dict.get("position", Vector3.ZERO)
			var marker := _make_box_marker(
				KotorWorldCoordinates.kotor_to_godot(position),
				Vector3(6.0, 3.0, 6.0),
				Color(0.35, 0.55, 0.85, 0.25),
				true
			)
			marker.name = "Room_%s" % model_name
			_layout_root.add_child(marker)

	for track in _parsed_layout.get("tracks", []):
		if typeof(track) != TYPE_DICTIONARY:
			continue
		var track_dict: Dictionary = track
		var track_position: Vector3 = track_dict.get("position", Vector3.ZERO)
		var track_marker := _make_box_marker(
			KotorWorldCoordinates.kotor_to_godot(track_position),
			Vector3(4.0, 0.35, 4.0),
			Color(0.25, 0.85, 0.45, 0.45),
			true
		)
		track_marker.name = "Track_%s" % str(track_dict.get("model", "track"))
		_layout_root.add_child(track_marker)

	for obstacle in _parsed_layout.get("obstacles", []):
		if typeof(obstacle) != TYPE_DICTIONARY:
			continue
		var obstacle_dict: Dictionary = obstacle
		var obstacle_position: Vector3 = obstacle_dict.get("position", Vector3.ZERO)
		var obstacle_marker := _make_box_marker(
			KotorWorldCoordinates.kotor_to_godot(obstacle_position),
			Vector3(3.0, 2.0, 3.0),
			Color(0.9, 0.35, 0.2, 0.4),
			true
		)
		obstacle_marker.name = "Obstacle_%s" % str(obstacle_dict.get("model", "obstacle"))
		_layout_root.add_child(obstacle_marker)

	for hook in _parsed_layout.get("doorhooks", []):
		if typeof(hook) != TYPE_DICTIONARY:
			continue
		var hook_dict: Dictionary = hook
		var hook_position: Vector3 = hook_dict.get("position", Vector3.ZERO)
		var hook_marker := _make_sphere_marker(
			KotorWorldCoordinates.kotor_to_godot(hook_position),
			0.45,
			Color(0.95, 0.85, 0.2, 0.85)
		)
		hook_marker.name = "Doorhook_%s" % str(hook_dict.get("name", "hook"))
		_layout_root.add_child(hook_marker)

	for record in _records:
		var category := str(record.get("category", ""))
		var index := int(record.get("index", -1))
		var key := "%s:%d" % [category, index]
		var kotor_pos := Vector3(
			float(record.get("x", 0.0)),
			float(record.get("y", 0.0)),
			float(record.get("z", 0.0))
		)
		var godot_pos := KotorWorldCoordinates.kotor_to_godot(kotor_pos)
		var color := KotorGITDocument.category_color(category)
		var instance_mesh := _instance_mesh_for_key(key)
		var marker := _make_pickable_marker(record, godot_pos, color, instance_mesh)
		marker.name = "GIT_%s" % key
		_instances_root.add_child(marker)
		_marker_nodes[key] = marker

	_refresh_marker_highlights()
	_rebuild_rotate_gizmo()


func _rebuild_room_meshes() -> void:
	if _room_mesh_root == null:
		return
	for child in _room_mesh_root.get_children():
		child.queue_free()
	for entry in _room_meshes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var mesh_dict: Dictionary = entry.get("mesh", {})
		if mesh_dict.is_empty():
			continue
		var room_position: Vector3 = entry.get("position", Vector3.ZERO)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "RoomMesh_%s" % str(entry.get("model", "room"))
		mesh_instance.mesh = _build_model_mesh_surface(mesh_dict, room_position)
		if mesh_instance.mesh == null:
			continue
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.55, 0.72, 0.95, 0.85)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = material
		_room_mesh_root.add_child(mesh_instance)


func _build_model_mesh_surface(parsed: Dictionary, room_position: Vector3) -> ArrayMesh:
	var vertices: Array = parsed.get("vertices", [])
	var faces: Array = parsed.get("faces", [])
	if vertices.is_empty() or faces.is_empty():
		return null
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for raw_face in faces:
		if typeof(raw_face) != TYPE_DICTIONARY:
			continue
		var face: Dictionary = raw_face
		for key in ["i1", "i2", "i3"]:
			var vertex_index := int(face.get(key, -1))
			if vertex_index < 0 or vertex_index >= vertices.size():
				continue
			var kotor_vertex: Vector3 = vertices[vertex_index] + room_position
			surface_tool.add_vertex(KotorWorldCoordinates.kotor_to_godot(kotor_vertex))
	return surface_tool.commit()


func _room_mesh_for_model(model_name: String) -> Dictionary:
	var normalized := model_name.strip_edges().to_lower()
	for entry in _room_meshes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("model", "")).strip_edges().to_lower() == normalized:
			var mesh_dict: Dictionary = entry.get("mesh", {})
			if typeof(mesh_dict) == TYPE_DICTIONARY and not mesh_dict.is_empty():
				return mesh_dict
	return {}


func _instance_mesh_for_key(key: String) -> Dictionary:
	var mesh_dict: Variant = _instance_mesh_by_key.get(key, {})
	if typeof(mesh_dict) == TYPE_DICTIONARY:
		return mesh_dict
	return {}


func _rebuild_walkmesh() -> void:
	if _walkmesh_root == null:
		return
	for child in _walkmesh_root.get_children():
		child.queue_free()
	if _walkmesh.is_empty():
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "AreaWalkmesh"
	mesh_instance.mesh = _build_walkmesh_surface(_walkmesh)
	if mesh_instance.mesh == null:
		return
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	_walkmesh_root.add_child(mesh_instance)


func _rebuild_path_points() -> void:
	if _path_root == null:
		return
	for child in _path_root.get_children():
		child.queue_free()
	for point_record in _path_points:
		var kotor_pos := Vector3(
			float(point_record.get("x", 0.0)),
			float(point_record.get("y", 0.0)),
			float(point_record.get("z", 0.0))
		)
		var marker := _make_sphere_marker(
			KotorWorldCoordinates.kotor_to_godot(kotor_pos),
			0.28,
			Color(0.2, 0.95, 0.95, 0.9)
		)
		marker.name = "PathPoint_%d" % int(point_record.get("id", int(point_record.get("index", 0))))
		_path_root.add_child(marker)


func _build_walkmesh_surface(parsed: Dictionary) -> ArrayMesh:
	var vertices: Array = parsed.get("vertices", [])
	var faces: Array = parsed.get("faces", [])
	if vertices.is_empty() or faces.is_empty():
		return null
	var offset: Vector3 = parsed.get("position", Vector3.ZERO)
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for raw_face in faces:
		if typeof(raw_face) != TYPE_DICTIONARY:
			continue
		var face: Dictionary = raw_face
		var material_id := int(face.get("material", 0))
		var color := Color(0.25, 0.82, 0.35, 0.38) if BWMParser.is_walkable_material(material_id) else Color(0.9, 0.28, 0.2, 0.32)
		for key in ["i1", "i2", "i3"]:
			var vertex_index := int(face.get(key, -1))
			if vertex_index < 0 or vertex_index >= vertices.size():
				continue
			var kotor_vertex: Vector3 = vertices[vertex_index] + offset
			surface_tool.set_color(color)
			surface_tool.add_vertex(KotorWorldCoordinates.kotor_to_godot(kotor_vertex))
	return surface_tool.commit()


func _make_pickable_marker(record: Dictionary, position: Vector3, color: Color, instance_mesh: Dictionary = {}) -> Area3D:
	var area := Area3D.new()
	area.position = position
	area.set_meta("git_record", record)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	if not instance_mesh.is_empty():
		var mesh_bounds := MDLParser.compute_bounds(instance_mesh)
		if mesh_bounds.size != Vector3.ZERO:
			shape.radius = clampf(mesh_bounds.size.length() * 0.35, 0.55, 4.0)
	collision.shape = shape
	area.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	if not instance_mesh.is_empty():
		mesh_instance.mesh = _build_model_mesh_surface(instance_mesh, Vector3.ZERO)
		if mesh_instance.mesh == null:
			instance_mesh = {}
	if instance_mesh.is_empty():
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 0.7, 0.7)
		mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not instance_mesh.is_empty():
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	area.add_child(mesh_instance)

	var bearing := float(record.get("bearing", 0.0))
	area.rotation.y = KotorWorldCoordinates.kotor_bearing_to_yaw(bearing)
	return area


func _marker_visual_mesh(area: Area3D) -> MeshInstance3D:
	for child in area.get_children():
		if child is MeshInstance3D:
			return child
	return null


func _make_box_marker(position: Vector3, box_size: Vector3, color: Color, wireframe: bool) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = position
	var box := BoxMesh.new()
	box.size = box_size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED if wireframe else BaseMaterial3D.CULL_BACK
	mesh_instance.material_override = material
	return mesh_instance


func _make_sphere_marker(position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = position
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	return mesh_instance


func _refresh_marker_highlights() -> void:
	for key in _marker_nodes.keys():
		var area: Area3D = _marker_nodes[key]
		var record = area.get_meta("git_record", {})
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var category := str(record.get("category", ""))
		var index := int(record.get("index", -1))
		var mesh := _marker_visual_mesh(area)
		if mesh == null or mesh.material_override == null:
			continue
		var material := mesh.material_override as StandardMaterial3D
		var base_color := KotorGITDocument.category_color(category)
		if category == _selected_category and index == _selected_index:
			material.albedo_color = base_color.lightened(0.45)
			area.scale = Vector3.ONE * 1.25
		else:
			material.albedo_color = base_color
			area.scale = Vector3.ONE


func _pick_instance(screen_pos: Vector2) -> Dictionary:
	if _camera == null or _viewport == null or size.x <= 0.0 or size.y <= 0.0:
		return {}
	var viewport_pos := Vector2(
		screen_pos.x / size.x * float(_viewport.size.x),
		screen_pos.y / size.y * float(_viewport.size.y)
	)
	var origin := _camera.project_ray_origin(viewport_pos)
	var direction := _camera.project_ray_normal(viewport_pos)
	var best_record := {}
	var best_distance := INF
	for key in _marker_nodes.keys():
		var area: Area3D = _marker_nodes[key]
		var record = area.get_meta("git_record", {})
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var center := area.global_position
		var radius := 0.75 * maxf(area.scale.x, 1.0)
		var oc := origin - center
		var b := direction.dot(oc)
		var c := oc.dot(oc) - radius * radius
		var discriminant := b * b - c
		if discriminant < 0.0:
			continue
		var t := -b - sqrt(discriminant)
		if t < 0.0:
			t = -b + sqrt(discriminant)
		if t < 0.0 or t >= best_distance:
			continue
		best_distance = t
		best_record = record
	return best_record


func _fit_camera_to_content() -> void:
	if _records.is_empty() and _path_points.is_empty() and _parsed_layout.is_empty() and _walkmesh.is_empty() and _room_meshes.is_empty() and _instance_mesh_by_key.is_empty():
		_orbit_focus = Vector3.ZERO
		_orbit_distance = 40.0
		_update_camera_transform()
		return
	var min_pos := Vector3(INF, INF, INF)
	var max_pos := Vector3(-INF, -INF, -INF)
	if not _walkmesh.is_empty():
		var kotor_bounds := BWMParser.compute_bounds(_walkmesh)
		if kotor_bounds.size != Vector3.ZERO:
			var corners := [
				kotor_bounds.position,
				kotor_bounds.position + Vector3(kotor_bounds.size.x, 0.0, 0.0),
				kotor_bounds.position + Vector3(0.0, kotor_bounds.size.y, 0.0),
				kotor_bounds.position + Vector3(0.0, 0.0, kotor_bounds.size.z),
				kotor_bounds.end,
			]
			for corner in corners:
				var godot_pos := KotorWorldCoordinates.kotor_to_godot(corner)
				min_pos = min_pos.min(godot_pos)
				max_pos = max_pos.max(godot_pos)
	for record in _records:
		var kotor_pos := Vector3(
			float(record.get("x", 0.0)),
			float(record.get("y", 0.0)),
			float(record.get("z", 0.0))
		)
		var godot_pos := KotorWorldCoordinates.kotor_to_godot(kotor_pos)
		min_pos = min_pos.min(godot_pos)
		max_pos = max_pos.max(godot_pos)
	for point_record in _path_points:
		var path_pos := KotorWorldCoordinates.kotor_to_godot(Vector3(
			float(point_record.get("x", 0.0)),
			float(point_record.get("y", 0.0)),
			float(point_record.get("z", 0.0))
		))
		min_pos = min_pos.min(path_pos)
		max_pos = max_pos.max(path_pos)
	for record in _records:
		var category := str(record.get("category", ""))
		var index := int(record.get("index", -1))
		var key := "%s:%d" % [category, index]
		var instance_mesh := _instance_mesh_for_key(key)
		if instance_mesh.is_empty():
			continue
		var kotor_pos := Vector3(
			float(record.get("x", 0.0)),
			float(record.get("y", 0.0)),
			float(record.get("z", 0.0))
		)
		var mesh_bounds := MDLParser.compute_bounds(instance_mesh)
		if mesh_bounds.size == Vector3.ZERO:
			continue
		var corners := [
			kotor_pos + mesh_bounds.position,
			kotor_pos + mesh_bounds.position + Vector3(mesh_bounds.size.x, 0.0, 0.0),
			kotor_pos + mesh_bounds.position + Vector3(0.0, mesh_bounds.size.y, 0.0),
			kotor_pos + mesh_bounds.position + Vector3(0.0, 0.0, mesh_bounds.size.z),
			kotor_pos + mesh_bounds.position + mesh_bounds.size,
		]
		for corner in corners:
			var godot_corner := KotorWorldCoordinates.kotor_to_godot(corner)
			min_pos = min_pos.min(godot_corner)
			max_pos = max_pos.max(godot_corner)
	for layout_key in ["rooms", "tracks", "obstacles", "doorhooks"]:
		for raw_entry in _parsed_layout.get(layout_key, []):
			if typeof(raw_entry) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = raw_entry
			var kotor_pos: Vector3 = entry.get("position", Vector3.ZERO)
			var godot_pos := KotorWorldCoordinates.kotor_to_godot(kotor_pos)
			min_pos = min_pos.min(godot_pos)
			max_pos = max_pos.max(godot_pos)
	for room in _parsed_layout.get("rooms", []):
		if typeof(room) != TYPE_DICTIONARY:
			continue
		var room_dict: Dictionary = room
		var model_name := str(room_dict.get("model", ""))
		var room_position: Vector3 = room_dict.get("position", Vector3.ZERO)
		if not _room_mesh_for_model(model_name).is_empty():
			var mesh_bounds := MDLParser.compute_bounds(_room_mesh_for_model(model_name))
			if mesh_bounds.size != Vector3.ZERO:
				var corners := [
					room_position + mesh_bounds.position,
					room_position + mesh_bounds.position + Vector3(mesh_bounds.size.x, 0.0, 0.0),
					room_position + mesh_bounds.position + Vector3(0.0, mesh_bounds.size.y, 0.0),
					room_position + mesh_bounds.position + Vector3(0.0, 0.0, mesh_bounds.size.z),
					room_position + mesh_bounds.position + mesh_bounds.size,
				]
				for corner in corners:
					var godot_pos := KotorWorldCoordinates.kotor_to_godot(corner)
					min_pos = min_pos.min(godot_pos)
					max_pos = max_pos.max(godot_pos)
				continue
		var godot_pos := KotorWorldCoordinates.kotor_to_godot(room_position)
		min_pos = min_pos.min(godot_pos)
		max_pos = max_pos.max(godot_pos)
	_orbit_focus = (min_pos + max_pos) * 0.5
	var span := (max_pos - min_pos).length()
	_orbit_distance = clampf(maxf(span * 1.8, 12.0), 12.0, 200.0)
	_update_camera_transform()


func _update_camera_transform() -> void:
	if _camera == null:
		return
	var offset := Vector3(
		cos(_orbit_pitch) * sin(_orbit_yaw),
		-sin(_orbit_pitch),
		cos(_orbit_pitch) * cos(_orbit_yaw)
	) * _orbit_distance
	_camera.position = _orbit_focus + offset
	var forward := (_orbit_focus - _camera.position).normalized()
	if forward.is_zero_approx():
		return
	if _camera.is_inside_tree():
		_camera.look_at(_orbit_focus, Vector3.UP)
	else:
		_camera.basis = Basis.looking_at(forward, Vector3.UP)


func _has_selection() -> bool:
	return not _selected_category.is_empty() and _selected_index >= 0


func _selected_record() -> Dictionary:
	for record in _records:
		if str(record.get("category", "")) == _selected_category and int(record.get("index", -1)) == _selected_index:
			return record
	return {}


func _begin_rotate(screen_pos: Vector2) -> void:
	var record := _selected_record()
	if record.is_empty():
		return
	_rotate_active = true
	_rotate_category = _selected_category
	_rotate_index = _selected_index
	_rotate_start_bearing = float(record.get("bearing", 0.0))
	_rotate_preview_bearing = _rotate_start_bearing
	_last_mouse = screen_pos
	_update_rotate_preview(screen_pos)


func _update_rotate_preview(screen_pos: Vector2) -> void:
	if not _rotate_active:
		return
	var record := _selected_record()
	if record.is_empty():
		_cancel_rotate()
		return
	_rotate_preview_bearing = _bearing_from_screen(screen_pos, record)
	set_preview_bearing(_rotate_category, _rotate_index, _rotate_preview_bearing)
	instance_rotate_updated.emit(_rotate_category, _rotate_index, _rotate_preview_bearing)


func _finish_rotate() -> void:
	if not _rotate_active:
		return
	if absf(_rotate_preview_bearing - _rotate_start_bearing) > 0.001:
		instance_rotate_finished.emit(
			_rotate_category,
			_rotate_index,
			_rotate_start_bearing,
			_rotate_preview_bearing
		)
	_cancel_rotate()


func _cancel_rotate() -> void:
	_rotate_active = false
	_rotate_category = ""
	_rotate_index = -1
	_rotate_start_bearing = 0.0
	_rotate_preview_bearing = 0.0
	if _has_selection():
		var record := _selected_record()
		set_preview_bearing(_selected_category, _selected_index, float(record.get("bearing", 0.0)))


func _bearing_from_screen(screen_pos: Vector2, record: Dictionary) -> float:
	var instance_xy := Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))
	var ray := _screen_ray(screen_pos)
	if ray.is_empty():
		return float(record.get("bearing", 0.0))
	var kotor_pos := Vector3(
		float(record.get("x", 0.0)),
		float(record.get("y", 0.0)),
		float(record.get("z", 0.0))
	)
	var plane_y := KotorWorldCoordinates.kotor_to_godot(kotor_pos).y
	var cursor_xy := KotorWorldCoordinates.godot_ray_to_kotor_xy(
		ray.get("origin", Vector3.ZERO),
		ray.get("direction", Vector3.FORWARD),
		plane_y
	)
	if is_nan(cursor_xy.x):
		return float(record.get("bearing", 0.0))
	return KotorWorldCoordinates.bearing_from_kotor_xy_offset(instance_xy, cursor_xy)


func _screen_ray(screen_pos: Vector2) -> Dictionary:
	if _camera == null or _viewport == null or size.x <= 0.0 or size.y <= 0.0:
		return {}
	var viewport_pos := Vector2(
		screen_pos.x / size.x * float(_viewport.size.x),
		screen_pos.y / size.y * float(_viewport.size.y)
	)
	return {
		"origin": _camera.project_ray_origin(viewport_pos),
		"direction": _camera.project_ray_normal(viewport_pos),
	}


func _rebuild_rotate_gizmo() -> void:
	if _rotate_gizmo_root == null:
		return
	for child in _rotate_gizmo_root.get_children():
		child.queue_free()
	if not _has_selection():
		_rotate_gizmo_root.visible = false
		return
	var key := "%s:%d" % [_selected_category, _selected_index]
	if not _marker_nodes.has(key):
		_rotate_gizmo_root.visible = false
		return
	var area: Area3D = _marker_nodes[key]
	_rotate_gizmo_root.visible = true
	_rotate_gizmo_root.global_position = area.global_position

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.05
	torus.outer_radius = 1.25
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(1.0, 0.85, 0.2, 0.9)
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_material
	_rotate_gizmo_root.add_child(ring)

	var arrow := MeshInstance3D.new()
	var arrow_mesh := BoxMesh.new()
	arrow_mesh.size = Vector3(0.08, 0.08, 1.4)
	arrow.mesh = arrow_mesh
	arrow.position = Vector3(0.0, 0.05, -0.7)
	var arrow_material := StandardMaterial3D.new()
	arrow_material.albedo_color = Color(1.0, 0.45, 0.15, 0.95)
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow.material_override = arrow_material
	_rotate_gizmo_root.add_child(arrow)

	var record := _selected_record()
	_update_rotate_gizmo_rotation(float(record.get("bearing", 0.0)))


func _update_rotate_gizmo_rotation(bearing: float) -> void:
	if _rotate_gizmo_root == null:
		return
	_rotate_gizmo_root.rotation.y = KotorWorldCoordinates.kotor_bearing_to_yaw(bearing)
