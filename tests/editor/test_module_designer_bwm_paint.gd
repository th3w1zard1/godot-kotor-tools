extends SceneTree

## Headless tests for Module Designer BWM walkmesh face paint (Q126).

const BWMParser = preload("res://formats/bwm_parser.gd")
const ModuleDesignerWorkspaceEditor = preload(
	"res://ui/workspace/editors/module_designer_workspace_editor.gd"
)


func _init() -> void:
	_test_exec_walkmesh_set_face_material()
	_test_walkmesh_dirty_tracking()
	print("✓ Module Designer BWM paint tests passed")
	quit(0)


func _build_parsed_walkmesh(material_id: int) -> Dictionary:
	return {
		"vertices": [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		"faces": [
			{"i1": 0, "i2": 1, "i3": 2, "material": material_id},
		],
		"vertex_count": 3,
		"face_count": 1,
	}


func _test_exec_walkmesh_set_face_material() -> void:
	var editor := ModuleDesignerWorkspaceEditor.new()
	var parsed := _build_parsed_walkmesh(BWMParser.DEFAULT_WALKABLE_MATERIAL)
	editor._parsed_walkmesh = parsed
	editor._walkmesh_dirty = false
	editor._exec_walkmesh_set_face_material(0, BWMParser.DEFAULT_UNWALKABLE_MATERIAL)
	assert(BWMParser.get_face_material(parsed, 0) == BWMParser.DEFAULT_UNWALKABLE_MATERIAL)
	assert(editor._walkmesh_dirty)
	print("✓ walkmesh set_face_material exec passed")


func _test_walkmesh_dirty_tracking() -> void:
	var editor := ModuleDesignerWorkspaceEditor.new()
	editor._walkmesh_dirty = true
	editor._git_dirty = false
	editor._pth_dirty = false
	editor._refresh_dirty_state()
	assert(editor._dirty)
	editor._walkmesh_dirty = false
	editor._refresh_dirty_state()
	assert(not editor._dirty)
	print("✓ walkmesh dirty tracking passed")
