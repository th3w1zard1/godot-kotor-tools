@tool
extends GraphEdit
class_name KotorDLGGraphView

signal node_metadata_selected(metadata: Dictionary)
signal connection_link_requested(from_metadata: Dictionary, to_metadata: Dictionary)

const KotorDLGDocument := preload("../../../resources/documents/kotor_dlg_document.gd")

const SLOT_TYPE := 0
const SLOT_COLOR := Color(0.55, 0.75, 0.95)
const DEFAULT_NODE_SIZE := Vector2(220, 96)
const VIEWPORT_MARGIN := 32.0
const MINIMAP_SIZE := Vector2(168, 120)
const MINIMAP_MARGIN := 8.0

var _custom_minimap_enabled: bool = false

var _minimap_root: PanelContainer
var _minimap_canvas: Control
var _last_minimap_scroll := Vector2.INF


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(280, 240)
	scroll_offset = Vector2.ZERO
	right_disconnects = false


func _ready() -> void:
	connection_request.connect(_on_connection_request)
	node_selected.connect(_on_node_selected)
	_ensure_minimap_overlay()
	set_process(false)


func _process(_delta: float) -> void:
	if not _custom_minimap_enabled or _minimap_canvas == null:
		return
	if scroll_offset != _last_minimap_scroll:
		_last_minimap_scroll = scroll_offset
		_minimap_canvas.queue_redraw()


func set_custom_minimap_enabled(enabled: bool) -> void:
	_custom_minimap_enabled = enabled
	if _minimap_root != null:
		_minimap_root.visible = enabled
	set_process(enabled)
	if enabled:
		_last_minimap_scroll = Vector2.INF
		_update_minimap()


func is_custom_minimap_enabled() -> bool:
	return _custom_minimap_enabled


func _on_connection_request(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
) -> void:
	if from_port != 0 or to_port != 0:
		return
	var from_metadata := KotorDLGDocument.parse_graph_node_id(str(from_node))
	var to_metadata := KotorDLGDocument.parse_graph_node_id(str(to_node))
	if from_metadata.is_empty() or to_metadata.is_empty():
		return
	if from_metadata.get("kind", "") == to_metadata.get("kind", ""):
		return
	connection_link_requested.emit(from_metadata, to_metadata)


func _on_node_selected(node: Node) -> void:
	if not node is GraphNode:
		return
	var metadata := KotorDLGDocument.parse_graph_node_id(str(node.name))
	if metadata.is_empty():
		return
	node_metadata_selected.emit(metadata)


func build_from_layout(layout: Dictionary) -> void:
	_clear_graph_nodes()
	_last_layout = layout
	if layout.is_empty():
		_update_minimap()
		return

	var node_ids := {}
	for node_data in layout.get("nodes", []):
		if typeof(node_data) != TYPE_DICTIONARY:
			continue
		var node_id := str(node_data.get("id", ""))
		if node_id.is_empty():
			continue
		var graph_node := _create_graph_node(node_data)
		add_child(graph_node)
		node_ids[node_id] = graph_node

	for edge_data in layout.get("edges", []):
		if typeof(edge_data) != TYPE_DICTIONARY:
			continue
		var from_id := str(edge_data.get("from_id", ""))
		var to_id := str(edge_data.get("to_id", ""))
		if not node_ids.has(from_id) or not node_ids.has(to_id):
			continue
		connect_node(StringName(from_id), 0, StringName(to_id), 0)
	_update_minimap()


var _last_layout: Dictionary = {}


static func compute_layout_bounds(
	layout: Dictionary,
	default_node_size: Vector2 = DEFAULT_NODE_SIZE
) -> Rect2:
	var nodes: Array = layout.get("nodes", [])
	if nodes.is_empty():
		return Rect2()
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for node_data in nodes:
		if typeof(node_data) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = node_data.get("pos", Vector2.ZERO)
		min_pos.x = minf(min_pos.x, pos.x)
		min_pos.y = minf(min_pos.y, pos.y)
		max_pos.x = maxf(max_pos.x, pos.x + default_node_size.x)
		max_pos.y = maxf(max_pos.y, pos.y + default_node_size.y)
	if min_pos.x == INF:
		return Rect2()
	return Rect2(min_pos, max_pos - min_pos)


