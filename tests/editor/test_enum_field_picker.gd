@tool
extends SceneTree

const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_enum_option_array()
	_test_find_enum_option_index()
	_test_language_ids()
	print("✓ Enum field picker helper tests passed")
	quit()


func _test_enum_option_array() -> void:
	var options := TypedFieldHelpers.get_enum_options_as_array("Gender")
	assert(options.size() == 2)
	assert(options[0].begins_with("0:"))
	assert(options[1].begins_with("1:"))
	print("✓ Enum option array tests passed")


func _test_find_enum_option_index() -> void:
	assert(TypedFieldHelpers.find_enum_option_index("Race", 3) >= 0)
	assert(TypedFieldHelpers.find_enum_option_index("Race", 99) == -1)
	print("✓ Enum option index lookup tests passed")


func _test_language_ids() -> void:
	assert(TypedFieldHelpers.LOCSTRING_LANGUAGE_IDS.size() >= 1)
	assert(TypedFieldHelpers.LOCSTRING_LANGUAGE_IDS[0] == 0)
	print("✓ Locstring language ID tests passed")
