@tool
extends SubViewportContainer
class_name ModuleDesignerViewport3D

signal instance_selected(category: String, index: int)

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
var _records: Array[Dictionary] = []
var _layout_rooms: Array = []
var _room_meshes: Array = []
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


func _ready() -> void:
	_update_camera_transform()


func set_instances(records: Array, layout: Dictionary = {}) -> void:
	_records.clear()
	for raw_record in records:
		if typeof(raw_record) == TYPE_DICTIONARY:
			_records.append(raw_record)
	_layout_rooms = layout.get("rooms", []) as Array if typeof(layout) == TYPE_DICTIONARY else []
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


func set_selection(category: String, index: int) -> void:
	_selected_category = category
	_selected_index = index
	_refresh_marker_highlights()


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
			_dragging = mouse_event.pressed
			_last_mouse = mouse_event.position
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_orbit_distance = maxf(5.0, _orbit_distance * 0.9)
			_update_camera_transform()
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_orbit_distance = minf(500.0, _orbit_distance * 1.1)
			_update_camera_transform()
	if event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
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

	for room in _layout_rooms:
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
		var marker := _make_pickable_marker(record, godot_pos, color)
		marker.name = "GIT_%s" % key
		_instances_root.add_child(marker)
		_marker_nodes[key] = marker

	_refresh_marker_highlights()


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


func _make_pickable_marker(record: Dictionary, position: Vector3, color: Color) -> Area3D:
	var area := Area3D.new()
	area.position = position
	area.set_meta("git_record", record)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	collision.shape = shape
	area.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.7, 0.7)
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	area.add_child(mesh_instance)

	var bearing := float(record.get("bearing", 0.0))
	area.rotation.y = KotorWorldCoordinates.kotor_bearing_to_yaw(bearing)
	return area


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


func _refresh_marker_highlights() -> void:
	for key in _marker_nodes.keys():
		var area: Area3D = _marker_nodes[key]
		var record = area.get_meta("git_record", {})
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var category := str(record.get("category", ""))
		var index := int(record.get("index", -1))
		var mesh := area.get_child(1) as MeshInstance3D
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
	if _records.is_empty() and _layout_rooms.is_empty() and _walkmesh.is_empty() and _room_meshes.is_empty():
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
	for room in _layout_rooms:
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
