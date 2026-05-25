@tool
extends SceneTree

const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorEnumRegistry := preload("../../editor/workspace/kotor_enum_registry.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_static_fallback()
	_test_2da_load()
	_test_cache_clear_on_reindex()
	_test_out_of_range_2da_value_allowed()
	print("✓ Enum registry tests passed")
	quit()


func _test_static_fallback() -> void:
	var state := KotorEditorState.new()
	state.load_settings()
	var registry: KotorEnumRegistry = state.enum_registry
	assert(registry.get_enum_source("Gender") == "static")
	assert(registry.get_enum_values("Gender").has(0))
	print("✓ Enum registry static fallback passed")


func _test_2da_load() -> void:
	var install_path := ProjectSettings.globalize_path("user://enum_registry_install")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var gender_path := override_dir.path_join("gender.2da")
	var file := FileAccess.open(gender_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("2DA V2.0\n\nlabel\n0 Male\n1 Female\n2 Other\n")
	file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.clear_cache()
	var values := registry.get_enum_values("Gender")
	assert(registry.get_enum_source("Gender") == "2da")
	assert(values.size() >= 3)
	assert(values[2] == "Other")

	DirAccess.remove_absolute(gender_path)
	print("✓ Enum registry 2DA load passed")


func _test_cache_clear_on_reindex() -> void:
	var state := KotorEditorState.new()
	state.load_settings()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.get_enum_values("Gender")
	assert(not registry._cache.is_empty())
	state.refresh_gamefs()
	assert(registry._cache.is_empty())
	print("✓ Enum registry cache clear passed")


func _test_out_of_range_2da_value_allowed() -> void:
	var install_path := ProjectSettings.globalize_path("user://enum_registry_install2")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var gender_path := override_dir.path_join("gender.2da")
	var file := FileAccess.open(gender_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("2DA V2.0\n\nlabel\n0 Male\n1 Female\n")
	file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.clear_cache()
	assert(TypedFieldHelpers.validate_enum_value("Gender", 99, registry))
	DirAccess.remove_absolute(gender_path)
	print("✓ Enum registry out-of-range validation passed")
