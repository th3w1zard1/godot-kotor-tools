@tool
extends SceneTree

const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")
const KotorGFFDocument := preload("../../resources/kotor_gff_document.gd")
const KotorDLGDocument := preload("../../resources/documents/kotor_dlg_document.gd")
const GFFParser := preload("../../formats/gff_parser.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_resref_validation()
	_test_resref_field_detection()
	_test_enum_field_hints()
	_test_enum_validation()
	_test_gff_document_resref_method()
	_test_dlg_document_resref_method()
	_test_whitespace_trimming()
	quit()


func _test_resref_validation() -> void:
	assert(TypedFieldHelpers.validate_resref("short") == "short", "Short resref should pass through")
	assert(TypedFieldHelpers.validate_resref("  spaces  ") == "spaces", "Whitespace should be trimmed")
	assert(TypedFieldHelpers.validate_resref("exactly16chars!") == "exactly16chars!", "16-char resref should pass")
	assert(TypedFieldHelpers.validate_resref("toolongresrefname") == "toolongresrefnam", "Resref longer than 16 chars should be truncated")
	assert(TypedFieldHelpers.validate_resref("this_is_way_too_long_for_a_resref") == "this_is_way_too_", "Long resref should be truncated to 16 chars")
	print("✓ Resref validation tests passed")


func _test_resref_field_detection() -> void:
	assert(TypedFieldHelpers.is_resref_field("HeadRef"), "HeadRef should be detected as resref field")
	assert(TypedFieldHelpers.is_resref_field("BodyRef"), "BodyRef should be detected as resref field")
	assert(TypedFieldHelpers.is_resref_field("TemplateResRef"), "TemplateResRef should be detected as resref field")
	assert(not TypedFieldHelpers.is_resref_field("Tag"), "Tag should not be detected as resref field")
	assert(not TypedFieldHelpers.is_resref_field("Name"), "Name should not be detected as resref field")
	assert(not TypedFieldHelpers.is_resref_field("Description"), "Description should not be detected as resref field")
	print("✓ Resref field detection tests passed")


func _test_enum_field_hints() -> void:
	assert(TypedFieldHelpers.has_enum_hints("Gender"), "Gender should have enum hints")
	assert(TypedFieldHelpers.has_enum_hints("Race"), "Race should have enum hints")
	assert(TypedFieldHelpers.has_enum_hints("Appearance_Type"), "Appearance_Type should have enum hints")
	assert(not TypedFieldHelpers.has_enum_hints("Tag"), "Tag should not have enum hints")
	assert(not TypedFieldHelpers.has_enum_hints("Name"), "Name should not have enum hints")
	
	var gender_values = TypedFieldHelpers.get_enum_values("Gender")
	assert(gender_values.size() == 2, "Gender should have 2 values")
	assert(gender_values[0] == "Male", "Gender 0 should be Male")
	assert(gender_values[1] == "Female", "Gender 1 should be Female")
	
	var race_values = TypedFieldHelpers.get_enum_values("Race")
	assert(race_values.size() == 6, "Race should have 6 values")
	assert(race_values[3] == "Human", "Race 3 should be Human")
	
	print("✓ Enum field hints tests passed")


func _test_enum_validation() -> void:
	assert(TypedFieldHelpers.validate_enum_value("Gender", 0), "Gender 0 should be valid")
	assert(TypedFieldHelpers.validate_enum_value("Gender", 1), "Gender 1 should be valid")
	assert(not TypedFieldHelpers.validate_enum_value("Gender", 2), "Gender 2 should be invalid")
	assert(not TypedFieldHelpers.validate_enum_value("Gender", 99), "Gender 99 should be invalid")
	
	assert(TypedFieldHelpers.validate_enum_value("Race", 0), "Race 0 should be valid")
	assert(TypedFieldHelpers.validate_enum_value("Race", 3), "Race 3 should be valid")
	assert(not TypedFieldHelpers.validate_enum_value("Race", 6), "Race 6 should be invalid")
	assert(not TypedFieldHelpers.validate_enum_value("Race", 100), "Race 100 should be invalid")
	
	assert(TypedFieldHelpers.get_enum_display_name("Gender", 0) == "Male", "Gender 0 should display as Male")
	assert(TypedFieldHelpers.get_enum_display_name("Gender", 1) == "Female", "Gender 1 should display as Female")
	assert(TypedFieldHelpers.get_enum_display_name("Gender", 99) == "Unknown (99)", "Unknown value should show Unknown")
	
	print("✓ Enum validation tests passed")


func _test_gff_document_resref_method() -> void:
	var doc = KotorGFFDocument.new()
	doc.setup("UTC", {})
	
	assert(doc.validate_resref("short") == "short", "Short resref should pass through")
	assert(doc.validate_resref("  spaces  ") == "spaces", "Whitespace should be trimmed")
	assert(doc.validate_resref("exactly16chars!") == "exactly16chars!", "16-char resref should pass")
	assert(doc.validate_resref("toolongresrefname") == "toolongresrefnam", "Resref longer than 16 chars should be truncated")
	
	print("✓ GFF document resref validation tests passed")


func _test_dlg_document_resref_method() -> void:
	var doc = KotorDLGDocument.new()
	doc.setup("DLG", {})
	
	assert(doc.validate_resref("short") == "short", "Short resref should pass through")
	assert(doc.validate_resref("  spaces  ") == "spaces", "Whitespace should be trimmed")
	assert(doc.validate_resref("exactly16chars!") == "exactly16chars!", "16-char resref should pass")
	assert(doc.validate_resref("toolongresrefname") == "toolongresrefnam", "Resref longer than 16 chars should be truncated")
	
	print("✓ DLG document resref validation tests passed")


func _test_whitespace_trimming() -> void:
	assert(TypedFieldHelpers.validate_resref("  leading") == "leading", "Leading whitespace should be trimmed")
	assert(TypedFieldHelpers.validate_resref("trailing  ") == "trailing", "Trailing whitespace should be trimmed")
	assert(TypedFieldHelpers.validate_resref("  both  ") == "both", "Both leading and trailing whitespace should be trimmed")
	assert(TypedFieldHelpers.validate_resref("\t\ttabs\t\t") == "tabs", "Tab characters should be trimmed")
	assert(TypedFieldHelpers.validate_resref("\n\nnewlines\n\n") == "newlines", "Newline characters should be trimmed")
	
	print("✓ Whitespace trimming tests passed")
