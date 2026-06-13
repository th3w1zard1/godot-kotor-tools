@tool
extends SceneTree

const KotorDLGDocument := preload("../../resources/documents/kotor_dlg_document.gd")
const KotorDLGGraphView := preload("../../ui/workspace/panels/dlg_graph_view.gd")
const GFFParser := preload("../../formats/gff_parser.gd")
const DLGResource := preload("../../resources/typed/dlg_resource.gd")


func _initialize() -> void:
	call_deferred("_run_tests")
	return


func _run_tests() -> void:
	_test_layout_node_count_matches_entries_and_replies()
	_test_layout_edge_count_matches_valid_links()
	_test_layout_omits_invalid_link_targets()
	_test_parse_graph_node_id_round_trip()
	_test_connection_request_rejects_same_kind()
	_test_compute_layout_bounds()
	_test_compute_center_scroll_offset()
	await _test_focus_metadata_rejects_non_graph_kinds()
	await _test_fit_all_nodes_from_layout()
	_test_build_layout_creates_graph_connections()
	_test_compute_minimap_transform()
	await _test_minimap_enabled_sync()
	quit()


func _build_document() -> KotorDLGDocument:
	var resource := DLGResource.new()
	resource.setup_from_parser_result({
		"file_type": "DLG",
		"root": {
			"Tag": "graph_layout_test",
			"StartingList": [
				{"Index": 0},
			],
			"EntryList": [
				{
					"Text": {"strref": 0xFFFFFFFF, "strings": {0: "Hello there."}},
					"RepliesList": [
						{"Index": 0, "Comment": "Go to reply 0"},
						{"Index": 99, "Comment": "Broken link"},
					],
				},
				{
					"Text": {"strref": 0xFFFFFFFF, "strings": {0: "Second entry."}},
					"RepliesList": [],
				},
			],
			"ReplyList": [
				{
					"Text": {"strref": 0xFFFFFFFF, "strings": {0: "General Kenobi."}},
					"EntriesList": [
						{"Index": 1, "Comment": "Back to entry 1"},
					],
				},
			],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [],
		},
	})
	return resource.create_document() as KotorDLGDocument


func _test_layout_node_count_matches_entries_and_replies() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	var nodes: Array = layout.get("nodes", [])
	assert(nodes.size() == doc.get_entry_count() + doc.get_reply_count())
	for node_data in nodes:
		assert(typeof(node_data) == TYPE_DICTIONARY)
		assert(not str(node_data.get("id", "")).is_empty())
		assert(node_data.get("pos", null) is Vector2)


func _test_layout_edge_count_matches_valid_links() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	var edges: Array = layout.get("edges", [])
	assert(edges.size() == 2, "Fixture should expose two valid dialogue links")
	var edge_pairs: Array[String] = []
	for edge_data in edges:
		edge_pairs.append("%s->%s" % [edge_data.get("from_id", ""), edge_data.get("to_id", "")])
	assert("entry_0->reply_0" in edge_pairs)
	assert("reply_0->entry_1" in edge_pairs)


func _test_layout_omits_invalid_link_targets() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	for edge_data in layout.get("edges", []):
		var from_id := str(edge_data.get("from_id", ""))
		var to_id := str(edge_data.get("to_id", ""))
		assert(not from_id.contains("99"))
		assert(not to_id.contains("99"))


func _test_connection_request_rejects_same_kind() -> void:
	var graph_view := KotorDLGGraphView.new()
	var requested: Array[Dictionary] = []
	graph_view.connection_link_requested.connect(func(from_metadata: Dictionary, to_metadata: Dictionary) -> void:
		requested.append(from_metadata)
		requested.append(to_metadata)
	)
	graph_view._on_connection_request(&"entry_0", 0, &"entry_1", 0)
	assert(requested.is_empty(), "Entry-to-entry connection should be ignored")
	graph_view._on_connection_request(&"entry_0", 0, &"reply_0", 0)
	assert(requested.size() == 2, "Entry-to-reply connection should emit metadata pair")
	assert(requested[0].get("kind", "") == "entry")
	assert(int(requested[1].get("index", -1)) == 0)
	graph_view.free()