static func compute_center_scroll_offset(bounds: Rect2, viewport_size: Vector2) -> Vector2:
	if bounds.size == Vector2.ZERO or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2.ZERO
	var center := bounds.position + bounds.size * 0.5
	return center - viewport_size * 0.5


static func compute_viewport_rect_in_graph_space(scroll_offset: Vector2, viewport_size: Vector2) -> Rect2:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Rect2()
	return Rect2(scroll_offset, viewport_size)


static func compute_minimap_transform(graph_bounds: Rect2, minimap_size: Vector2, padding: float = 4.0) -> Dictionary:
	if graph_bounds.size == Vector2.ZERO or minimap_size.x <= 0.0 or minimap_size.y <= 0.0:
		return {"scale": 1.0, "offset": Vector2.ZERO}
	var padded_bounds := graph_bounds.grow(padding)
	var scale := minf(
		(minimap_size.x - padding * 2.0) / padded_bounds.size.x,
		(minimap_size.y - padding * 2.0) / padded_bounds.size.y
	)
	if scale <= 0.0:
		scale = 1.0
	var drawn_size := padded_bounds.size * scale
	var offset := (minimap_size - drawn_size) * 0.5 - padded_bounds.position * scale
	return {"scale": scale, "offset": offset}


func fit_all_nodes() -> bool:
	var bounds := _compute_live_bounds()
	if bounds.size == Vector2.ZERO:
		scroll_offset = Vector2.ZERO
		return false
	var padded := Rect2(
		bounds.position - Vector2(VIEWPORT_MARGIN, VIEWPORT_MARGIN),
		bounds.size + Vector2(VIEWPORT_MARGIN, VIEWPORT_MARGIN) * 2.0
	)
	scroll_offset = compute_center_scroll_offset(padded, size)
	_update_minimap()
	return true


func focus_metadata(metadata: Dictionary) -> bool:
	if typeof(metadata) != TYPE_DICTIONARY or metadata.is_empty():
		return false
	var kind := str(metadata.get("kind", ""))
	if kind != "entry" and kind != "reply":
		return false
	var graph_node := _graph_node_for_metadata(metadata)
	if graph_node == null:
		return false
	_highlight_graph_node(graph_node)
	var node_bounds := Rect2(graph_node.position_offset, _graph_node_size(graph_node))
	scroll_offset = compute_center_scroll_offset(node_bounds, size)
	_update_minimap()
	return true


func metadata_is_graph_focusable(metadata: Dictionary) -> bool:
	if typeof(metadata) != TYPE_DICTIONARY:
		return false
	var kind := str(metadata.get("kind", ""))
	return kind == "entry" or kind == "reply"


func _compute_live_bounds() -> Rect2:
	var bounds := Rect2()
	var has_bounds := false
	for child in get_children():
		if not child is GraphNode:
			continue
		var graph_node := child as GraphNode
		var node_bounds := Rect2(graph_node.position_offset, _graph_node_size(graph_node))
		if not has_bounds:
			bounds = node_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(node_bounds)
	if has_bounds:
		return bounds
	return compute_layout_bounds(_last_layout)


func _graph_node_for_metadata(metadata: Dictionary) -> GraphNode:
	var target_kind := str(metadata.get("kind", ""))
	var target_index := int(metadata.get("index", -1))
	for child in get_children():
		if not child is GraphNode:
			continue
		var parsed := KotorDLGDocument.parse_graph_node_id(str(child.name))
		if parsed.is_empty():
			continue
		if str(parsed.get("kind", "")) == target_kind and int(parsed.get("index", -1)) == target_index:
			return child as GraphNode
	return null


func _graph_node_by_id(node_id: String) -> GraphNode:
	for child in get_children():
		if child is GraphNode and str(child.name) == node_id:
			return child as GraphNode
	return null


func _graph_node_size(graph_node: GraphNode) -> Vector2:
	var node_size := graph_node.size
	if node_size.x > 0.0 and node_size.y > 0.0:
		return node_size
	return DEFAULT_NODE_SIZE


func _highlight_graph_node(graph_node: GraphNode) -> void:
	for child in get_children():
		if child is GraphNode:
			(child as GraphNode).selected = child == graph_node


