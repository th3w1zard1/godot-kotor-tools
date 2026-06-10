@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorResRefReferenceScanner := preload("../../editor/tools/kotor_resref_reference_scanner.gd")
const KotorResourceBrowserPanel := preload("../../ui/workspace/panels/resource_browser_panel.gd")
const KotorTargetContext := preload("../../editor/workspace/kotor_target_context.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://resref_reference_scanner_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_seed_install_files()
	_test_scan_finds_gff_and_nss_hits()
	_test_format_report_lists_field_paths()
	var button_ok := await _test_resource_browser_find_references_button()
	_cleanup()
	if not button_ok:
		push_error("Resource browser Find References button test failed")
		quit(1)
	print("✓ ResRef reference scanner tests passed")
	quit()


func _test_scan_finds_gff_and_nss_hits() -> void:
	var gamefs := _build_gamefs()
	var result := KotorResRefReferenceScanner.scan_install_references(gamefs, "n_malak")
	assert(result.get("ok", false))
	var hits: Array = result.get("hits", [])
	assert(hits.size() >= 2)
	var extensions: Dictionary = {}
	for hit in hits:
		extensions[str(hit.get("extension", ""))] = true
	assert(extensions.has("git"))
	assert(extensions.has("nss"))
	var git_hit: Dictionary = {}
	for hit in hits:
		if str(hit.get("extension", "")) == "git":
			git_hit = hit
			break
	assert(not git_hit.is_empty())
	var matches: Array = git_hit.get("matches", [])
	assert(matches.size() >= 1)
	assert(str(matches[0].get("field_path", "")).find("TemplateResRef") >= 0)
	print("✓ Reference scanner finds GFF and NSS hits passed")


func _test_format_report_lists_field_paths() -> void:
	var report := KotorResRefReferenceScanner.format_report({
		"ok": true,
		"target": "n_malak",
		"scanned": 3,
		"hits": [
			{
				"resref": "tar_m02aa",
				"extension": "git",
				"source": "override",
				"location": "override/tar_m02aa.git",
				"matches": [{"field_path": "Creature List[0]/TemplateResRef", "value": "n_malak"}],
			},
		],
	})
	assert(report.find("References to 'n_malak'") >= 0)
	assert(report.find("Creature List[0]/TemplateResRef") >= 0)
	print("✓ Reference report formatting passed")


func _test_resource_browser_find_references_button() -> bool:
	var context := KotorTargetContext.new().setup(_build_editor_state())
	var panel := KotorResourceBrowserPanel.new()
	panel.setup(context)
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(panel)
	await process_frame

	var button := _find_button(panel, "Find References")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ Resource browser Find References button passed")
	return true


func _build_editor_state() -> KotorEditorState:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	return editor_state


func _build_gamefs() -> RefCounted:
	return _build_editor_state().gamefs


func _seed_install_files() -> void:
	var override_dir := _install_root.path_join("override")
	_write_bytes(override_dir.path_join("tar_m02aa.git"), _build_git_bytes())
	var nss_file := FileAccess.open(override_dir.path_join("onheartbeat.nss"), FileAccess.WRITE)
	nss_file.store_string('void main() {\n    object o = GetObjectByTag("n_malak");\n}\n')
	nss_file.close()


func _build_git_bytes() -> PackedByteArray:
	var parsed := {
		"file_type": "GIT ",
		"root": {
			"Creature List": [
				{
					"TemplateResRef": "n_malak",
					"Tag": "malak",
					"XPosition": 1.0,
					"YPosition": 2.0,
					"ZPosition": 0.0,
					"Bearing": 0.0,
				},
			],
			"Door List": [],
			"Encounter List": [],
			"Placeable List": [],
			"SoundList": [],
			"StoreList": [],
			"TriggerList": [],
			"WaypointList": [],
		},
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": [
				{
					"name": "Creature List",
					"type": GFFParser.FIELD_LIST,
					"items": [
						{
							"struct_type": 1,
							"fields": [
								{"name": "TemplateResRef", "type": GFFParser.FIELD_CRESREF},
								{"name": "Tag", "type": GFFParser.FIELD_CEXOSTRING},
								{"name": "XPosition", "type": GFFParser.FIELD_FLOAT},
								{"name": "YPosition", "type": GFFParser.FIELD_FLOAT},
								{"name": "ZPosition", "type": GFFParser.FIELD_FLOAT},
								{"name": "Bearing", "type": GFFParser.FIELD_FLOAT},
							],
						},
					],
				},
			],
		},
	}
	return GFFWriter.serialize(GFFResourceFactory.create_from_parser_result(parsed))


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _cleanup() -> void:
	var override_dir := _install_root.path_join("override")
	for file_name in ["tar_m02aa.git", "onheartbeat.nss"]:
		var path := override_dir.path_join(file_name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(override_dir):
		DirAccess.remove_absolute(override_dir)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
