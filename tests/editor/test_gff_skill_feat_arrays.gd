@tool
extends SceneTree

const UTCResource := preload("../../resources/typed/utc_resource.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")
const GFFTreePopulator := preload("../../ui/workspace/gff_tree_populator.gd")

const SKILL_DEFAULT := { "Rank": 0 }
const FEAT_DEFAULT := { "Feat": 65535 }


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_editable_array_registration()
	_test_validation_warnings()
	_test_skilllist_insert_remove()
	_test_featlist_insert_reorder()
	_test_feat_enum_hints_without_static_map()
	print("✓ GFF skill/feat array tests passed")
	quit()


func _test_editable_array_registration() -> void:
	assert(GFFTreePopulator.EDITABLE_STRUCT_ARRAY_FIELDS.has("SkillList"))
	assert(GFFTreePopulator.EDITABLE_STRUCT_ARRAY_FIELDS.has("FeatList"))
	print("✓ Editable skill/feat arrays registered")


func _test_validation_warnings() -> void:
	assert(TypedFieldHelpers.get_validation_warning("Rank", -1).contains("negative"))
	assert(TypedFieldHelpers.get_validation_warning("Rank", 128).contains("127"))
	assert(TypedFieldHelpers.get_validation_warning("Feat", 65535).contains("unset"))
	assert(TypedFieldHelpers.get_validation_warning("Feat", -1).contains("negative"))
	print("✓ Skill/feat validation warnings passed")


func _test_skilllist_insert_remove() -> void:
	var resource := _build_creature_with_skills()
	var document = resource.create_document()
	var initial_size := (document.get_field("SkillList") as Array).size()
	document.insert_struct_at_array("SkillList", initial_size, SKILL_DEFAULT.duplicate())
	assert((document.get_field("SkillList") as Array).size() == initial_size + 1)
	var inserted := (document.get_field("SkillList") as Array)[initial_size] as Dictionary
	assert(inserted.get("Rank") == 0)
	document.remove_struct_from_array("SkillList", 0)
	assert((document.get_field("SkillList") as Array).size() == initial_size)
	print("✓ SkillList insert/remove passed")


func _test_featlist_insert_reorder() -> void:
	var resource := _build_creature_with_feats()
	var document = resource.create_document()
	var items := document.get_field("FeatList") as Array
	var first_feat := int((items[0] as Dictionary).get("Feat", -1))
	var second_feat := int((items[1] as Dictionary).get("Feat", -1))
	document.reorder_array_item("FeatList", 0, 1)
	var reordered := document.get_field("FeatList") as Array
	assert(int((reordered[0] as Dictionary).get("Feat", -1)) == second_feat)
	assert(int((reordered[1] as Dictionary).get("Feat", -1)) == first_feat)
	document.insert_struct_at_array("FeatList", reordered.size(), FEAT_DEFAULT.duplicate())
	var last := (document.get_field("FeatList") as Array).back() as Dictionary
	assert(int(last.get("Feat", -1)) == 65535)
	print("✓ FeatList reorder/insert passed")


func _test_feat_enum_hints_without_static_map() -> void:
	assert(TypedFieldHelpers.ENUM_FIELD_MAPPING.get("Feat", {}).is_empty())
	var install_path := ProjectSettings.globalize_path("user://skill_feat_enum_install")
	var override_dir := install_path.path_join("override")
	DirAccess.make_dir_recursive_absolute(override_dir)
	var feat_path := override_dir.path_join("feat.2da")
	var feat_file := FileAccess.open(feat_path, FileAccess.WRITE)
	assert(feat_file != null)
	feat_file.store_string("2DA V2.0\n\nlabel\n0 Flurry\n")
	feat_file.close()
	var state := KotorEditorState.new()
	state.game_path = install_path
	state.refresh_gamefs()
	var registry = state.enum_registry
	registry.clear_cache()
	assert(TypedFieldHelpers.has_enum_hints("Feat", registry))
	DirAccess.remove_absolute(feat_path)
	print("✓ Feat enum hints from 2DA passed")


func _build_creature_with_skills() -> UTCResource:
	var resource := UTCResource.new()
	resource.file_type = "UTC "
	resource.gff_data = {
		"Tag": "skill_creature",
		"SkillList": [
			{"Rank": 4},
			{"Rank": 2},
		],
	}
	return resource


func _build_creature_with_feats() -> UTCResource:
	var resource := UTCResource.new()
	resource.file_type = "UTC "
	resource.gff_data = {
		"Tag": "feat_creature",
		"FeatList": [
			{"Feat": 12},
			{"Feat": 34},
		],
	}
	return resource