func _create_graph_node(node_data: Dictionary) -> GraphNode:
	var node_id := str(node_data.get("id", ""))
	var graph_node := GraphNode.new()
	graph_node.name = node_id
	graph_node.title = str(node_data.get("label", node_id))
	graph_node.draggable = false
	graph_node.resizable = false
	graph_node.position_offset = node_data.get("pos", Vector2.ZERO)

	var preview := str(node_data.get("preview", "")).strip_edges()
	if not preview.is_empty():
		var preview_label := Label.new()
		preview_label.text = preview
		preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_label.custom_minimum_size = Vector2(180, 0)
		graph_node.add_child(preview_label)

	graph_node.set_slot(0, true, SLOT_TYPE, SLOT_COLOR, true, SLOT_TYPE, SLOT_COLOR)
	return graph_node


func _clear_graph_nodes() -> void:
	clear_connections()
	var to_remove: Array[GraphNode] = []
	for child in get_children():
		if child is GraphNode:
			to_remove.append(child as GraphNode)
	for graph_node in to_remove:
		remove_child(graph_node)
		graph_node.free()


func _ensure_minimap_overlay() -> void:
	if _minimap_root != null:
		return
	_minimap_root = PanelContainer.new()
	_minimap_root.name = "GraphMinimap"
	_minimap_root.visible = false
	_minimap_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_minimap_root.custom_minimum_size = MINIMAP_SIZE
	_minimap_root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_minimap_root.offset_left = -MINIMAP_SIZE.x - MINIMAP_MARGIN
	_minimap_root.offset_top = -MINIMAP_SIZE.y - MINIMAP_MARGIN
	_minimap_root.offset_right = -MINIMAP_MARGIN
	_minimap_root.offset_bottom = -MINIMAP_MARGIN
	add_child(_minimap_root)

	_minimap_canvas = Control.new()
	_minimap_canvas.name = "GraphMinimapCanvas"
	_minimap_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_minimap_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_minimap_canvas.draw.connect(_draw_minimap)
	_minimap_canvas.gui_input.connect(_on_minimap_gui_input)
	_minimap_root.add_child(_minimap_canvas)


func _update_minimap() -> void:
	if _minimap_canvas != null and _custom_minimap_enabled:
		_minimap_canvas.queue_redraw()


func _draw_minimap() -> void:
	if _minimap_canvas == null:
		return
	var canvas_size := _minimap_canvas.size
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		return

	_minimap_canvas.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(0.08, 0.1, 0.14, 0.92), true)
	_minimap_canvas.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(0.35, 0.45, 0.55, 0.9), false, 1.0)

	var graph_bounds := _compute_live_bounds()
	if graph_bounds.size == Vector2.ZERO:
		return

	var transform := compute_minimap_transform(graph_bounds, canvas_size)
	var scale: float = transform.get("scale", 1.0)
	var offset: Vector2 = transform.get("offset", Vector2.ZERO)

	for child in get_children():
		if not child is GraphNode:
			continue
		var graph_node := child as GraphNode
		var node_rect := Rect2(graph_node.position_offset, _graph_node_size(graph_node))
		var top_left := node_rect.position * scale + offset
		var node_size := node_rect.size * scale
		var fill := Color(0.45, 0.65, 0.9, 0.85) if graph_node.selected else Color(0.3, 0.45, 0.65, 0.75)
		_minimap_canvas.draw_rect(Rect2(top_left, node_size), fill, true)

	var viewport_rect := compute_viewport_rect_in_graph_space(scroll_offset, size)
	var viewport_top_left := viewport_rect.position * scale + offset
	var viewport_size := viewport_rect.size * scale
	_minimap_canvas.draw_rect(Rect2(viewport_top_left, viewport_size), Color(1.0, 0.85, 0.35, 0.18), true)
	_minimap_canvas.draw_rect(Rect2(viewport_top_left, viewport_size), Color(1.0, 0.85, 0.35, 0.95), false, 1.0)


func _on_minimap_gui_input(event: InputEvent) -> void:
	if _minimap_canvas == null or not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var graph_bounds := _compute_live_bounds()
	if graph_bounds.size == Vector2.ZERO or size.x <= 0.0 or size.y <= 0.0:
		return
	var transform := compute_minimap_transform(graph_bounds, _minimap_canvas.size)
	var scale: float = transform.get("scale", 1.0)
	var offset: Vector2 = transform.get("offset", Vector2.ZERO)
	if scale <= 0.0:
		return
	var graph_pos := (mouse_event.position - offset) / scale
	scroll_offset = graph_pos - size * 0.5
	_update_minimap()
	accept_event()

