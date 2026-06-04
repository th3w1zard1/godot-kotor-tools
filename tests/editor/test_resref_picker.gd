@tool
extends SceneTree

const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_resref_type_hints()
	_test_normalize_picker_selection()
	_test_enum_option_parsing()
	_test_picker_dialog_without_index()
	_test_picker_dialog_with_index()
	quit()


func _test_resref_type_hints() -> void:
	assert(TypedFieldHelpers.get_resref_type_hint("Script") == "nss")
	assert(TypedFieldHelpers.get_resref_type_hint("Sound") == "wav")
	assert(TypedFieldHelpers.get_resref_type_hint("OnRunScript") == "nss")
	assert(TypedFieldHelpers.get_resref_type_hint("OnClick") == "nss")
	assert(TypedFieldHelpers.get_resref_type_hint("ScriptHeartbeat") == "nss")
	assert(TypedFieldHelpers.get_resref_type_hint("Tag") == "")
	print("✓ ResRef type hint tests passed")


func _test_normalize_picker_selection() -> void:
	var entry := {"resref": "  test_script  "}
	assert(TypedFieldHelpers.normalize_picker_selection(entry) == "test_script")
	var long_entry := {"resref": "this_is_way_too_long_for_a_resref"}
	assert(
		TypedFieldHelpers.normalize_picker_selection(long_entry).length()
		== TypedFieldHelpers.MAX_RESREF_LENGTH
	)
	print("✓ Picker selection normalization tests passed")


func _test_enum_option_parsing() -> void:
	assert(TypedFieldHelpers.parse_enum_option_index("1: Female") == 1)
	assert(TypedFieldHelpers.find_enum_option_index("Gender", 1) >= 0)
	print("✓ Enum option parsing tests passed")


func _test_picker_dialog_without_index() -> void:
	var dialog := preload("../../ui/workspace/dialogs/kotor_resref_picker_dialog.gd").new()
	dialog.configure(KotorEditorState.new(), "", "")
	assert(dialog.get_selected_resref().is_empty())
	print("✓ Picker dialog no-index test passed")


func _test_picker_dialog_with_index() -> void:
	var install_path := ProjectSettings.globalize_path("user://resref_picker_install")
	DirAccess.make_dir_recursive_absolute(install_path.path_join("override"))
	var script_path := install_path.path_join("override").path_join("picker_test.nss")
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("// picker test")
	file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()

	var dialog := preload("../../ui/workspace/dialogs/kotor_resref_picker_dialog.gd").new()
	root.add_child(dialog)
	dialog.configure(state, "nss", "picker_test")
	dialog._refresh_entries("picker_test")
	var tree_root := dialog._tree.get_root()
	assert(tree_root != null)
	var first := tree_root.get_first_child()
	assert(first != null)
	first.select(0)
	dialog._on_item_selected()
	assert(dialog.get_selected_resref() == "picker_test")
	dialog.queue_free()
	print("✓ Picker dialog indexed install test passed")

	DirAccess.remove_absolute(script_path)
