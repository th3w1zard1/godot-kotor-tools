@tool
extends SceneTree

const KotorDLGDocument := preload("../../resources/documents/kotor_dlg_document.gd")
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
	assert("entry:0->reply:0" in edge_pairs)
	assert("reply:0->entry:1" in edge_pairs)


func _test_layout_omits_invalid_link_targets() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	for edge_data in layout.get("edges", []):
		var from_id := str(edge_data.get("from_id", ""))
		var to_id := str(edge_data.get("to_id", ""))
		assert(not from_id.contains("99"))
		assert(not to_id.contains("99"))


func _test_parse_graph_node_id_round_trip() -> void:
	var doc := _build_document()
	var layout := doc.build_graph_layout_metadata()
	for node_data in layout.get("nodes", []):
		var node_id := str(node_data.get("id", ""))
		var parsed := KotorDLGDocument.parse_graph_node_id(node_id)
		assert(parsed.get("kind", "") == node_data.get("kind", ""))
		assert(int(parsed.get("index", -1)) == int(node_data.get("index", -1)))
