## KotOR MDL binary parser (read-only, K1 trimesh visualization).
##
## Parses geometry nodes from K1 MDL layout per PyKotor io_mdl: geometry header,
## node tree, trimesh headers, and face/vertex tables. Merges all mesh nodes into
## one vertex/face list in model space.
class_name MDLParser

const DATA_OFFSET := 12
const MODEL_HEADER_SIZE := 196
const NODE_HEADER_SIZE := 80
const TRIMESH_HEADER_K1_SIZE := 332
const FACE_SIZE := 32
const SKIN_HEADER_SIZE := 100
const DANGLY_HEADER_SIZE := 28

const K1_GEOMETRY_TOKEN0 := 4273776
const K1_GEOMETRY_TOKEN1 := 4216096
const K1_TRIMESH_TOKEN0 := 4216656
const K1_TRIMESH_TOKEN1 := 4216672

const FLAG_HEADER := 0x0001
const FLAG_MESH := 0x0020
const FLAG_SKIN := 0x0040
const FLAG_DANGLY := 0x0100
const FLAG_AABB := 0x0200

const MDX_VERTEX_FLAG := 0x00000001


static func parse_bytes(mdl_data: PackedByteArray, mdx_data: PackedByteArray = PackedByteArray()) -> Dictionary:
	if mdl_data.size() < DATA_OFFSET + MODEL_HEADER_SIZE:
		return {}

	var stream := StreamPeerBuffer.new()
	stream.data_array = mdl_data
	stream.big_endian = false

	_seek_data(stream, 0)
	var token0 := int(stream.get_u32())
	var token1 := int(stream.get_u32())
	if token0 != K1_GEOMETRY_TOKEN0 or token1 != K1_GEOMETRY_TOKEN1:
		return {}

	var model_name := _read_fixed_string(stream, 32)
	var root_offset := int(stream.get_u32())
	if root_offset <= 0:
		return {}

	var vertices: Array[Vector3] = []
	var faces: Array[Dictionary] = []
	_parse_node(mdl_data, mdx_data, root_offset, Transform3D.IDENTITY, vertices, faces, 0)

	if vertices.is_empty() or faces.is_empty():
		return {}

	return {
		"model_name": model_name,
		"vertices": vertices,
		"faces": faces,
		"vertex_count": vertices.size(),
		"face_count": faces.size(),
	}


static func compute_bounds(parsed: Dictionary) -> AABB:
	var vertices: Array = parsed.get("vertices", [])
	if vertices.is_empty():
		return AABB()
	var min_pos := Vector3(INF, INF, INF)
	var max_pos := Vector3(-INF, -INF, -INF)
	for raw_vertex in vertices:
		if typeof(raw_vertex) != TYPE_VECTOR3:
			continue
		var vertex: Vector3 = raw_vertex
		min_pos = min_pos.min(vertex)
		max_pos = max_pos.max(vertex)
	if min_pos == Vector3(INF, INF, INF):
		return AABB()
	return AABB(min_pos, max_pos - min_pos)


static func _parse_node(
	mdl_data: PackedByteArray,
	mdx_data: PackedByteArray,
	node_offset: int,
	parent_transform: Transform3D,
	vertices: Array[Vector3],
	faces: Array[Dictionary],
	depth: int
) -> void:
	if depth > 64:
		return
	if node_offset <= 0 or _abs_offset(node_offset) + NODE_HEADER_SIZE > mdl_data.size():
		return

	var stream := StreamPeerBuffer.new()
	stream.data_array = mdl_data
	stream.big_endian = false
	_seek_data(stream, node_offset)

	var type_id := int(stream.get_u16())
	stream.get_u16() # padding0
	stream.get_u16() # node_id
	stream.get_u16() # name_id
	stream.get_u32() # offset_to_root
	stream.get_u32() # offset_to_parent

	var position := _read_vector3(stream)
	var orient_w := stream.get_float()
	var orient_x := stream.get_float()
	var orient_y := stream.get_float()
	var orient_z := stream.get_float()
	var local_rotation := Quaternion(orient_x, orient_y, orient_z, orient_w)
	var local_transform := Transform3D(Basis(local_rotation), position)
	var world_transform := parent_transform * local_transform

	var children_offset := int(stream.get_u32())
	var children_count := int(stream.get_u32())
	stream.get_u32() # children_count2
	stream.get_u32() # offset_to_controllers
	stream.get_u32() # controller_count
	stream.get_u32() # controller_count2
	stream.get_u32() # offset_to_controller_data
	stream.get_u32() # controller_data_length
	stream.get_u32() # controller_data_length2

	if type_id & FLAG_MESH:
		_read_trimesh_node(
			mdl_data,
			mdx_data,
			stream,
			type_id,
			world_transform,
			vertices,
			faces
		)

	if children_count <= 0 or children_offset <= 0:
		return
	if children_offset == 0xFFFFFFFF:
		return

	var child_stream := StreamPeerBuffer.new()
	child_stream.data_array = mdl_data
	child_stream.big_endian = false
	_seek_data(child_stream, children_offset)
	for _child_index in range(children_count):
		if child_stream.get_position() + 4 > mdl_data.size():
			break
		var child_offset := int(child_stream.get_u32())
		if child_offset > 0 and child_offset != 0xFFFFFFFF:
			_parse_node(mdl_data, mdx_data, child_offset, world_transform, vertices, faces, depth + 1)


