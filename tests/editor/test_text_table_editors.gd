@tool
extends SceneTree

const KotorWorkspaceController := preload("../../editor/workspace/kotor_workspace_controller.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorTwoDaWorkspaceEditor := preload("../../ui/workspace/editors/twoda_workspace_editor.gd")
const KotorTLKWorkspaceEditor := preload("../../ui/workspace/editors/tlk_workspace_editor.gd")
const KotorScriptWorkspaceEditor := preload("../../ui/workspace/editors/script_workspace_editor.gd")
const TwoDaResource := preload("../../resources/twoda_resource.gd")
const TLKResource := preload("../../resources/tlk_resource.gd")
const TLKParser := preload("../../formats/tlk_parser.gd")

var _install_root := ""
var _twoda_path := ""
var _tlk_path := ""
var _script_path := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://text_table_editor_install")
	_twoda_path = _install_root.path_join("skills.2da")
	_tlk_path = _install_root.path_join("dialog.tlk")
	_script_path = _install_root.path_join("testscript.nss")
	if DirAccess.dir_exists_absolute(_install_root):
		_cleanup()
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_assert_text_table_editors")


func _assert_text_table_editors() -> void:
	var editor_state := KotorEditorState.new()
	editor_state.game_path = _install_root
	editor_state.refresh_gamefs()
	var controller := KotorWorkspaceController.new(editor_state)

	var twoda_editor := KotorTwoDaWorkspaceEditor.new()
	twoda_editor._skip_preflight_for_testing = true
	twoda_editor.setup(editor_state, controller)
	root.add_child(twoda_editor)

	var tlk_editor := KotorTLKWorkspaceEditor.new()
	tlk_editor._skip_preflight_for_testing = true
	tlk_editor.setup(editor_state, controller)
	root.add_child(tlk_editor)

	var script_editor := KotorScriptWorkspaceEditor.new()
	script_editor._skip_preflight_for_testing = true
	script_editor.setup(editor_state, controller)
	root.add_child(script_editor)

	var twoda_resource := TwoDaResource.new()
	twoda_resource.columns = PackedStringArray(["label", "value"])
	twoda_resource.rows = [{"label": "A", "value": "1"}]
	twoda_editor.open_resource(twoda_resource, "", "skills.2da")
	assert(twoda_editor.get_document().set_cell(0, "value", "2"))
	assert(twoda_editor.is_document_dirty())
	assert(twoda_editor.save_document_to_path(_twoda_path).get("applied", false))
	assert(twoda_editor.install_document_to_override().get("applied", false))

	var tlk_resource := TLKResource.new()
	tlk_resource.apply_parser_result({
		"version": "V3.0",
		"language_id": 0,
		"entries": [_make_tlk_entry(0, "Hello there.")],
	})
	assert(int(tlk_resource.get_entry(0).get("volume_variance", -1)) == 12)
	assert(int(tlk_resource.get_entry(0).get("pitch_variance", -1)) == 34)
	tlk_editor.open_resource(tlk_resource, "", "dialog.tlk")
	assert(tlk_editor.get_document().set_entry_text(0, "General Kenobi."))
	assert(tlk_editor.is_document_dirty())
	assert(tlk_editor.save_document_to_path(_tlk_path).get("applied", false))
	assert(tlk_editor.install_document_to_override().get("applied", false))

	assert(controller.mutation_service.apply_install_to_override(editor_state.gamefs, "testscript.ncs", PackedByteArray([0x4E, 0x43, 0x53, 0x20])).get("applied", false))
	editor_state.refresh_gamefs()
	script_editor.open_script_bytes("testscript.nss", "void main() { SpeakString(\"hi\"); }\n".to_ascii_buffer(), "nss", _script_path)
	assert(script_editor.get_document().counterpart_label().contains("testscript.ncs"))
	assert(script_editor.get_document().set_text("void main() { SpeakString(\"bye\"); }\n"))
	assert(script_editor.is_document_dirty())
	assert(script_editor.save_document_to_path(_script_path).get("applied", false))
	assert(script_editor.install_document_to_override().get("applied", false))
	assert(script_editor.get_validation_text().contains("Script validation passed."))

	var documents: Array[Dictionary] = controller.document_registry.list_documents()
	assert(documents.size() == 3)
	assert(controller.document_registry.get_document_entry("twoda:%s" % _twoda_path).get("dirty", false) == false)
	assert(controller.document_registry.get_document_entry("tlk:%s" % _tlk_path).get("dirty", false) == false)
	assert(controller.document_registry.get_document_entry("script:%s" % _script_path).get("dirty", false) == false)

	_cleanup()
	quit()


func _make_tlk_entry(strref: int, text: String) -> TLKParser.TLKEntry:
	var entry := TLKParser.TLKEntry.new()
	entry.strref = strref
	entry.flags = 1
	entry.sound_resref = ""
	entry.volume_variance = 12
	entry.pitch_variance = 34
	entry.offset = 0
	entry.size = text.length()
	entry.sound_length = 0.0
	entry.text = text
	return entry


func _cleanup() -> void:
	for path in [
		_twoda_path,
		_tlk_path,
		_script_path,
		_install_root.path_join("override").path_join("skills.2da"),
		_install_root.path_join("override").path_join("dialog.tlk"),
		_install_root.path_join("override").path_join("testscript.nss"),
		_install_root.path_join("override").path_join("testscript.ncs"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for directory in [
		_install_root.path_join("override"),
		_install_root,
	]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)
