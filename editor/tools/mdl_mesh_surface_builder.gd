## Build Godot ArrayMesh surfaces from parsed KotOR MDL trimesh dictionaries.
class_name MdlMeshSurfaceBuilder

const KotorWorldCoordinates := preload("../module/kotor_world_coordinates.gd")


static func build_from_parsed(parsed: Dictionary, position_offset: Vector3 = Vector3.ZERO) -> ArrayMesh:
	if typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty():
		return null
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
			if typeof(vertices[vertex_index]) != TYPE_VECTOR3:
				continue
			var kotor_vertex: Vector3 = vertices[vertex_index] + position_offset
			surface_tool.add_vertex(KotorWorldCoordinates.kotor_to_godot(kotor_vertex))
	return surface_tool.commit()


static func triangle_count(parsed: Dictionary) -> int:
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	return int(parsed.get("face_count", 0))
