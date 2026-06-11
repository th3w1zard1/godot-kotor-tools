@tool
extends GraphEdit
class_name KotorDLGGraphView

signal node_metadata_selected(metadata: Dictionary)
signal connection_link_requested(from_metadata: Dictionary, to_metadata: Dictionary)

const KotorDLGDocument := preload("../../../resources/documents/kotor_dlg_document.gd")

const SLOT_TYPE := 0
const SLOT_COLOR := Color(0.55, 0.75, 0.95)


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(280, 240)
	scroll_offset = Vector2.ZERO
	right_disconnects = false


func _ready() -> void:
	connection_request.connect(_on_connection_request)
	node_selected.connect(_on_node_selected)


func _on_connection_request(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
) -> void:
	if from_port != 1 or to_port != 0:
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
	if layout.is_empty():
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
		connect_node(StringName(from_id), 1, StringName(to_id), 0)


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
	for child in get_children():
		if child is GraphNode:
			child.queue_free()

