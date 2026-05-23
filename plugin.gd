## plugin.gd
## KotOR Tools — EditorPlugin entry point.
##
## Bootstraps importer registration and the modular KotOR editor shell.
##
## Aurora Engine file-format reference addresses (K1_GOG_swkotor):
##   CResGFF ctor          @ 0x00410630
##   CERFFile ctor         @ 0x005dd9c0
##   ExportFilesFromERF    @ 0x005dd710
##   C2DA::Load2DArray     @ 0x004143b0
##   CTlkTable             (class, no single ctor addr resolved)
@tool
extends EditorPlugin

const KotorEditorState := preload("editor/core/kotor_editor_state.gd")
const KotorImporterRegistry := preload("editor/core/kotor_importer_registry.gd")
const KotorSaverRegistry := preload("editor/core/kotor_saver_registry.gd")
const KotorWorkspaceController := preload("editor/workspace/kotor_workspace_controller.gd")
const KotorMainScreen := preload("editor/workspace/kotor_main_screen.gd")

var _editor_state: RefCounted
var _importer_registry: RefCounted
var _saver_registry: RefCounted
var _workspace_controller: RefCounted
var _main_screen: Control


func _enter_tree() -> void:
	_importer_registry = KotorImporterRegistry.new()
	if not _importer_registry.register_all(self):
		return

	_saver_registry = KotorSaverRegistry.new()
	_saver_registry.register_all()

	_editor_state = KotorEditorState.new()
	_editor_state.load_settings()

	_workspace_controller = KotorWorkspaceController.new(_editor_state)
	_main_screen = KotorMainScreen.new()
	_main_screen.setup(_workspace_controller)
	_main_screen.visible = false
	_main_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_editor_interface().get_editor_main_screen().add_child(_main_screen)


func _exit_tree() -> void:
	if _importer_registry != null:
		_importer_registry.unregister_all(self)

	if _saver_registry != null:
		_saver_registry.unregister_all()

	if _main_screen:
		var main_screen_parent := _main_screen.get_parent()
		if main_screen_parent != null:
			main_screen_parent.remove_child(_main_screen)
		_main_screen.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _main_screen != null:
		_main_screen.visible = visible


func _get_plugin_name() -> String:
	return "KotOR"


func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_editor_theme().get_icon("Node", "EditorIcons")