func _test_parse_graph_node_id_round_trip() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	for node_data in layout.get("nodes", []):
		var node_id := str(node_data.get("id", ""))
		var parsed := KotorDLGDocument.parse_graph_node_id(node_id)
		assert(parsed.get("kind", "") == node_data.get("kind", ""))
		assert(int(parsed.get("index", -1)) == int(node_data.get("index", -1)))


func _test_compute_layout_bounds() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	var bounds := KotorDLGGraphView.compute_layout_bounds(layout)
	assert(bounds.size.x > 0.0)
	assert(bounds.size.y > 0.0)
	assert(bounds.position.x >= 0.0)
	print("✓ DLG graph layout bounds passed")


func _test_compute_center_scroll_offset() -> void:
	var bounds := Rect2(Vector2(100, 200), Vector2(400, 300))
	var viewport := Vector2(800, 600)
	var offset := KotorDLGGraphView.compute_center_scroll_offset(bounds, viewport)
	assert(is_equal_approx(offset.x, -100.0))
	assert(is_equal_approx(offset.y, 50.0))
	print("✓ DLG graph center scroll offset passed")


func _test_compute_viewport_rect_in_graph_space() -> void:
	var viewport_rect := KotorDLGGraphView.compute_viewport_rect_in_graph_space(
		Vector2(120, 80),
		Vector2(640, 480)
	)
	assert(viewport_rect.position == Vector2(120, 80))
	assert(viewport_rect.size == Vector2(640, 480))
	print("✓ DLG graph viewport rect passed")


func _test_compute_minimap_transform() -> void:
	var bounds := Rect2(Vector2(100, 50), Vector2(400, 300))
	var transform := KotorDLGGraphView.compute_minimap_transform(bounds, Vector2(160, 120))
	assert(transform.get("scale", 0.0) > 0.0)
	var scale: float = transform.get("scale", 1.0)
	var offset: Vector2 = transform.get("offset", Vector2.ZERO)
	var mapped := bounds.position * scale + offset
	assert(mapped.x >= 0.0)
	assert(mapped.y >= 0.0)
	print("✓ DLG graph minimap transform passed")


func _test_minimap_enabled_sync() -> void:
	var graph_view := KotorDLGGraphView.new()
	root.add_child(graph_view)
	graph_view.size = Vector2(640, 480)
	graph_view.build_from_layout(_build_document().build_graph_layout_metadata())
	await process_frame
	assert(not graph_view.is_custom_minimap_enabled())
	graph_view.set_custom_minimap_enabled(true)
	assert(graph_view.is_custom_minimap_enabled())
	graph_view.set_custom_minimap_enabled(false)
	assert(not graph_view.is_custom_minimap_enabled())
	graph_view.queue_free()
	print("✓ DLG graph minimap toggle passed")


func _test_focus_metadata_rejects_non_graph_kinds() -> void:
	var graph_view := KotorDLGGraphView.new()
	root.add_child(graph_view)
	graph_view.size = Vector2(640, 480)
	graph_view.build_from_layout(_build_document().build_graph_layout_metadata())
	await process_frame
	assert(not graph_view.focus_metadata({"kind": "link", "index": 0}))
	assert(not graph_view.focus_metadata({"kind": "start", "index": 0}))
	assert(graph_view.focus_metadata({"kind": "entry", "index": 0}))
	graph_view.queue_free()
	print("✓ DLG graph focus metadata guards passed")


func _test_fit_all_nodes_from_layout() -> void:
	var graph_view := KotorDLGGraphView.new()
	root.add_child(graph_view)
	graph_view.size = Vector2(640, 480)
	graph_view.build_from_layout(_build_document().build_graph_layout_metadata())
	await process_frame
	assert(graph_view.fit_all_nodes())
	graph_view.queue_free()
	print("✓ DLG graph fit all nodes passed")


func _test_build_layout_creates_graph_connections() -> void:
	var graph_view := KotorDLGGraphView.new()
	root.add_child(graph_view)
	graph_view.build_from_layout(_build_document().build_graph_layout_metadata())
	assert(graph_view.get_connection_list().size() == 2)
	graph_view.queue_free()
	print("✓ DLG graph layout connections passed")