static func _read_trimesh_node(
	mdl_data: PackedByteArray,
	mdx_data: PackedByteArray,
	stream: StreamPeerBuffer,
	type_id: int,
	world_transform: Transform3D,
	vertices: Array[Vector3],
	faces: Array[Dictionary]
) -> void:
	var trimesh_start := stream.get_position()
	if trimesh_start + TRIMESH_HEADER_K1_SIZE > mdl_data.size():
		return

	var layout_token0 := int(stream.get_u32())
	var layout_token1 := int(stream.get_u32())
	if layout_token0 != K1_TRIMESH_TOKEN0 or layout_token1 != K1_TRIMESH_TOKEN1:
		return

	var offset_to_faces := int(stream.get_u32())
	var faces_count := int(stream.get_u32())
	stream.get_u32() # faces_count2
	_read_vector3(stream) # bounding_box_min
	_read_vector3(stream) # bounding_box_max
	stream.get_float() # radius
	_read_vector3(stream) # average
	_read_vector3(stream) # diffuse
	_read_vector3(stream) # ambient
	stream.get_u32() # transparency_hint
	stream.seek(stream.get_position() + 64) # texture1 + texture2
	stream.seek(stream.get_position() + 24) # unknown0
	stream.seek(stream.get_position() + 36) # indices/counters block
	stream.seek(stream.get_position() + 12) # unknown1
	stream.seek(stream.get_position() + 8) # saber_unknowns
	stream.get_u32() # unknown2
	stream.get_float() # uv_direction.x
	stream.get_float() # uv_direction.y
	stream.get_float() # uv_jitter
	stream.get_float() # uv_speed
	stream.get_u32() # mdx_data_size
	var mdx_data_bitmap := int(stream.get_u32())
	var mdx_vertex_offset := int(stream.get_u32())
	stream.seek(stream.get_position() + 40) # remaining mdx offset fields
	var vertex_count := int(stream.get_u16())
	stream.get_u16() # texture_count
	stream.seek(stream.get_position() + 6) # render flags
	stream.get_u16() # tail_short (K1)
	stream.get_float() # total_area
	stream.get_u32() # tail_long0
	stream.get_u32() # mdx_data_offset
	var vertices_offset := int(stream.get_u32())
	_seek_data(stream, trimesh_start + TRIMESH_HEADER_K1_SIZE)

	if type_id & FLAG_SKIN:
		stream.seek(stream.get_position() + SKIN_HEADER_SIZE)
	if type_id & FLAG_DANGLY:
		stream.seek(stream.get_position() + DANGLY_HEADER_SIZE)
	if type_id & FLAG_AABB:
		stream.get_u32() # offset_to_aabb

	if faces_count <= 0 or vertex_count <= 0:
		return
	if offset_to_faces <= 0 or vertices_offset <= 0:
		return

	var local_vertices := _read_vertices(
		mdl_data,
		mdx_data,
		vertices_offset,
		mdx_vertex_offset,
		mdx_data_bitmap,
		vertex_count
	)
	if local_vertices.is_empty():
		return

	var vertex_base := vertices.size()
	for local_vertex in local_vertices:
		vertices.append(world_transform * local_vertex)

	var face_stream := StreamPeerBuffer.new()
	face_stream.data_array = mdl_data
	face_stream.big_endian = false
	_seek_data(face_stream, offset_to_faces)
	for _face_index in range(faces_count):
		if face_stream.get_position() + FACE_SIZE > mdl_data.size():
			break
		_read_vector3(face_stream) # normal
		face_stream.get_float() # plane_coefficient
		face_stream.get_u32() # material
		face_stream.get_u16() # adjacent1
		face_stream.get_u16() # adjacent2
		face_stream.get_u16() # adjacent3
		var i1 := int(face_stream.get_u16())
		var i2 := int(face_stream.get_u16())
		var i3 := int(face_stream.get_u16())
		if i1 < 0 or i2 < 0 or i3 < 0:
			continue
		if i1 >= vertex_count or i2 >= vertex_count or i3 >= vertex_count:
			continue
		faces.append({
			"i1": vertex_base + i1,
			"i2": vertex_base + i2,
			"i3": vertex_base + i3,
		})


static func _read_vertices(
	mdl_data: PackedByteArray,
	mdx_data: PackedByteArray,
	vertices_offset: int,
	mdx_vertex_offset: int,
	mdx_data_bitmap: int,
	vertex_count: int
) -> Array[Vector3]:
	var result: Array[Vector3] = []
	result.resize(vertex_count)

	if mdx_data_bitmap & MDX_VERTEX_FLAG and not mdx_data.is_empty() and mdx_vertex_offset > 0:
		var mdx_stream := StreamPeerBuffer.new()
		mdx_stream.data_array = mdx_data
		mdx_stream.big_endian = false
		mdx_stream.seek(mdx_vertex_offset)
		for index in range(vertex_count):
			if mdx_stream.get_position() + 12 > mdx_data.size():
				return []
			result[index] = _read_vector3(mdx_stream)
		return result

	var stream := StreamPeerBuffer.new()
	stream.data_array = mdl_data
	stream.big_endian = false
	_seek_data(stream, vertices_offset)
	for index in range(vertex_count):
		if stream.get_position() + 12 > mdl_data.size():
			return []
		result[index] = _read_vector3(stream)
	return result


static func _seek_data(stream: StreamPeerBuffer, data_offset: int) -> void:
	stream.seek(DATA_OFFSET + data_offset)


static func _abs_offset(data_offset: int) -> int:
	return DATA_OFFSET + data_offset


static func _read_vector3(stream: StreamPeerBuffer) -> Vector3:
	return Vector3(stream.get_float(), stream.get_float(), stream.get_float())


static func _read_fixed_string(stream: StreamPeerBuffer, length: int) -> String:
	var bytes := PackedByteArray()
	bytes.resize(length)
	for index in range(length):
		if stream.get_position() >= stream.get_size():
			break
		bytes[index] = stream.get_u8()
	var terminator := bytes.find(0)
	if terminator >= 0:
		bytes = bytes.slice(0, terminator)
	return bytes.get_string_from_ascii()
