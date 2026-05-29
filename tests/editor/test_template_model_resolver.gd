@tool
extends SceneTree

const GFFParser := preload("../../formats/gff_parser.gd")
const GFFWriter := preload("../../formats/gff_writer.gd")
const GFFResourceFactory := preload("../../resources/gff_resource_factory.gd")
const KotorGameFS := preload("../../gamefs/kotor_gamefs.gd")
const KotorTemplateModelResolver := preload("../../editor/module/kotor_template_model_resolver.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://template_model_resolver_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	KotorTemplateModelResolver.clear_cache()
	_test_supports_mesh_category()
	_test_creature_modeltype_b()
	_test_creature_modeltype_race()
	_test_placeable_model()
	_test_door_generic_type()
	_test_invalid_template_returns_empty()
	_cleanup()
	print("✓ Template model resolver tests passed")
	quit()


func _test_supports_mesh_category() -> void:
	assert(KotorTemplateModelResolver.supports_mesh_category("Creatures"))
	assert(KotorTemplateModelResolver.supports_mesh_category("Placeables"))
	assert(KotorTemplateModelResolver.supports_mesh_category("Doors"))
	assert(not KotorTemplateModelResolver.supports_mesh_category("Triggers"))
	print("✓ Mesh category support passed")


func _test_creature_modeltype_b() -> void:
	var gamefs := _build_gamefs()
	_write_twoda(
		gamefs,
		"appearance.2da",
		"2DA V2.0\n\nmodeltype modela race\n0 B p_bastilla human\n"
	)
	_write_gff(
		gamefs,
		"npc_bastilla.utc",
		_build_blueprint_resource("UTC", {"Appearance_Type": 0})
	)
	gamefs.index_install(_install_root)
	var model := KotorTemplateModelResolver.resolve_model_resref(gamefs, "Creatures", "npc_bastilla")
	assert(model == "p_bastilla")
	print("✓ Creature modeltype B resolution passed")


func _test_creature_modeltype_race() -> void:
	KotorTemplateModelResolver.clear_cache()
	var gamefs := _build_gamefs()
	_write_twoda(
		gamefs,
		"appearance.2da",
		"2DA V2.0\n\nmodeltype modela race\n1 F **** c_droid\n"
	)
	_write_gff(
		gamefs,
		"npc_droid.utc",
		_build_blueprint_resource("UTC", {"Appearance_Type": 1})
	)
	gamefs.index_install(_install_root)
	var model := KotorTemplateModelResolver.resolve_model_resref(gamefs, "Creatures", "npc_droid")
	assert(model == "c_droid")
	print("✓ Creature race model resolution passed")


func _test_placeable_model() -> void:
	KotorTemplateModelResolver.clear_cache()
	var gamefs := _build_gamefs()
	_write_twoda(
		gamefs,
		"placeables.2da",
		"2DA V2.0\n\nmodelname\n0 plc_chair01\n"
	)
	_write_gff(
		gamefs,
		"plc_chair.utp",
		_build_blueprint_resource("UTP", {"Appearance_Type": 0})
	)
	gamefs.index_install(_install_root)
	var model := KotorTemplateModelResolver.resolve_model_resref(gamefs, "Placeables", "plc_chair")
	assert(model == "plc_chair01")
	print("✓ Placeable model resolution passed")


func _test_door_generic_type() -> void:
	KotorTemplateModelResolver.clear_cache()
	var gamefs := _build_gamefs()
	_write_twoda(
		gamefs,
		"genericdoors.2da",
		"2DA V2.0\n\nmodelname\n2 door_generic02\n"
	)
	_write_gff(
		gamefs,
		"door_test.utd",
		_build_blueprint_resource("UTD", {"GenericType": 2})
	)
	gamefs.index_install(_install_root)
	var model := KotorTemplateModelResolver.resolve_model_resref(gamefs, "Doors", "door_test")
	assert(model == "door_generic02")
	print("✓ Door model resolution passed")


func _test_invalid_template_returns_empty() -> void:
	KotorTemplateModelResolver.clear_cache()
	var gamefs := _build_gamefs()
	gamefs.index_install(_install_root)
	assert(KotorTemplateModelResolver.resolve_model_resref(gamefs, "Creatures", "") == "")
	assert(KotorTemplateModelResolver.resolve_model_resref(gamefs, "Creatures", "missing_npc") == "")
	assert(KotorTemplateModelResolver.resolve_model_resref(gamefs, "Triggers", "foo") == "")
	print("✓ Invalid template handling passed")


func _build_gamefs() -> KotorGameFS:
	var gamefs := KotorGameFS.new()
	gamefs.game_path = _install_root
	return gamefs


func _write_twoda(_gamefs: KotorGameFS, filename: String, text: String) -> void:
	var path := _install_root.path_join("override").path_join(filename)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(text)
	file.close()


func _write_gff(_gamefs: KotorGameFS, filename: String, resource: Resource) -> void:
	var path := _install_root.path_join("override").path_join(filename)
	var err := GFFWriter.save_resource(resource, path)
	assert(err == OK)


func _build_blueprint_resource(file_type: String, root: Dictionary) -> Resource:
	var fields: Array = []
	for key in root.keys():
		var value = root[key]
		var field_type := GFFParser.FIELD_INT
		if typeof(value) == TYPE_STRING:
			field_type = GFFParser.FIELD_CEXOSTRING
		fields.append({"name": key, "type": field_type})
	var resource := GFFResourceFactory.create_from_parser_result({
		"file_type": file_type,
		"root": root,
		"schema": {
			"struct_type": 0xFFFFFFFF,
			"fields": fields,
		},
	})
	return resource


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(_install_root):
		_remove_dir_recursive(_install_root)


func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var child := path.path_join(name)
			if DirAccess.dir_exists_absolute(child):
				_remove_dir_recursive(child)
			else:
				DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
