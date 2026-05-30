@tool
extends RefCounted

const KotorGameFS := preload("../../gamefs/kotor_gamefs.gd")
const KotorEnumRegistry := preload("../workspace/kotor_enum_registry.gd")
const PREF_KEY := "kotor_tools/game_path"
const INDOOR_KITS_PREF_KEY := "kotor_tools/indoor_kits_path"
const PYKOTOR_CLI_PREF_KEY := "kotor_tools/pykotor_cli_path"
const GAME_TLK_NAME := "dialog.tlk"

signal game_path_changed(game_path: String)
signal indoor_kits_path_changed(indoor_kits_path: String)
signal pykotor_cli_path_changed(pykotor_cli_path: String)
signal gamefs_reindexed(status_text: String)

var game_path: String = ""
var indoor_kits_path: String = ""
var pykotor_cli_path: String = ""
var gamefs: RefCounted
var enum_registry: RefCounted


func load_settings() -> void:
	if gamefs == null:
		gamefs = KotorGameFS.new()
	_ensure_enum_registry()
	var editor_settings := EditorInterface.get_editor_settings()
	game_path = editor_settings.get_setting(PREF_KEY) if editor_settings.has_setting(PREF_KEY) else ""
	indoor_kits_path = (
		editor_settings.get_setting(INDOOR_KITS_PREF_KEY)
		if editor_settings.has_setting(INDOOR_KITS_PREF_KEY)
		else ""
	)
	pykotor_cli_path = (
		editor_settings.get_setting(PYKOTOR_CLI_PREF_KEY)
		if editor_settings.has_setting(PYKOTOR_CLI_PREF_KEY)
		else ""
	)
	refresh_gamefs()


func set_game_path(new_path: String) -> void:
	game_path = new_path.strip_edges()
	EditorInterface.get_editor_settings().set_setting(PREF_KEY, game_path)
	game_path_changed.emit(game_path)
	refresh_gamefs()


func set_indoor_kits_path(new_path: String) -> void:
	indoor_kits_path = new_path.strip_edges()
	EditorInterface.get_editor_settings().set_setting(INDOOR_KITS_PREF_KEY, indoor_kits_path)
	indoor_kits_path_changed.emit(indoor_kits_path)


func set_pykotor_cli_path(new_path: String) -> void:
	pykotor_cli_path = new_path.strip_edges()
	EditorInterface.get_editor_settings().set_setting(PYKOTOR_CLI_PREF_KEY, pykotor_cli_path)
	pykotor_cli_path_changed.emit(pykotor_cli_path)


func has_valid_indoor_kits_path() -> bool:
	return not indoor_kits_path.is_empty() and DirAccess.dir_exists_absolute(indoor_kits_path)


func refresh_gamefs() -> void:
	if gamefs == null:
		gamefs = KotorGameFS.new()
	_ensure_enum_registry()
	if not has_valid_game_path():
		gamefs.clear()
		gamefs_reindexed.emit(get_game_path_status())
		return
	gamefs.index_install(game_path)
	gamefs_reindexed.emit(get_game_path_status())


func has_indexed_resources() -> bool:
	return gamefs != null and gamefs.has_method("has_indexed_resources") and gamefs.call("has_indexed_resources")


func has_valid_game_path() -> bool:
	return not game_path.is_empty() and DirAccess.dir_exists_absolute(game_path)


func get_game_path_status() -> String:
	if game_path.is_empty():
		return "No game path configured"
	if not DirAccess.dir_exists_absolute(game_path):
		return "Invalid path"
	if gamefs != null:
		return gamefs.get_status_text()
	return "Ready"


func find_dialog_tlk() -> String:
	if gamefs != null and not gamefs.dialog_tlk_path.is_empty():
		return gamefs.dialog_tlk_path
	if not has_valid_game_path():
		return ""
	var candidates := [
		game_path.path_join(GAME_TLK_NAME),
		game_path.path_join("dialog").path_join(GAME_TLK_NAME),
	]
	for candidate: String in candidates:
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


func _ensure_enum_registry() -> void:
	if enum_registry == null:
		enum_registry = KotorEnumRegistry.new().configure(self)


func find_first_existing_dir(candidates: Array[String]) -> String:
	for candidate: String in candidates:
		if DirAccess.dir_exists_absolute(candidate):
			return candidate
	return game_path


func resolve_dialog_start_dir(start_dir: String = "") -> String:
	var initial_dir := start_dir
	if initial_dir.is_empty() and has_valid_game_path():
		initial_dir = game_path
	if not initial_dir.is_empty() and DirAccess.dir_exists_absolute(initial_dir):
		return initial_dir
	return ""
