@tool
extends SceneTree

const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_item_field_detection()
	_test_item_picker_dialog()
	print("✓ Item picker tests passed")
	quit()


func _test_item_field_detection() -> void:
	assert(TypedFieldHelpers.is_item_resref_field("InventoryRes"))
	assert(TypedFieldHelpers.is_item_resref_field("ResRef", ["itemList", 0]))
	assert(not TypedFieldHelpers.is_item_resref_field("ResRef", ["ScriptList"]))
	assert(TypedFieldHelpers.is_item_resref_field("TemplateItemRes"))
	print("✓ Item field detection passed")


func _test_item_picker_dialog() -> void:
	var install_path := ProjectSettings.globalize_path("user://item_picker_install")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var uti_path := override_dir.path_join("test_item.uti")
	var file := FileAccess.open(uti_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("GFF V3.2 placeholder")
	file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()

	var dialog := preload("../../ui/workspace/dialogs/kotor_item_picker_dialog.gd").new()
	root.add_child(dialog)
	dialog.configure(state, "uti", "test_item")
	dialog._refresh_entries("test_item")
	var tree_root := dialog._tree.get_root()
	assert(tree_root != null)
	var first := tree_root.get_first_child()
	assert(first != null)
	first.select(0)
	dialog._on_item_selected()
	assert(dialog.get_selected_resref() == "test_item")
	dialog.queue_free()
	DirAccess.remove_absolute(uti_path)
	print("✓ Item picker dialog indexed install passed")
