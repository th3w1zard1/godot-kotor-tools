@tool
extends SceneTree

const BWMParser := preload("../../formats/bwm_parser.gd")
const KotorEditorState := preload("../../editor/core/kotor_editor_state.gd")
const KotorIndoorDocument := preload("../../resources/documents/kotor_indoor_document.gd")
const KotorIndoorKitLibrary := preload("../../resources/indoor/kotor_indoor_kit_library.gd")
const KotorIndoorBuilderWorkspaceEditor := preload("../../ui/workspace/editors/indoor_builder_workspace_editor.gd")
const KotorModuleKitLoader := preload("../../resources/indoor/kotor_module_kit_loader.gd")

var _install_root := ""


func _initialize() -> void:
	_install_root = ProjectSettings.globalize_path("user://module_kit_loader_test")
	DirAccess.make_dir_recursive_absolute(_install_root.path_join("override"))
	call_deferred("_run_tests")


func _run_tests() -> void:
	_seed_install_files()
	_test_discover_module_roots()
	_test_load_module_kit_components()
	_test_kit_library_registers_module_kit()
	_test_document_add_room_from_module_kit()
	var button_ok := await _test_indoor_builder_module_kit_button()
	_cleanup()
	if not button_ok:
		push_error("Indoor builder module kit button test failed")
		quit(1)
	print("✓ ModuleKit loader tests passed")
	quit()


func _test_discover_module_roots() -> void:
	var gamefs := _build_gamefs()
	var roots := KotorModuleKitLoader.discover_module_roots(gamefs)
	assert(roots.has("tar_m02aa"))
	print("✓ ModuleKit discovery passed")


func _test_load_module_kit_components() -> void:
	var gamefs := _build_gamefs()
	var result := KotorModuleKitLoader.load_module_kit(gamefs, "tar_m02aa")
	assert(result.get("ok", false))
	var kit: Dictionary = result.get("kit", {})
	assert(str(kit.get("id", "")) == "tar_m02aa")
	assert(bool(kit.get("is_module_kit", false)))
	var components: Array = kit.get("components", [])
	assert(components.size() == 2)
	var first: Dictionary = components[0]
	assert(str(first.get("id", "")) == "room001_0")
	assert(float(first.get("half_width", 0.0)) > 0.0)
	assert(bool(first.get("has_mdl", false)))
	print("✓ ModuleKit load passed")


func _test_kit_library_registers_module_kit() -> void:
	var library := KotorIndoorKitLibrary.new()
	var registration := library.register_module_kits_from_gamefs(_build_gamefs())
	assert(int(registration.get("loaded", 0)) >= 1)
	assert(library.is_module_kit("tar_m02aa"))
	assert(library.has_component("tar_m02aa", "room001_0"))
	var summaries := library.get_component_summaries("tar_m02aa")
	assert(summaries.size() == 2)
	print("✓ ModuleKit library registration passed")


func _test_document_add_room_from_module_kit() -> void:
	var library := KotorIndoorKitLibrary.new()
	library.register_module_kits_from_gamefs(_build_gamefs())
	var document := KotorIndoorDocument.new()
	document.load_from_dictionary({
		"module_id": "test01",
		"warp": "test01",
		"name": {"stringref": -1},
		"lighting": [0.5, 0.5, 0.5],
		"skybox": "",
		"embedded_components": [],
		"rooms": [],
	})
	document.set_kit_library(library)
	var index := document.add_room_from_kit("tar_m02aa", "room001_0", Vector3(1.0, 2.0, 0.0), 0.0)
	assert(index == 0)
	assert(document.get_room_count() == 1)
	print("✓ ModuleKit document add room passed")


func _test_indoor_builder_module_kit_button() -> bool:
	var editor_state := _build_editor_state()
	var editor := KotorIndoorBuilderWorkspaceEditor.new()
	editor.setup(editor_state)
	var holder := Node.new()
	root.add_child(holder)
	holder.add_child(editor)
	await process_frame

	var button := _find_button(editor, "Refresh Module Kits")
	assert(button != null)
	holder.queue_free()
	await process_frame
	print("✓ Indoor builder module kit button passed")
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
	_write_text(override_dir.path_join("tar_m02aa.lyt"), _build_layout_text())
	_write_bytes(
		override_dir.path_join("room001.wok"),
		_build_minimal_wok(
			[Vector3(0, 0, 0), Vector3(4, 0, 0), Vector3(0, 0, 4)],
			[0, 1, 2],
			[1]
		)
	)
	_write_bytes(override_dir.path_join("room001.mdl"), PackedByteArray([0x00, 0x01, 0x02]))


func _build_layout_text() -> String:
	return "\n".join([
		"beginlayout",
		"roomcount 2",
		"roommodel room001 0.0 0.0 0.0",
		"roommodel room002 4.0 0.0 0.0",
		"donelayout",
	])


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


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


static func _build_minimal_wok(vertices: Array, face_indices: Array, materials: Array) -> PackedByteArray:
	var vertex_count := vertices.size()
	var face_count := materials.size()
	var vertices_offset := BWMParser.HEADER_SIZE
	var indices_offset := vertices_offset + vertex_count * 12
	var materials_offset := indices_offset + face_count * 12
	var total_size := materials_offset + face_count * 4

	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.resize(total_size)

	_write_fixed_string(stream, BWMParser.MAGIC, 4)
	_write_fixed_string(stream, BWMParser.VERSION, 4)
	stream.put_u32(0)
	for _i in range(5):
		_write_vector3(stream, Vector3.ZERO)
	stream.put_u32(vertex_count)
	stream.put_u32(vertices_offset)
	stream.put_u32(face_count)
	stream.put_u32(indices_offset)
	stream.put_u32(materials_offset)

	stream.seek(vertices_offset)
	for vertex in vertices:
		_write_vector3(stream, vertex)

	stream.seek(indices_offset)
	for index in face_indices:
		stream.put_u32(index)

	stream.seek(materials_offset)
	for material_id in materials:
		stream.put_u32(material_id)

	return stream.data_array


static func _write_vector3(stream: StreamPeerBuffer, value: Vector3) -> void:
	stream.put_float(value.x)
	stream.put_float(value.y)
	stream.put_float(value.z)


static func _write_fixed_string(stream: StreamPeerBuffer, text: String, length: int) -> void:
	for index in range(length):
		stream.put_u8(text.unicode_at(index) if index < text.length() else 0)


func _cleanup() -> void:
	var override_dir := _install_root.path_join("override")
	for file_name in ["tar_m02aa.lyt", "room001.wok", "room001.mdl"]:
		var path := override_dir.path_join(file_name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(override_dir):
		DirAccess.remove_absolute(override_dir)
	if DirAccess.dir_exists_absolute(_install_root):
		DirAccess.remove_absolute(_install_root)
