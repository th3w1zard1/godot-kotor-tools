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
	_test_feat_and_skills_tables()
	_test_non_sequential_row_indices()
	_test_cache_clear_on_reindex()
	_test_out_of_range_2da_value_allowed()
	_test_traps_table_mapping()
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


func _test_feat_and_skills_tables() -> void:
	var install_path := ProjectSettings.globalize_path("user://enum_registry_feat_skills")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var feat_path := override_dir.path_join("feat.2da")
	var skills_path := override_dir.path_join("skills.2da")
	var feat_file := FileAccess.open(feat_path, FileAccess.WRITE)
	assert(feat_file != null)
	feat_file.store_string("2DA V2.0\n\nlabel\n0 Flurry\n1 Power Attack\n")
	feat_file.close()
	var skills_file := FileAccess.open(skills_path, FileAccess.WRITE)
	assert(skills_file != null)
	skills_file.store_string("2DA V2.0\n\nlabel\n0 Computer Use\n1 Demolitions\n2 Stealth\n")
	skills_file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.clear_cache()
	var feat_values := registry.get_enum_values("Feat")
	assert(registry.get_enum_source("Feat") == "2da")
	assert(feat_values[0] == "Flurry")
	assert(registry.get_skill_label(2) == "Stealth")
	assert(TypedFieldHelpers.has_enum_hints("Feat", registry))

	DirAccess.remove_absolute(feat_path)
	DirAccess.remove_absolute(skills_path)
	print("✓ Enum registry feat/skills tables passed")


func _test_non_sequential_row_indices() -> void:
	var install_path := ProjectSettings.globalize_path("user://enum_registry_sparse_rows")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var feat_path := override_dir.path_join("feat.2da")
	var skills_path := override_dir.path_join("skills.2da")
	var feat_file := FileAccess.open(feat_path, FileAccess.WRITE)
	assert(feat_file != null)
	feat_file.store_string("2DA V2.0\n\nlabel\n2 Flurry\n5 \"Power Attack\"\n")
	feat_file.close()
	var skills_file := FileAccess.open(skills_path, FileAccess.WRITE)
	assert(skills_file != null)
	skills_file.store_string("2DA V2.0\n\nlabel\n7 Awareness\n12 Repair\n")
	skills_file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.clear_cache()
	var feat_values := registry.get_enum_values("Feat")
	assert(feat_values[2] == "Flurry")
	assert(feat_values[5] == "Power Attack")
	assert(registry.get_skill_label(12) == "Repair")
	assert(registry.get_skill_label(1) == "")

	DirAccess.remove_absolute(feat_path)
	DirAccess.remove_absolute(skills_path)
	print("✓ Enum registry sparse row indices passed")


func _test_cache_clear_on_reindex() -> void:
	var state := KotorEditorState.new()
	state.load_settings()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.get_enum_values("Gender")
	assert(registry.has_cached_entries())
	state.refresh_gamefs()
	assert(registry.cache_size() == 0)
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


func _test_traps_table_mapping() -> void:
	var install_path := ProjectSettings.globalize_path("user://enum_registry_traps")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var traps_path := override_dir.path_join("traps.2da")
	var file := FileAccess.open(traps_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string("2DA V2.0\n\nlabel\n0 \"Minor Blast\"\n")
	file.close()

	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry: KotorEnumRegistry = state.enum_registry
	registry.clear_cache()
	assert(registry.get_enum_source("TrapType") == "2da")
	assert(registry.get_enum_values("TrapType")[0] == "Minor Blast")
	DirAccess.remove_absolute(traps_path)
	print("✓ Enum registry traps.2da mapping passed")
