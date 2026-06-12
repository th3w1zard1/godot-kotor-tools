## ui/kotor_dock.gd
## KotOR Tools bottom-panel dock.
##
## Provides:
##   • Game Path picker — point at a KotOR/TSL installation directory
##   • TAB: ERF Browser — browse any loaded ERF/RIM; double-click to preview
##   • TAB: GFF Inspector — drag any .utc/.dlg/etc. and inspect the field tree
##   • TAB: Area Tools — inspect indexed ARE/module/LYT resources and linked room models
##   • TAB: 2DA Viewer — load & browse any .2da as a spreadsheet
##   • TAB: TLK Search — load dialog.tlk and full-text search strings
@tool
extends Control

const GFFParser    := preload("../formats/gff_parser.gd")
const ERFParser    := preload("../formats/erf_parser.gd")
const TwoDaParser  := preload("../formats/twoda_parser.gd")
const TLKParser    := preload("../formats/tlk_parser.gd")
const LYTParser    := preload("../formats/lyt_parser.gd")
const TPCReader    := preload("../formats/tpc_reader.gd")
const GFFResourceFactory := preload("../resources/gff_resource_factory.gd")
const GFFResource := preload("../resources/gff_resource.gd")
const DLGResource := preload("../resources/typed/dlg_resource.gd")
const TwoDaResource := preload("../resources/twoda_resource.gd")
const TLKResource := preload("../resources/tlk_resource.gd")
const KotorDLGDocument := preload("../resources/documents/kotor_dlg_document.gd")
const KotorEditorState := preload("../editor/core/kotor_editor_state.gd")
const KotorScriptToolBridge := preload("../resources/scripts/kotor_script_tool_bridge.gd")
const KotorDiffToolBridge := preload("../resources/diff/kotor_diff_tool_bridge.gd")
const HoloPatcherToolBridge := preload("../resources/patch/holo_patcher_tool_bridge.gd")
const KotorModdingPipeline := preload("../editor/modding/kotor_modding_pipeline.gd")
const KotorMutationService := preload("../editor/transactions/kotor_mutation_service.gd")
const KotorPreflightDialog := preload("./workspace/dialogs/kotor_preflight_dialog.gd")
const KotorGFFWorkspaceEditor := preload("./workspace/editors/gff_workspace_editor.gd")
const KotorModuleDesignerWorkspaceEditor := preload("./workspace/editors/module_designer_workspace_editor.gd")
const KotorErfWorkspaceEditor := preload("./workspace/editors/erf_workspace_editor.gd")
const GAME_TLK_NAME := KotorEditorState.GAME_TLK_NAME
const GAMEFS_RESULT_LIMIT := 500
const AREA_RESULT_LIMIT := 256
const GFF_EXTENSIONS := {
	"utc": true, "utd": true, "ute": true, "uti": true, "utp": true,
	"uts": true, "utt": true, "utw": true, "utm": true, "jrl": true,
	"dlg": true, "are": true, "ifo": true, "gff": true,
}
const AREA_TOOL_EXTENSIONS := {
	"lyt": true,
	"vis": true,
}
const SCRIPT_EXTENSIONS := {
	"nss": true,
	"ncs": true,
}
const ARCHIVE_EXTENSIONS := {
	"erf": true, "rim": true, "mod": true, "sav": true,
}

var _editor_state: RefCounted
var _modding_pipeline: RefCounted
var _mutation_service: RefCounted
var _preflight_dialog: KotorPreflightDialog
var _preflight_pending_apply: Callable
var _preflight_pending_complete: Callable
var _skip_preflight_for_testing := false
var _workspace_entry_opener: Callable = Callable()
var _tabs: TabContainer
var _path_status_label: Label
var _workspace_status_label: Label
var _workspace_search_field: LineEdit
var _workspace_tree: Tree
var _workspace_detail: TextEdit
var _activity_log: TextEdit
var _last_compare_report := ""
var _kotordiff_path1 := ""
var _kotordiff_path2 := ""
var _holopatcher_tslpatchdata := ""

# GameFS tab
var _gamefs_status_label: Label
var _gamefs_search_field: LineEdit
var _gamefs_tree: Tree
var _gamefs_report: TextEdit
var _gamefs_tab: Control

# ERF tab
var _erf_path_label: Label
var _erf_status_label: Label
var _erf_tree: Tree
var _erf_data: Dictionary = {}
var _erf_preview: TextureRect
var _erf_tab: Control
var _erf_status_text := ""

# GFF tab
var _gff_path_label: Label
var _gff_summary_label: Label
var _gff_tree: Tree
var _gff_tab: Control
var _gff_resource: GFFResource

# DLG tab
var _dlg_path_label: Label
var _dlg_tree: Tree
var _dlg_details: VBoxContainer
var _dlg_validation_report: TextEdit
var _dlg_tab: Control
var _dlg_resource: DLGResource
var _dlg_document: KotorDLGDocument
var _dlg_source_path: String = ""
var _dlg_file_name := "dialogue.dlg"
var _dlg_dirty := false
var _dlg_status_text := ""
var _dlg_selection: Dictionary = {}

# Area tools tab
var _area_status_label: Label
var _area_search_field: LineEdit
var _area_tree: Tree
var _area_summary: TextEdit
var _area_related_tree: Tree
var _area_tab: Control

# 2DA tab
var _twoda_path_label: Label
var _twoda_tree: Tree
var _twoda_tab: Control
var _twoda_resource: TwoDaResource
var _twoda_source_path: String = ""
var _twoda_file_name := "table.2da"
var _twoda_dirty := false
var _twoda_status_text := ""

# TLK tab
var _tlk_path_label: Label
var _tlk_search_field: LineEdit
var _tlk_tree: Tree
var _tlk_tab: Control
var _tlk_resource: TLKResource
var _tlk_source_path: String = ""
var _tlk_file_name := GAME_TLK_NAME
var _tlk_dirty := false
var _tlk_text_edit: TextEdit
var _tlk_entry_status_label: Label
var _tlk_selected_strref := -1
var _tlk_status_text := ""

# Script tab
var _script_path_label: Label
var _script_summary_label: Label
var _script_text_edit: TextEdit
var _script_report: TextEdit
var _script_tab: Control
var _script_source_path: String = ""
var _script_file_name := "script.nss"
var _script_extension := "nss"
var _script_dirty := false
var _script_status_text := ""
var _script_bytes := PackedByteArray()
var _script_loading := false
var _script_install_btn: Button
var _script_compile_btn: Button
var _script_decompile_btn: Button
var _script_disassemble_btn: Button


func _init() -> void:
	custom_minimum_size = Vector2(0, 220)


func set_workspace_entry_opener(opener: Callable) -> void:
	_workspace_entry_opener = opener


func setup(editor_state: RefCounted, mutation_service: RefCounted = null) -> void:
	_editor_state = editor_state
	if mutation_service != null:
		_mutation_service = mutation_service
	_ensure_mutation_services()


func _ready() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_ensure_mutation_services()
	_build_ui()


# --------------------------------------------------------------------------- #
# UI Construction
# --------------------------------------------------------------------------- #

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ── Game-path row ──────────────────────────────────────────────────────
	var path_row := HBoxContainer.new()
	root.add_child(path_row)

	var path_lbl := Label.new()
	path_lbl.text = "Game Path:"
	path_row.add_child(path_lbl)

	var path_edit := LineEdit.new()
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_edit.placeholder_text = "Select KotOR / TSL install folder…"
	path_edit.text = _editor_state.game_path
	path_edit.text_submitted.connect(_on_game_path_changed)
	path_row.add_child(path_edit)

	var browse_btn := Button.new()
	browse_btn.text = "Browse…"
	browse_btn.pressed.connect(_browse_game_path.bind(path_edit))
	path_row.add_child(browse_btn)

	_path_status_label = Label.new()
	_path_status_label.clip_text = true
	path_row.add_child(_path_status_label)
	_refresh_game_path_status()

	var shell_split := VSplitContainer.new()
	shell_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(shell_split)

	var workspace_split := HSplitContainer.new()
	workspace_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_split.add_child(workspace_split)

	_build_workspace_sidebar(workspace_split)

	# ── Tabs / editor area ─────────────────────────────────────────────────
	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_split.add_child(_tabs)

	_build_gamefs_tab()
	_build_erf_tab()
	_build_gff_tab()
	_build_dlg_tab()
	_build_area_tab()
	_build_2da_tab()
	_build_tlk_tab()
	_build_script_tab()

	_activity_log = TextEdit.new()
	_activity_log.custom_minimum_size = Vector2(0, 96)
	_activity_log.editable = false
	_activity_log.placeholder_text = "Workspace activity, modding writes, and compare output appear here."
	shell_split.add_child(_activity_log)

	_refresh_gamefs_view()


func _build_workspace_sidebar(parent: Control) -> void:
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(320, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(sidebar)

	var header := Label.new()
	header.text = "Workspace Browser"
	sidebar.add_child(header)

	_workspace_status_label = Label.new()
	_workspace_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(_workspace_status_label)

	var toolbar := HBoxContainer.new()
	sidebar.add_child(toolbar)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(_refresh_gamefs_index)
	toolbar.add_child(refresh_btn)

	var open_btn := Button.new()
	open_btn.text = "Open"
	open_btn.pressed.connect(_open_selected_workspace_entry)
	toolbar.add_child(open_btn)

	var compare_btn := Button.new()
	compare_btn.text = "Compare"
	compare_btn.pressed.connect(_compare_selected_workspace_entry)
	toolbar.add_child(compare_btn)

	var compare_all_btn := Button.new()
	compare_all_btn.text = "Compare All"
	compare_all_btn.pressed.connect(_compare_all_overrides)
	toolbar.add_child(compare_all_btn)

	var export_compare_btn := Button.new()
	export_compare_btn.text = "Export Report…"
	export_compare_btn.pressed.connect(_export_compare_report_dialog)
	toolbar.add_child(export_compare_btn)

	var install_btn := Button.new()
	install_btn.text = "Install"
	install_btn.pressed.connect(_install_selected_workspace_entry)
	toolbar.add_child(install_btn)

	var export_btn := Button.new()
	export_btn.text = "Export…"
	export_btn.pressed.connect(_export_selected_workspace_entry)
	toolbar.add_child(export_btn)

	var search_row := HBoxContainer.new()
	sidebar.add_child(search_row)

	var search_lbl := Label.new()
	search_lbl.text = "Find:"
	search_row.add_child(search_lbl)

	_workspace_search_field = LineEdit.new()
	_workspace_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace_search_field.placeholder_text = "Search install resources…"
	_workspace_search_field.text_submitted.connect(_on_workspace_search)
	search_row.add_child(_workspace_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(func(): _on_workspace_search(_workspace_search_field.text))
	search_row.add_child(search_btn)

	_workspace_tree = Tree.new()
	_workspace_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace_tree.columns = 3
	_workspace_tree.hide_root = true
	_workspace_tree.set_column_title(0, "Resource")
	_workspace_tree.set_column_title(1, "Location")
	_workspace_tree.set_column_title(2, "Size")
	_workspace_tree.column_titles_visible = true
	_workspace_tree.item_selected.connect(_on_workspace_item_selected)
	_workspace_tree.item_activated.connect(_open_selected_workspace_entry)
	sidebar.add_child(_workspace_tree)

	var detail_label := Label.new()
	detail_label.text = "Selection"
	sidebar.add_child(detail_label)

	_workspace_detail = TextEdit.new()
	_workspace_detail.custom_minimum_size = Vector2(0, 140)
	_workspace_detail.editable = false
	_workspace_detail.placeholder_text = "Select an indexed install resource to inspect its source, variants, and suggested editor."
	sidebar.add_child(_workspace_detail)


func _refresh_workspace_view() -> void:
	if _workspace_status_label == null or _workspace_tree == null:
		return
	if not _has_valid_game_path() or _editor_state.gamefs == null:
		_workspace_status_label.text = "Set a valid game path to browse install-aware resources."
		_workspace_tree.clear()
		if _workspace_detail != null:
			_workspace_detail.text = ""
		return

	var query := _workspace_search_field.text if _workspace_search_field != null else ""
	var entry_count := _populate_workspace_tree(query)
	_workspace_status_label.text = "%s — %d resources in view" % [
		_editor_state.gamefs.get_status_text(),
		entry_count,
	]
	_refresh_workspace_selection()


func _populate_workspace_tree(query: String) -> int:
	if _workspace_tree == null:
		return 0
	_workspace_tree.clear()
	if _editor_state.gamefs == null:
		return 0

	var root_item := _workspace_tree.create_item()
	var entries: Array = _editor_state.gamefs.list_core_resources(query, null, "", GAMEFS_RESULT_LIMIT)
	var grouped: Dictionary = {}
	for entry: Dictionary in entries:
		var source := str(entry.get("source", "")).to_lower()
		var extension := str(entry.get("extension", "")).to_lower()
		if not grouped.has(source):
			grouped[source] = {}
		var source_group: Dictionary = grouped[source]
		if not source_group.has(extension):
			source_group[extension] = []
		(source_group[extension] as Array).append(entry)

	for source in _sorted_dictionary_keys(grouped):
		var source_group: Dictionary = grouped[source]
		var source_count := 0
		for extension_entries in source_group.values():
			source_count += (extension_entries as Array).size()
		var source_item := _workspace_tree.create_item(root_item)
		source_item.set_text(0, "%s (%d)" % [_format_source_label(source), source_count])
		source_item.collapsed = false

		for extension in _sorted_dictionary_keys(source_group):
			var extension_entries: Array = source_group[extension]
			var extension_item := _workspace_tree.create_item(source_item)
			extension_item.set_text(0, ".%s (%d)" % [extension, extension_entries.size()])
			extension_item.collapsed = extension_entries.size() > 16
			for entry: Dictionary in extension_entries:
				var item := _workspace_tree.create_item(extension_item)
				item.set_text(0, "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")])
				item.set_text(1, str(entry.get("location", "")))
				item.set_text(2, _format_size(int(entry.get("size", -1))))
				item.set_metadata(0, entry)

	if entries.size() >= GAMEFS_RESULT_LIMIT:
		var more_item := _workspace_tree.create_item(root_item)
		more_item.set_text(0, "Showing first %d matches" % GAMEFS_RESULT_LIMIT)
	return entries.size()


func _get_selected_workspace_entry() -> Dictionary:
	if _workspace_tree == null:
		return {}
	var item := _workspace_tree.get_selected()
	if item == null:
		return {}
	var metadata = item.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY:
		return {}
	return metadata


func _on_workspace_search(query: String) -> void:
	if _workspace_search_field != null:
		_workspace_search_field.text = query
	_refresh_workspace_view()


func _on_workspace_item_selected() -> void:
	_refresh_workspace_selection()


func _refresh_workspace_selection() -> void:
	if _workspace_detail == null:
		return
	var entry := _get_selected_workspace_entry()
	if entry.is_empty():
		_workspace_detail.text = ""
		return

	var extension := str(entry.get("extension", "")).to_lower()
	var variants: Array[Dictionary] = _editor_state.gamefs.list_resource_variants(
		str(entry.get("resref", "")),
		int(entry.get("resource_type", -1))
	)
	var lines: Array[String] = []
	lines.append("%s.%s" % [entry.get("resref", ""), entry.get("extension", "")])
	lines.append("Viewer: %s" % _viewer_for_extension(extension))
	lines.append("Primary source: %s" % _format_source_label(str(entry.get("source", ""))))
	lines.append("Location: %s" % str(entry.get("location", "")))
	lines.append("Size: %s" % _format_size(int(entry.get("size", -1))))
	lines.append("")
	lines.append("Variants:")
	for variant: Dictionary in variants:
		lines.append("- %s — %s" % [
			_format_source_label(str(variant.get("source", ""))),
			str(variant.get("location", "")),
		])
	_workspace_detail.text = "\n".join(lines)


func _open_selected_workspace_entry() -> void:
	_open_gamefs_entry(_get_selected_workspace_entry())


func _export_selected_workspace_entry() -> void:
	_export_gamefs_entry(_get_selected_workspace_entry())


func _install_selected_workspace_entry() -> void:
	_install_gamefs_entry(_get_selected_workspace_entry())


func _compare_selected_workspace_entry() -> void:
	_compare_gamefs_entry(_get_selected_workspace_entry())


# ── GameFS Browser ────────────────────────────────────────────────────────────

func _build_gamefs_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "GameFS"
	_tabs.add_child(vbox)
	_gamefs_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh Index"
	refresh_btn.pressed.connect(_refresh_gamefs_index)
	toolbar.add_child(refresh_btn)

	var open_btn := Button.new()
	open_btn.text = "Open Selected"
	open_btn.pressed.connect(_open_selected_gamefs_entry)
	toolbar.add_child(open_btn)

	var export_btn := Button.new()
	export_btn.text = "Export Selected…"
	export_btn.pressed.connect(_export_selected_gamefs_entry)
	toolbar.add_child(export_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_selected_gamefs_entry)
	toolbar.add_child(install_btn)

	var compare_btn := Button.new()
	compare_btn.text = "Compare Override"
	compare_btn.pressed.connect(_compare_selected_gamefs_entry)
	toolbar.add_child(compare_btn)

	var compare_all_btn := Button.new()
	compare_all_btn.text = "Compare All Overrides"
	compare_all_btn.pressed.connect(_compare_all_overrides)
	toolbar.add_child(compare_all_btn)

	var export_compare_btn := Button.new()
	export_compare_btn.text = "Export Compare Report…"
	export_compare_btn.pressed.connect(_export_compare_report_dialog)
	toolbar.add_child(export_compare_btn)

	var kotordiff_btn := Button.new()
	kotordiff_btn.text = "Run KotorDiff CLI…"
	kotordiff_btn.pressed.connect(_run_kotordiff_cli_dialog)
	toolbar.add_child(kotordiff_btn)

	var validate_patch_btn := Button.new()
	validate_patch_btn.text = "Validate TSL Patch…"
	validate_patch_btn.pressed.connect(
		func() -> void: _run_holopatcher_cli_dialog(HoloPatcherToolBridge.MODE_VALIDATE)
	)
	toolbar.add_child(validate_patch_btn)

	var install_patch_btn := Button.new()
	install_patch_btn.text = "Install TSL Patch…"
	install_patch_btn.pressed.connect(
		func() -> void: _run_holopatcher_cli_dialog(HoloPatcherToolBridge.MODE_INSTALL)
	)
	toolbar.add_child(install_patch_btn)

	_gamefs_status_label = Label.new()
	_gamefs_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gamefs_status_label.clip_text = true
	toolbar.add_child(_gamefs_status_label)

	var search_row := HBoxContainer.new()
	vbox.add_child(search_row)

	var search_lbl := Label.new()
	search_lbl.text = "Find:"
	search_row.add_child(search_lbl)

	_gamefs_search_field = LineEdit.new()
	_gamefs_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gamefs_search_field.placeholder_text = "Search by resref, type, source, or path…"
	_gamefs_search_field.text_submitted.connect(_on_gamefs_search)
	search_row.add_child(_gamefs_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(func(): _on_gamefs_search(_gamefs_search_field.text))
	search_row.add_child(search_btn)

	_gamefs_tree = Tree.new()
	_gamefs_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gamefs_tree.columns = 4
	_gamefs_tree.set_column_title(0, "ResRef")
	_gamefs_tree.set_column_title(1, "Type")
	_gamefs_tree.set_column_title(2, "Source")
	_gamefs_tree.set_column_title(3, "Location")
	_gamefs_tree.column_titles_visible = true
	_gamefs_tree.item_activated.connect(_open_selected_gamefs_entry)
	vbox.add_child(_gamefs_tree)

	_gamefs_report = TextEdit.new()
	_gamefs_report.custom_minimum_size = Vector2(0, 96)
	_gamefs_report.editable = false
	_gamefs_report.placeholder_text = "Modding actions and compare reports appear here."
	vbox.add_child(_gamefs_report)


# ── ERF Browser ─────────────────────────────────────────────────────────────

func _build_erf_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "ERF Browser"
	_tabs.add_child(vbox)
	_erf_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open ERF/RIM…"
	open_btn.pressed.connect(_open_erf)
	toolbar.add_child(open_btn)

	var open_game_btn := Button.new()
	open_game_btn.text = "Game Archive…"
	open_game_btn.pressed.connect(_open_game_erf)
	toolbar.add_child(open_game_btn)

	var extract_btn := Button.new()
	extract_btn.text = "Extract All…"
	extract_btn.pressed.connect(_extract_erf_all)
	toolbar.add_child(extract_btn)

	var export_selected_btn := Button.new()
	export_selected_btn.text = "Export Selected…"
	export_selected_btn.pressed.connect(_export_selected_erf_entry)
	toolbar.add_child(export_selected_btn)

	var install_selected_btn := Button.new()
	install_selected_btn.text = "Install Selected → Override"
	install_selected_btn.pressed.connect(_install_selected_erf_entry)
	toolbar.add_child(install_selected_btn)

	_erf_path_label = Label.new()
	_erf_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_erf_path_label.clip_text = true
	toolbar.add_child(_erf_path_label)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	_erf_tree = Tree.new()
	_erf_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_erf_tree.columns = 3
	_erf_tree.set_column_title(0, "ResRef")
	_erf_tree.set_column_title(1, "Type")
	_erf_tree.set_column_title(2, "Size")
	_erf_tree.column_titles_visible = true
	_erf_tree.item_activated.connect(_on_erf_item_activated)
	split.add_child(_erf_tree)

	_erf_preview = TextureRect.new()
	_erf_preview.custom_minimum_size = Vector2(180, 180)
	_erf_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_erf_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	split.add_child(_erf_preview)

	_erf_status_label = Label.new()
	_erf_status_label.clip_text = true
	vbox.add_child(_erf_status_label)


# ── GFF Inspector ────────────────────────────────────────────────────────────

func _build_gff_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "GFF Inspector"
	_tabs.add_child(vbox)
	_gff_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open GFF…"
	open_btn.pressed.connect(_open_gff)
	toolbar.add_child(open_btn)

	_gff_path_label = Label.new()
	_gff_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gff_path_label.clip_text = true
	toolbar.add_child(_gff_path_label)

	_gff_summary_label = Label.new()
	_gff_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gff_summary_label.visible = false
	vbox.add_child(_gff_summary_label)

	_gff_tree = Tree.new()
	_gff_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gff_tree.columns = 2
	_gff_tree.set_column_title(0, "Field")
	_gff_tree.set_column_title(1, "Value")
	_gff_tree.column_titles_visible = true
	vbox.add_child(_gff_tree)


# ── DLG Editor ────────────────────────────────────────────────────────────────

func _build_dlg_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "DLG Editor"
	_tabs.add_child(vbox)
	_dlg_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open DLG…"
	open_btn.pressed.connect(_open_dlg)
	toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save DLG"
	save_btn.pressed.connect(_save_dlg)
	toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As…"
	save_as_btn.pressed.connect(_save_dlg_as)
	toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_dlg_to_override)
	toolbar.add_child(install_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_refresh_dlg_validation)
	toolbar.add_child(validate_btn)

	_dlg_path_label = Label.new()
	_dlg_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dlg_path_label.clip_text = true
	toolbar.add_child(_dlg_path_label)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	_dlg_tree = Tree.new()
	_dlg_tree.custom_minimum_size = Vector2(280, 0)
	_dlg_tree.columns = 2
	_dlg_tree.hide_root = true
	_dlg_tree.set_column_title(0, "Dialogue")
	_dlg_tree.set_column_title(1, "Preview")
	_dlg_tree.column_titles_visible = true
	_dlg_tree.item_selected.connect(_on_dlg_item_selected)
	split.add_child(_dlg_tree)

	var detail_panel := VBoxContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_scroll)

	_dlg_details = VBoxContainer.new()
	_dlg_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_dlg_details)

	_dlg_validation_report = TextEdit.new()
	_dlg_validation_report.custom_minimum_size = Vector2(0, 140)
	_dlg_validation_report.editable = false
	_dlg_validation_report.placeholder_text = "Dialogue validation and script resolution issues appear here."
	detail_panel.add_child(_dlg_validation_report)


# ── Area Tools ────────────────────────────────────────────────────────────────

func _build_area_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "Area Tools"
	_tabs.add_child(vbox)
	_area_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(_refresh_area_view)
	toolbar.add_child(refresh_btn)

	var open_are_btn := Button.new()
	open_are_btn.text = "Open ARE"
	open_are_btn.pressed.connect(_open_selected_area_resource)
	toolbar.add_child(open_are_btn)

	var open_related_btn := Button.new()
	open_related_btn.text = "Open Related"
	open_related_btn.pressed.connect(_open_selected_area_related_resource)
	toolbar.add_child(open_related_btn)

	_area_status_label = Label.new()
	_area_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_area_status_label.clip_text = true
	toolbar.add_child(_area_status_label)

	var search_row := HBoxContainer.new()
	vbox.add_child(search_row)

	var search_lbl := Label.new()
	search_lbl.text = "Find:"
	search_row.add_child(search_lbl)

	_area_search_field = LineEdit.new()
	_area_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_area_search_field.placeholder_text = "Search ARE resources by resref, tag, or module…"
	_area_search_field.text_submitted.connect(_on_area_search)
	search_row.add_child(_area_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(func(): _on_area_search(_area_search_field.text))
	search_row.add_child(search_btn)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	_area_tree = Tree.new()
	_area_tree.custom_minimum_size = Vector2(300, 0)
	_area_tree.columns = 3
	_area_tree.hide_root = true
	_area_tree.set_column_title(0, "Area")
	_area_tree.set_column_title(1, "Tag")
	_area_tree.set_column_title(2, "Module")
	_area_tree.column_titles_visible = true
	_area_tree.item_selected.connect(_on_area_item_selected)
	_area_tree.item_activated.connect(_open_selected_area_resource)
	split.add_child(_area_tree)

	var detail_split := VSplitContainer.new()
	detail_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_split)

	_area_summary = TextEdit.new()
	_area_summary.editable = false
	_area_summary.placeholder_text = "Select an ARE resource to inspect module, area layout, and related models."
	detail_split.add_child(_area_summary)

	_area_related_tree = Tree.new()
	_area_related_tree.columns = 3
	_area_related_tree.hide_root = true
	_area_related_tree.set_column_title(0, "Resource")
	_area_related_tree.set_column_title(1, "Kind")
	_area_related_tree.set_column_title(2, "Details")
	_area_related_tree.column_titles_visible = true
	_area_related_tree.item_activated.connect(_open_selected_area_related_resource)
	detail_split.add_child(_area_related_tree)


# ── 2DA Viewer ───────────────────────────────────────────────────────────────

func _build_2da_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "2DA Viewer"
	_tabs.add_child(vbox)
	_twoda_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open 2DA…"
	open_btn.pressed.connect(_open_2da)
	toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save 2DA"
	save_btn.pressed.connect(_save_twoda)
	toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As…"
	save_as_btn.pressed.connect(_save_twoda_as)
	toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_twoda_to_override)
	toolbar.add_child(install_btn)

	_twoda_path_label = Label.new()
	_twoda_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_twoda_path_label.clip_text = true
	toolbar.add_child(_twoda_path_label)

	_twoda_tree = Tree.new()
	_twoda_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_twoda_tree.item_edited.connect(_on_twoda_item_edited)
	vbox.add_child(_twoda_tree)


# ── TLK Search ───────────────────────────────────────────────────────────────

func _build_tlk_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "TLK Search"
	_tabs.add_child(vbox)
	_tlk_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var open_btn := Button.new()
	open_btn.text = "Load dialog.tlk…"
	open_btn.pressed.connect(_open_tlk)
	toolbar.add_child(open_btn)

	var open_game_btn := Button.new()
	open_game_btn.text = "Load Game TLK"
	open_game_btn.pressed.connect(_load_game_tlk)
	toolbar.add_child(open_game_btn)

	var save_btn := Button.new()
	save_btn.text = "Save TLK"
	save_btn.pressed.connect(_save_tlk)
	toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As…"
	save_as_btn.pressed.connect(_save_tlk_as)
	toolbar.add_child(save_as_btn)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_tlk_to_override)
	toolbar.add_child(install_btn)

	_tlk_path_label = Label.new()
	_tlk_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tlk_path_label.clip_text = true
	toolbar.add_child(_tlk_path_label)

	var search_row := HBoxContainer.new()
	vbox.add_child(search_row)

	var search_lbl := Label.new()
	search_lbl.text = "Search:"
	search_row.add_child(search_lbl)

	_tlk_search_field = LineEdit.new()
	_tlk_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tlk_search_field.placeholder_text = "Enter StrRef number or text fragment…"
	_tlk_search_field.text_submitted.connect(_on_tlk_search)
	search_row.add_child(_tlk_search_field)

	var search_btn := Button.new()
	search_btn.text = "Search"
	search_btn.pressed.connect(func(): _on_tlk_search(_tlk_search_field.text))
	search_row.add_child(search_btn)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	_tlk_tree = Tree.new()
	_tlk_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tlk_tree.columns = 2
	_tlk_tree.set_column_title(0, "StrRef")
	_tlk_tree.set_column_title(1, "Text")
	_tlk_tree.column_titles_visible = true
	_tlk_tree.item_selected.connect(_on_tlk_item_selected)
	split.add_child(_tlk_tree)

	var editor_panel := VBoxContainer.new()
	editor_panel.custom_minimum_size = Vector2(220, 0)
	split.add_child(editor_panel)

	var editor_label := Label.new()
	editor_label.text = "Selected TLK Text"
	editor_panel.add_child(editor_label)

	_tlk_text_edit = TextEdit.new()
	_tlk_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_panel.add_child(_tlk_text_edit)

	var edit_toolbar := HBoxContainer.new()
	editor_panel.add_child(edit_toolbar)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_apply_tlk_text)
	edit_toolbar.add_child(apply_btn)

	_tlk_entry_status_label = Label.new()
	_tlk_entry_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tlk_entry_status_label.clip_text = true
	_tlk_entry_status_label.text = "Select a search result to edit"
	editor_panel.add_child(_tlk_entry_status_label)


# ── Script Editor ─────────────────────────────────────────────────────────────

func _build_script_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "Script Editor"
	_tabs.add_child(vbox)
	_script_tab = vbox

	var toolbar := HBoxContainer.new()
	vbox.add_child(toolbar)

	var open_btn := Button.new()
	open_btn.text = "Open NSS/NCS…"
	open_btn.pressed.connect(_open_script)
	toolbar.add_child(open_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_script)
	toolbar.add_child(save_btn)

	var save_as_btn := Button.new()
	save_as_btn.text = "Save As…"
	save_as_btn.pressed.connect(_save_script_as)
	toolbar.add_child(save_as_btn)

	_script_install_btn = Button.new()
	_script_install_btn.text = "Install to Override"
	_script_install_btn.pressed.connect(_install_script_to_override)
	toolbar.add_child(_script_install_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_validate_script)
	toolbar.add_child(validate_btn)

	_script_compile_btn = Button.new()
	_script_compile_btn.text = "Compile"
	_script_compile_btn.pressed.connect(_compile_script)
	toolbar.add_child(_script_compile_btn)

	_script_decompile_btn = Button.new()
	_script_decompile_btn.text = "Decompile"
	_script_decompile_btn.pressed.connect(_decompile_script)
	toolbar.add_child(_script_decompile_btn)

	_script_disassemble_btn = Button.new()
	_script_disassemble_btn.text = "Disassemble"
	_script_disassemble_btn.pressed.connect(_disassemble_script)
	toolbar.add_child(_script_disassemble_btn)

	var counterpart_btn := Button.new()
	counterpart_btn.text = "Open Counterpart"
	counterpart_btn.pressed.connect(_open_script_counterpart)
	toolbar.add_child(counterpart_btn)

	_script_path_label = Label.new()
	_script_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_script_path_label.clip_text = true
	toolbar.add_child(_script_path_label)

	_script_summary_label = Label.new()
	_script_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_script_summary_label)

	_script_text_edit = TextEdit.new()
	_script_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_script_text_edit.placeholder_text = "Open an NSS or NCS resource to inspect it."
	_script_text_edit.text_changed.connect(_on_script_text_changed)
	vbox.add_child(_script_text_edit)

	_script_report = TextEdit.new()
	_script_report.custom_minimum_size = Vector2(0, 132)
	_script_report.editable = false
	_script_report.placeholder_text = "Validation, include resolution, and compile status notes appear here."
	vbox.add_child(_script_report)


# --------------------------------------------------------------------------- #
# Event handlers — game path
# --------------------------------------------------------------------------- #

func _on_game_path_changed(new_path: String) -> void:
	_editor_state.set_game_path(new_path)
	_refresh_game_path_status()
	_refresh_gamefs_view()


func _browse_game_path(target_edit: LineEdit) -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_DIR,
		PackedStringArray(),
		"Select KotOR / TSL Install Folder"
	)
	dialog.title = "Select KotOR / TSL Install Folder"
	dialog.dir_selected.connect(func(dir: String) -> void:
		target_edit.text = dir
		_on_game_path_changed(dir)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _refresh_gamefs_index() -> void:
	_editor_state.refresh_gamefs()
	_refresh_game_path_status()
	_refresh_gamefs_view()
	_refresh_workspace_view()
	_refresh_area_view()


func _on_gamefs_search(query: String) -> void:
	_populate_gamefs_tree(query)


func _refresh_gamefs_view() -> void:
	if _gamefs_status_label == null or _gamefs_tree == null:
		_refresh_workspace_view()
		_refresh_area_view()
		return
	if not _has_valid_game_path() or _editor_state.gamefs == null:
		_gamefs_status_label.text = "Set a valid game path to index install resources"
		_gamefs_tree.clear()
		_refresh_workspace_view()
		_refresh_area_view()
		return
	_gamefs_status_label.text = _editor_state.gamefs.get_status_text()
	_populate_gamefs_tree(_gamefs_search_field.text if _gamefs_search_field != null else "")
	_refresh_workspace_view()
	_refresh_area_view()


func _populate_gamefs_tree(query: String) -> void:
	if _gamefs_tree == null:
		return
	_gamefs_tree.clear()
	if _editor_state.gamefs == null:
		return

	var root_item := _gamefs_tree.create_item()
	var entries: Array = _editor_state.gamefs.list_core_resources(query, null, "", GAMEFS_RESULT_LIMIT)
	for entry: Dictionary in entries:
		var item := _gamefs_tree.create_item(root_item)
		item.set_text(0, str(entry.get("resref", "")))
		item.set_text(1, str(entry.get("extension", "")))
		item.set_text(2, str(entry.get("source", "")))
		item.set_text(3, str(entry.get("location", "")))
		item.set_metadata(0, entry)
	if entries.size() >= GAMEFS_RESULT_LIMIT:
		var more_item := _gamefs_tree.create_item(root_item)
		more_item.set_text(0, "…")
		more_item.set_text(3, "Showing first %d results" % GAMEFS_RESULT_LIMIT)


func _get_selected_gamefs_entry() -> Dictionary:
	if _gamefs_tree == null:
		return {}
	var item := _gamefs_tree.get_selected()
	if item == null:
		return {}
	var metadata = item.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY:
		return {}
	return metadata


func _export_selected_gamefs_entry() -> void:
	_export_gamefs_entry(_get_selected_gamefs_entry())


func _install_selected_gamefs_entry() -> void:
	_install_gamefs_entry(_get_selected_gamefs_entry())


func _compare_selected_gamefs_entry() -> void:
	_compare_gamefs_entry(_get_selected_gamefs_entry())


func _show_gamefs_report(text: String) -> void:
	if _gamefs_report != null:
		_gamefs_report.text = text
	_append_activity(text)


func _open_selected_gamefs_entry() -> void:
	_open_gamefs_entry(_get_selected_gamefs_entry())


func _export_gamefs_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		_show_gamefs_report("Select a GameFS resource first.")
		return
	var file_name := "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(),
		"Export GameFS Resource",
		_editor_state.game_path if _has_valid_game_path() else "",
		file_name
	)
	dialog.file_selected.connect(func(path: String) -> void:
		var payload: PackedByteArray = _editor_state.gamefs.load_resource_entry_bytes(entry)
		var service := _resolve_mutation_service()
		var preview: Dictionary = service.preview_export_to_path(path, payload)
		_run_mutation_preflight(
			preview,
			func(proceed: bool) -> Dictionary:
				return service.apply_export_to_path(path, payload, proceed),
			func(result: Dictionary) -> void:
				_show_gamefs_report(_mutation_status_text(result))
		)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_gamefs_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		_show_gamefs_report("Select a GameFS resource first.")
		return
	var file_name := _gamefs_entry_file_name(entry)
	var payload: PackedByteArray = _editor_state.gamefs.load_resource_entry_bytes(entry)
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_install_to_override(_editor_state.gamefs, file_name, payload)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_install_to_override(_editor_state.gamefs, file_name, payload, proceed),
		func(result: Dictionary) -> void:
			_show_gamefs_report(_mutation_status_text(result))
			if _mutation_applied_ok(result):
				_editor_state.refresh_gamefs()
				_refresh_game_path_status()
				_refresh_gamefs_view()
	)


func _compare_gamefs_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		_show_gamefs_report("Select a GameFS resource first.")
		return
	var result: Dictionary = _modding_pipeline.compare_gamefs_resource(
		_editor_state.gamefs,
		str(entry.get("resref", "")),
		int(entry.get("resource_type", -1))
	)
	var report := _format_compare_result(result)
	_last_compare_report = report
	_show_gamefs_report(report)


func _compare_all_overrides() -> void:
	if _editor_state == null or _editor_state.gamefs == null:
		_show_gamefs_report("Configure a game install path first.")
		return
	var result: Dictionary = _modding_pipeline.compare_all_overrides(_editor_state.gamefs)
	var report := _format_batch_compare_result(result)
	_last_compare_report = report
	_show_gamefs_report(report)
	_append_activity(report)


func _export_compare_report_dialog() -> void:
	if _last_compare_report.strip_edges().is_empty():
		_show_gamefs_report("Run Compare or Compare All Overrides first.")
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.txt ; Text Report"]),
		"Export Compare Report",
		_editor_state.game_path if _has_valid_game_path() else "",
		"override-compare-report.txt"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		var target_path := _ensure_extension(path, "txt")
		var result: Dictionary = _modding_pipeline.export_text_report_to_path(
			target_path,
			_last_compare_report
		)
		_show_gamefs_report(str(result.get("message", "Export failed.")))
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _run_kotordiff_cli_dialog() -> void:
	if not _has_valid_game_path():
		_show_gamefs_report("Configure a game install path first.")
		return
	_kotordiff_path1 = _editor_state.game_path
	_kotordiff_path2 = ""
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_DIR,
		PackedStringArray(),
		"KotorDiff path2 (install, directory, or parent folder)",
		_kotordiff_path1
	)
	dialog.dir_selected.connect(func(path: String) -> void:
		_kotordiff_path2 = path
		dialog.queue_free()
		_prompt_kotordiff_output_log()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _prompt_kotordiff_output_log() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.log ; Log files"]),
		"KotorDiff output log",
		_kotordiff_path1 if not _kotordiff_path1.is_empty() else "",
		"kotordiff.log"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_execute_kotordiff_cli(_ensure_extension(path, "log"))
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _execute_kotordiff_cli(output_log: String) -> void:
	var result := KotorDiffToolBridge.run_tool({
		"path1": _kotordiff_path1,
		"path2": _kotordiff_path2,
		"output_log": output_log,
		"game_path": _kotordiff_path1,
		"pykotor_cli_path": _editor_state.pykotor_cli_path if _editor_state != null else "",
	})
	var report := str(result.get("message", "KotorDiff failed."))
	if not str(result.get("stdout", "")).strip_edges().is_empty():
		report += "\n\n" + str(result.get("stdout", "")).strip_edges()
	_show_gamefs_report(report)
	_append_activity(report)


func _run_holopatcher_cli_dialog(mode: String) -> void:
	if not _has_valid_game_path():
		_show_gamefs_report("Configure a game install path first.")
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_DIR,
		PackedStringArray(),
		"HoloPatcher tslpatchdata folder",
		_editor_state.game_path
	)
	dialog.dir_selected.connect(func(path: String) -> void:
		_holopatcher_tslpatchdata = path
		dialog.queue_free()
		_execute_holopatcher_cli(mode)
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _execute_holopatcher_cli(mode: String) -> void:
	var result := HoloPatcherToolBridge.run_tool({
		"game_dir": _editor_state.game_path,
		"tslpatchdata": _holopatcher_tslpatchdata,
		"mode": mode,
		"pykotor_cli_path": _editor_state.pykotor_cli_path if _editor_state != null else "",
	})
	var report := str(result.get("message", "HoloPatcher failed."))
	if not str(result.get("stdout", "")).strip_edges().is_empty():
		report += "\n\n" + str(result.get("stdout", "")).strip_edges()
	_show_gamefs_report(report)
	_append_activity(report)


func _open_gamefs_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		_append_activity("Select a GameFS resource first.")
		return

	var extension := str(entry.get("extension", "")).to_lower()
	if _workspace_entry_opener.is_valid() and _should_delegate_to_workspace_editor(extension):
		_workspace_entry_opener.call(entry)
		return

	if _editor_state.gamefs == null:
		return

	var bytes: PackedByteArray = _editor_state.gamefs.load_resource_entry_bytes(entry)
	if bytes.is_empty():
		var missing_message := "Could not load %s.%s" % [entry.get("resref", ""), entry.get("extension", "")]
		push_warning("KotOR Tools: %s" % missing_message)
		_append_activity(missing_message)
		return

	var resref := str(entry.get("resref", ""))
	var label := "%s.%s [%s]" % [resref, extension, entry.get("source", "")]

	if extension == "dlg":
		_load_dlg_bytes(label, bytes)
		_tabs.current_tab = _dlg_tab.get_index()
	elif SCRIPT_EXTENSIONS.has(extension):
		_load_script_bytes(label, bytes, extension)
		_tabs.current_tab = _script_tab.get_index()
	elif KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed(extension):
		_append_activity("Open %s in the Module Designer workspace tab" % label)
	elif GFF_EXTENSIONS.has(extension):
		_load_gff_bytes(label, bytes)
		_tabs.current_tab = _gff_tab.get_index()
	elif AREA_TOOL_EXTENSIONS.has(extension):
		_inspect_area_support_entry(entry, bytes)
		_tabs.current_tab = _area_tab.get_index()
	elif extension == "2da":
		_load_2da_bytes(label, bytes)
		_tabs.current_tab = _twoda_tab.get_index()
	elif extension == "tlk":
		_load_tlk_bytes(label, bytes)
		_tabs.current_tab = _tlk_tab.get_index()
	elif ARCHIVE_EXTENSIONS.has(extension):
		_load_erf_bytes(label, bytes)
		_tabs.current_tab = _erf_tab.get_index()
	elif extension == "tpc":
		_erf_preview.texture = TPCReader.read_bytes(bytes)
		_erf_path_label.text = label
		_erf_tree.clear()
		_tabs.current_tab = _erf_tab.get_index()
		_append_activity("Opened %s in archive preview" % label)
	else:
		push_warning("KotOR Tools: no viewer is available for .%s resources yet" % extension)
		_append_activity("No viewer is available for %s" % label)
		return

	_append_activity("Opened %s in %s" % [label, _viewer_for_extension(extension)])


func open_gamefs_entry(entry: Dictionary) -> void:
	_open_gamefs_entry(entry)


# --------------------------------------------------------------------------- #
# Event handlers — Area tools
# --------------------------------------------------------------------------- #

func _refresh_area_view() -> void:
	if _area_status_label == null or _area_tree == null:
		return
	if not _has_valid_game_path() or _editor_state.gamefs == null:
		_area_status_label.text = "Set a valid game path to browse indexed area resources."
		_area_tree.clear()
		if _area_summary != null:
			_area_summary.text = ""
		if _area_related_tree != null:
			_area_related_tree.clear()
		return

	var area_count := _populate_area_tree(_area_search_field.text if _area_search_field != null else "")
	_area_status_label.text = "%d ARE resources indexed across %s" % [
		area_count,
		_editor_state.gamefs.get_status_text(),
	]
	_refresh_area_selection()


func _populate_area_tree(query: String) -> int:
	if _area_tree == null or _editor_state.gamefs == null:
		return 0
	_area_tree.clear()
	var root_item := _area_tree.create_item()
	var normalized_query := query.strip_edges().to_lower()
	var area_entries: Array = _editor_state.gamefs.list_core_resources("", "are", "", 0)
	var shown := 0

	for entry: Dictionary in area_entries:
		var descriptor := _describe_area_entry(entry)
		var haystack := "%s %s %s %s %s" % [
			entry.get("resref", ""),
			descriptor.get("display_name", ""),
			descriptor.get("tag", ""),
			descriptor.get("module", ""),
			entry.get("location", ""),
		]
		if not normalized_query.is_empty() and not haystack.to_lower().contains(normalized_query):
			continue

		var item := _area_tree.create_item(root_item)
		item.set_text(0, str(descriptor.get("display_name", "%s.are" % entry.get("resref", ""))))
		item.set_text(1, str(descriptor.get("tag", "")))
		item.set_text(2, str(descriptor.get("module", "")))
		item.set_metadata(0, entry)
		shown += 1
		if shown >= AREA_RESULT_LIMIT:
			break

	if shown >= AREA_RESULT_LIMIT:
		var more_item := _area_tree.create_item(root_item)
		more_item.set_text(0, "Showing first %d area matches" % AREA_RESULT_LIMIT)
	return area_entries.size()


func _on_area_search(query: String) -> void:
	if _area_search_field != null:
		_area_search_field.text = query
	_refresh_area_view()


func _on_area_item_selected() -> void:
	_refresh_area_selection()


func _get_selected_area_entry() -> Dictionary:
	if _area_tree == null:
		return {}
	var item := _area_tree.get_selected()
	if item == null:
		return {}
	var metadata = item.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY:
		return {}
	return metadata


func _get_selected_area_related_entry() -> Dictionary:
	if _area_related_tree == null:
		return {}
	var item := _area_related_tree.get_selected()
	if item == null:
		return {}
	var metadata = item.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY:
		return {}
	return metadata


func _open_selected_area_resource() -> void:
	_open_gamefs_entry(_get_selected_area_entry())


func _open_selected_area_related_resource() -> void:
	var entry := _get_selected_area_related_entry()
	if entry.is_empty():
		_append_activity("Select a related area resource first.")
		return
	_open_gamefs_entry(entry)


func _refresh_area_selection() -> void:
	if _area_summary == null or _area_related_tree == null:
		return
	var entry := _get_selected_area_entry()
	_area_related_tree.clear()
	if entry.is_empty():
		_area_summary.text = ""
		return

	var summary_lines: Array[String] = []
	var descriptor := _describe_area_entry(entry)
	var resref := str(entry.get("resref", ""))
	summary_lines.append("%s.are" % resref)
	summary_lines.append("Display: %s" % str(descriptor.get("display_name", resref)))
	if not str(descriptor.get("tag", "")).is_empty():
		summary_lines.append("Tag: %s" % descriptor.get("tag", ""))
	summary_lines.append("Source: %s" % _format_source_label(str(entry.get("source", ""))))
	summary_lines.append("Location: %s" % str(entry.get("location", "")))
	if entry.has("container_name"):
		summary_lines.append("Module archive: %s" % str(entry.get("container_name", "")))

	var area_resource := _parse_gff_resource_entry(entry)
	if area_resource != null:
		var area_summary := area_resource.build_summary_text()
		if not area_summary.is_empty():
			summary_lines.append("")
			summary_lines.append("Area")
			summary_lines.append(area_summary)

	var container_entries: Array = _editor_state.gamefs.list_container_resources(str(entry.get("container_path", "")))
	var related_root := _area_related_tree.create_item()
	var resource_group := _area_related_tree.create_item(related_root)
	resource_group.set_text(0, "Module Resources")
	resource_group.collapsed = false
	_add_area_related_item(resource_group, entry, "Area", "Selected ARE")

	var git_entry := _find_related_entry(container_entries, resref, "git", true)
	if not git_entry.is_empty():
		var git_resource := _parse_gff_resource_entry(git_entry)
		if git_resource != null:
			summary_lines.append("")
			summary_lines.append("Placed Objects")
			summary_lines.append(git_resource.build_summary_text())
		_add_area_related_item(resource_group, git_entry, "Layout", "Area object placements")

	var ifo_entry := _find_related_entry(container_entries, "", "ifo", false)
	if not ifo_entry.is_empty():
		var ifo_resource := _parse_gff_resource_entry(ifo_entry)
		if ifo_resource != null:
			summary_lines.append("")
			summary_lines.append("Module")
			summary_lines.append(ifo_resource.build_summary_text())
		_add_area_related_item(resource_group, ifo_entry, "Module", "Module info")

	var lyt_entry := _find_related_entry(container_entries, resref, "lyt", true)
	var layout: Dictionary = {}
	if not lyt_entry.is_empty():
		layout = _parse_layout_entry(lyt_entry)
		if not layout.is_empty():
			summary_lines.append("")
			summary_lines.append("Layout")
			summary_lines.append("Rooms: %d" % (layout.get("rooms", []) as Array).size())
			summary_lines.append("Tracks: %d" % (layout.get("tracks", []) as Array).size())
			summary_lines.append("Obstacles: %d" % (layout.get("obstacles", []) as Array).size())
			summary_lines.append("Doorhooks: %d" % (layout.get("doorhooks", []) as Array).size())
		_add_area_related_item(resource_group, lyt_entry, "Layout", "LYT room layout")

	var vis_entry := _find_related_entry(container_entries, resref, "vis", true)
	if not vis_entry.is_empty():
		_add_area_related_item(resource_group, vis_entry, "Visibility", "VIS portal visibility")

	var path_entry := _find_related_entry(container_entries, resref, "pth", true)
	if not path_entry.is_empty():
		_add_area_related_item(resource_group, path_entry, "Pathing", "PTH path graph")

	var set_entry := _find_related_entry(container_entries, resref, "set", true)
	if not set_entry.is_empty():
		_add_area_related_item(resource_group, set_entry, "Tileset", "SET tileset definition")

	var rooms: Array = layout.get("rooms", [])
	if not rooms.is_empty():
		summary_lines.append("")
		summary_lines.append("Room Models")
		var model_group := _area_related_tree.create_item(related_root)
		model_group.set_text(0, "Room Models")
		model_group.collapsed = false
		var unique_models: Dictionary = {}
		for room in rooms:
			var model_name := str((room as Dictionary).get("model", "")).to_lower()
			if model_name.is_empty() or unique_models.has(model_name):
				continue
			unique_models[model_name] = room
		for model_name in _sorted_dictionary_keys(unique_models):
			var room: Dictionary = unique_models[model_name]
			var mdl_entry := _find_related_entry(container_entries, model_name, "mdl", true)
			var mdx_entry := _find_related_entry(container_entries, model_name, "mdx", true)
			var wok_entry := _find_related_entry(container_entries, model_name, "wok", true)
			var position: Vector3 = room.get("position", Vector3.ZERO)
			var presence: Array[String] = []
			presence.append("MDL ✓" if not mdl_entry.is_empty() else "MDL missing")
			presence.append("MDX ✓" if not mdx_entry.is_empty() else "MDX missing")
			presence.append("WOK ✓" if not wok_entry.is_empty() else "WOK missing")
			summary_lines.append("- %s — %s" % [model_name, ", ".join(presence)])

			var item := _area_related_tree.create_item(model_group)
			item.set_text(0, model_name)
			item.set_text(1, "Room Model")
			item.set_text(2, "%s @ (%.2f, %.2f, %.2f)" % [
				", ".join(presence),
				position.x,
				position.y,
				position.z,
			])
			item.set_metadata(0, mdl_entry if not mdl_entry.is_empty() else {})

	_area_summary.text = "\n".join(summary_lines)


func _inspect_area_support_entry(entry: Dictionary, bytes: PackedByteArray) -> void:
	if _area_summary == null or _area_related_tree == null:
		return
	var extension := str(entry.get("extension", "")).to_lower()
	var lines: Array[String] = [
		"%s.%s" % [entry.get("resref", ""), entry.get("extension", "")],
		"Source: %s" % _format_source_label(str(entry.get("source", ""))),
		"Location: %s" % str(entry.get("location", "")),
	]
	_area_related_tree.clear()
	var root := _area_related_tree.create_item()
	var resource_group := _area_related_tree.create_item(root)
	resource_group.set_text(0, "Related Resources")
	resource_group.collapsed = false
	_add_area_related_item(resource_group, entry, extension.to_upper(), "Selected resource")

	var container_entries: Array = _editor_state.gamefs.list_container_resources(str(entry.get("container_path", "")))
	var are_entry := _find_related_entry(container_entries, str(entry.get("resref", "")), "are", true)
	if not are_entry.is_empty():
		_add_area_related_item(resource_group, are_entry, "Area", "Matching ARE")
	var git_entry := _find_related_entry(container_entries, str(entry.get("resref", "")), "git", true)
	if not git_entry.is_empty():
		_add_area_related_item(resource_group, git_entry, "Layout", "Matching GIT")

	if extension == "lyt":
		var layout := LYTParser.parse_bytes(bytes)
		lines.append("")
		lines.append("Layout")
		lines.append("Rooms: %d" % (layout.get("rooms", []) as Array).size())
		lines.append("Tracks: %d" % (layout.get("tracks", []) as Array).size())
		lines.append("Obstacles: %d" % (layout.get("obstacles", []) as Array).size())
		lines.append("Doorhooks: %d" % (layout.get("doorhooks", []) as Array).size())
		var model_group := _area_related_tree.create_item(root)
		model_group.set_text(0, "Room Models")
		model_group.collapsed = false
		for room in layout.get("rooms", []):
			var model_name := str((room as Dictionary).get("model", ""))
			if model_name.is_empty():
				continue
			var mdl_entry := _find_related_entry(container_entries, model_name, "mdl", true)
			var mdx_entry := _find_related_entry(container_entries, model_name, "mdx", true)
			var item := _area_related_tree.create_item(model_group)
			item.set_text(0, model_name)
			item.set_text(1, "Room Model")
			item.set_text(2, "%s, %s" % [
				"MDL ✓" if not mdl_entry.is_empty() else "MDL missing",
				"MDX ✓" if not mdx_entry.is_empty() else "MDX missing",
			])
			item.set_metadata(0, mdl_entry if not mdl_entry.is_empty() else {})
	else:
		lines.append("")
		lines.append("This resource is indexed for area/module discovery. Use the Area Tools list to inspect the matching ARE and linked room models.")

	_area_summary.text = "\n".join(lines)


func _describe_area_entry(entry: Dictionary) -> Dictionary:
	var display_name := "%s.are" % entry.get("resref", "")
	var tag := ""
	var resource := _parse_gff_resource_entry(entry)
	if resource != null:
		display_name = resource.get_display_name()
		tag = resource.create_document().get_string("Tag")
	if display_name.is_empty():
		display_name = "%s.are" % entry.get("resref", "")
	return {
		"display_name": display_name,
		"tag": tag,
		"module": _area_module_label(entry),
	}


func _area_module_label(entry: Dictionary) -> String:
	if entry.has("container_name"):
		return str(entry.get("container_name", ""))
	return _format_source_label(str(entry.get("source", "")))


func _parse_gff_resource_entry(entry: Dictionary) -> GFFResource:
	if entry.is_empty() or _editor_state.gamefs == null:
		return null
	var bytes: PackedByteArray = _editor_state.gamefs.load_resource_entry_bytes(entry)
	if bytes.is_empty():
		return null
	var parsed: Dictionary = GFFParser.parse_bytes(bytes)
	if parsed.is_empty():
		return null
	return GFFResourceFactory.create_from_parser_result(parsed)


func _parse_layout_entry(entry: Dictionary) -> Dictionary:
	if entry.is_empty() or _editor_state.gamefs == null:
		return {}
	var bytes: PackedByteArray = _editor_state.gamefs.load_resource_entry_bytes(entry)
	if bytes.is_empty():
		return {}
	return LYTParser.parse_bytes(bytes)


func _find_related_entry(
		container_entries: Array,
		resref: String,
		extension: String,
		allow_global_fallback: bool
) -> Dictionary:
	var normalized_resref := resref.to_lower()
	var normalized_extension := extension.to_lower()
	for raw_entry in container_entries:
		var entry: Dictionary = raw_entry
		if str(entry.get("extension", "")).to_lower() != normalized_extension:
			continue
		if normalized_resref.is_empty() or str(entry.get("resref", "")).to_lower() == normalized_resref:
			return entry
	if allow_global_fallback and not normalized_resref.is_empty() and _editor_state.gamefs != null:
		return _editor_state.gamefs.resolve_resource(resref, extension)
	return {}


func _add_area_related_item(parent: TreeItem, entry: Dictionary, kind: String, details: String) -> void:
	if parent == null or entry.is_empty():
		return
	var item := _area_related_tree.create_item(parent)
	item.set_text(0, "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")])
	item.set_text(1, kind)
	item.set_text(2, details)
	item.set_metadata(0, entry)


# --------------------------------------------------------------------------- #
# Event handlers — ERF tab
# --------------------------------------------------------------------------- #

func _open_erf() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.erf,*.rim,*.mod,*.sav ; KotOR ERF/RIM"]),
		"Open KotOR ERF/RIM"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_erf(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _open_game_erf() -> void:
	if not _has_valid_game_path():
		push_warning("KotOR Tools: configure a valid game path before opening game archives")
		_refresh_game_path_status("Set a valid game path first")
		return
	var archive_dir := _find_first_existing_dir([
		_editor_state.game_path.path_join("modules"),
		_editor_state.game_path.path_join("lips"),
		_editor_state.game_path.path_join("rims"),
		_editor_state.game_path,
	])
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.erf,*.rim,*.mod,*.sav ; KotOR ERF/RIM"]),
		"Open Game Archive",
		archive_dir
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_erf(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_erf(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data := f.get_buffer(f.get_length())
	f.close()
	_load_erf_bytes(path.get_file(), data)

func _load_erf_bytes(label: String, data: PackedByteArray) -> void:
	_erf_data = ERFParser.parse_bytes(data)
	_erf_path_label.text = label
	_erf_preview.texture = null
	_erf_status_text = ""
	_refresh_erf_status()
	_append_activity("Loaded archive %s" % label)

	_erf_tree.clear()
	var root_item := _erf_tree.create_item()
	for e: ERFParser.ERFEntry in _erf_data.get("entries", []):
		var item := _erf_tree.create_item(root_item)
		item.set_text(0, e.resref)
		item.set_text(1, e.extension)
		item.set_text(2, "%d B" % e.size)
		item.set_metadata(0, e)


func _extract_erf_all() -> void:
	if _erf_data.is_empty():
		return
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.title = "Extract To…"
	dialog.dir_selected.connect(func(dir: String) -> void:
		ERFParser.extract_all(_erf_data, dir)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _on_erf_item_activated() -> void:
	var item := _erf_tree.get_selected()
	if item == null:
		return
	var e: ERFParser.ERFEntry = item.get_metadata(0)
	if e == null:
		return
	# Preview TPC textures inline
	if e.extension == "tpc":
		var tex := TPCReader.read_bytes(e.read_data())
		_erf_preview.texture = tex
	else:
		_erf_preview.texture = null


func _get_selected_erf_entry() -> ERFParser.ERFEntry:
	if _erf_tree == null:
		return null
	var item := _erf_tree.get_selected()
	if item == null:
		return null
	return item.get_metadata(0)


func _export_selected_erf_entry() -> void:
	var entry := _get_selected_erf_entry()
	if entry == null:
		_erf_status_text = "Select an archive entry first."
		_refresh_erf_status()
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(),
		"Export Archive Entry",
		_editor_state.game_path if _has_valid_game_path() else "",
		"%s.%s" % [entry.resref, entry.extension]
	)
	dialog.file_selected.connect(func(path: String) -> void:
		var payload := entry.read_data()
		var service := _resolve_mutation_service()
		var preview: Dictionary = service.preview_export_to_path(path, payload)
		_run_mutation_preflight(
			preview,
			func(proceed: bool) -> Dictionary:
				return service.apply_export_to_path(path, payload, proceed),
			func(result: Dictionary) -> void:
				_erf_status_text = _mutation_status_text(result)
				_refresh_erf_status()
				_append_activity(_erf_status_text)
		)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _install_selected_erf_entry() -> void:
	var entry := _get_selected_erf_entry()
	if entry == null:
		_erf_status_text = "Select an archive entry first."
		_refresh_erf_status()
		return
	var file_name := "%s.%s" % [entry.resref, entry.extension]
	var payload := entry.read_data()
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_install_to_override(_editor_state.gamefs, file_name, payload)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_install_to_override(_editor_state.gamefs, file_name, payload, proceed),
		func(result: Dictionary) -> void:
			_erf_status_text = _mutation_status_text(result)
			_refresh_erf_status()
			_append_activity(_erf_status_text)
			if _mutation_applied_ok(result):
				_editor_state.refresh_gamefs()
				_refresh_game_path_status()
				_refresh_gamefs_view()
	)


# --------------------------------------------------------------------------- #
# Event handlers — GFF tab
# --------------------------------------------------------------------------- #

func _open_gff() -> void:
	var gff_exts := "*.utc,*.utd,*.ute,*.uti,*.utp,*.uts,*.utt,*.utw,*.utm,"
	gff_exts += "*.jrl,*.dlg,*.are,*.ifo,*.gff ; KotOR GFF"
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray([gff_exts]),
		"Open KotOR GFF"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_gff(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_gff(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data := f.get_buffer(f.get_length())
	f.close()
	_load_gff_bytes(path.get_file(), data)


func _load_gff_bytes(label: String, data: PackedByteArray) -> void:
	var parsed: Dictionary = GFFParser.parse_bytes(data)
	if parsed.is_empty():
		_gff_resource = null
		_gff_path_label.text = "Failed to load %s" % label
		if _gff_summary_label != null:
			_gff_summary_label.text = ""
			_gff_summary_label.visible = false
		_gff_tree.clear()
		_append_activity("Failed to load GFF %s" % label)
		return

	_gff_resource = GFFResourceFactory.create_from_parser_result(parsed)
	var display_name := _gff_resource.get_display_name()
	_gff_path_label.text = "[%s] %s" % [_gff_resource.file_type if not _gff_resource.file_type.is_empty() else "?", label]
	if not display_name.is_empty() and display_name != _gff_resource.get_type_label():
		_gff_path_label.text = "[%s] %s — %s" % [
			_gff_resource.file_type if not _gff_resource.file_type.is_empty() else "?",
			display_name,
			label,
		]
	if _gff_summary_label != null:
		_gff_summary_label.text = _gff_resource.build_summary_text()
		_gff_summary_label.visible = not _gff_summary_label.text.is_empty()
	_gff_tree.clear()
	var root_item := _gff_tree.create_item()
	root_item.set_text(0, _gff_resource.file_type if not _gff_resource.file_type.is_empty() else "?")
	root_item.set_text(1, _gff_resource.get_type_label())
	_populate_gff_tree(root_item, _gff_resource.gff_data)
	_append_activity("Loaded GFF %s" % label)


func _populate_gff_tree(parent: TreeItem, data: Dictionary) -> void:
	for key: String in data:
		var val = data[key]
		var item := _gff_tree.create_item(parent)
		item.set_text(0, key)
		match typeof(val):
			TYPE_DICTIONARY:
				item.set_text(1, "<struct>")
				item.collapsed = true
				_populate_gff_tree(item, val)
			TYPE_ARRAY:
				item.set_text(1, "<list[%d]>" % (val as Array).size())
				item.collapsed = true
				for i in (val as Array).size():
					var li := _gff_tree.create_item(item)
					li.set_text(0, "[%d]" % i)
					li.set_text(1, "<struct>")
					li.collapsed = true
					_populate_gff_tree(li, val[i])
			_:
				item.set_text(1, str(val))


# --------------------------------------------------------------------------- #
# Event handlers — DLG tab
# --------------------------------------------------------------------------- #

func _open_dlg() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.dlg ; KotOR Dialogue"]),
		"Open KotOR Dialogue"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_dlg(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_dlg(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	_load_dlg_bytes(path, bytes)


func _load_dlg_bytes(label: String, data: PackedByteArray) -> void:
	var parsed: Dictionary = GFFParser.parse_bytes(data)
	if parsed.is_empty() or str(parsed.get("file_type", "")).to_upper() != "DLG":
		_dlg_resource = null
		_dlg_document = null
		_dlg_path_label.text = "Failed to load %s" % label
		_clear_container(_dlg_details)
		if _dlg_validation_report != null:
			_dlg_validation_report.text = ""
		if _dlg_tree != null:
			_dlg_tree.clear()
		_append_activity("Failed to load DLG %s" % label)
		return

	var resource = GFFResourceFactory.create_from_parser_result(parsed)
	if not resource is DLGResource:
		_dlg_path_label.text = "Unsupported DLG payload in %s" % label
		return

	_dlg_resource = resource as DLGResource
	_dlg_document = _dlg_resource.create_document() as KotorDLGDocument
	_dlg_source_path = label if label.is_absolute_path() else ""
	_dlg_file_name = _guess_loaded_file_name(label, "dialogue.dlg")
	_dlg_dirty = false
	_dlg_status_text = ""
	_dlg_selection = {"kind": "root"}
	_refresh_dlg_tree()
	_refresh_dlg_detail()
	_refresh_dlg_validation()
	_refresh_dlg_status()
	_append_activity("Loaded dialogue %s" % _dlg_file_name)


func _refresh_dlg_tree() -> void:
	if _dlg_tree == null:
		return
	_dlg_tree.clear()
	if _dlg_document == null:
		_refresh_dlg_status()
		return

	var root_item := _dlg_tree.create_item()
	var overview_item := _dlg_tree.create_item(root_item)
	overview_item.set_text(0, "Dialogue")
	overview_item.set_text(1, _dlg_document.get_display_name())
	overview_item.set_metadata(0, {"kind": "root"})
	overview_item.collapsed = false

	var starts_item := _dlg_tree.create_item(root_item)
	starts_item.set_text(0, "Starting Nodes")
	starts_item.set_text(1, str(_dlg_document.get_start_count()))
	starts_item.collapsed = false
	for start_index in range(_dlg_document.get_start_count()):
		var item := _dlg_tree.create_item(starts_item)
		item.set_text(0, "Start %d" % start_index)
		item.set_text(1, _dlg_target_label("start", start_index, -1))
		item.set_metadata(0, {"kind": "start", "index": start_index})

	var entries_item := _dlg_tree.create_item(root_item)
	entries_item.set_text(0, "Entries")
	entries_item.set_text(1, str(_dlg_document.get_entry_count()))
	entries_item.collapsed = false
	for entry_index in range(_dlg_document.get_entry_count()):
		var node_item := _dlg_tree.create_item(entries_item)
		node_item.set_text(0, _dlg_document.build_node_title("entry", entry_index))
		node_item.set_text(1, _dlg_node_preview("entry", entry_index))
		node_item.set_metadata(0, {"kind": "entry", "index": entry_index})
		for link_index in range(_dlg_document.get_node_links("entry", entry_index).size()):
			var link_item := _dlg_tree.create_item(node_item)
			link_item.set_text(0, _dlg_target_label("entry", entry_index, link_index))
			link_item.set_text(1, _dlg_document.build_link_preview("entry", entry_index, link_index))
			link_item.set_metadata(0, {"kind": "link", "owner": "entry", "index": entry_index, "link_index": link_index})

	var replies_item := _dlg_tree.create_item(root_item)
	replies_item.set_text(0, "Replies")
	replies_item.set_text(1, str(_dlg_document.get_reply_count()))
	replies_item.collapsed = false
	for reply_index in range(_dlg_document.get_reply_count()):
		var node_item := _dlg_tree.create_item(replies_item)
		node_item.set_text(0, _dlg_document.build_node_title("reply", reply_index))
		node_item.set_text(1, _dlg_node_preview("reply", reply_index))
		node_item.set_metadata(0, {"kind": "reply", "index": reply_index})
		for link_index in range(_dlg_document.get_node_links("reply", reply_index).size()):
			var link_item := _dlg_tree.create_item(node_item)
			link_item.set_text(0, _dlg_target_label("reply", reply_index, link_index))
			link_item.set_text(1, _dlg_document.build_link_preview("reply", reply_index, link_index))
			link_item.set_metadata(0, {"kind": "link", "owner": "reply", "index": reply_index, "link_index": link_index})

	_select_first_dlg_item(root_item)
	_refresh_dlg_status()


func _on_dlg_item_selected() -> void:
	if _dlg_tree == null:
		return
	var item := _dlg_tree.get_selected()
	if item == null:
		_dlg_selection = {}
	else:
		var metadata = item.get_metadata(0)
		_dlg_selection = metadata if typeof(metadata) == TYPE_DICTIONARY else {}
	_refresh_dlg_detail()


func _refresh_dlg_detail() -> void:
	if _dlg_details == null:
		return
	_clear_container(_dlg_details)
	if _dlg_document == null or _dlg_selection.is_empty():
		return

	match str(_dlg_selection.get("kind", "")):
		"root":
			_add_dlg_section_title("Dialogue Header")
			var summary := Label.new()
			summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary.text = _dlg_document.build_summary_text()
			_dlg_details.add_child(summary)
			var root := _dlg_document.get_root()
			_build_dlg_struct_editor(root, ["Tag", "Quest", "NumWords", "WordCount"])
		"entry", "reply":
			var kind := str(_dlg_selection.get("kind", "entry"))
			var index := int(_dlg_selection.get("index", -1))
			var node := _dlg_document.get_node(kind, index)
			_add_dlg_section_title("%s — %s" % [
				_dlg_document.build_node_title(kind, index),
				_dlg_node_preview(kind, index),
			])
			_build_dlg_struct_editor(node, [
				"Text", "Speaker", "Listener", "Comment", "AnimList",
				"Script", "Delay", "Quest", "PlotIndex", "Sound", "VO_ResRef",
			])
			_add_dlg_link_summary(kind, index)
		"start":
			var index := int(_dlg_selection.get("index", -1))
			var start := _dlg_document.get_start(index)
			_add_dlg_section_title("Start %d" % index)
			var target_label := Label.new()
			target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			target_label.text = "Target: %s" % _dlg_target_label("start", index, -1)
			_dlg_details.add_child(target_label)
			_build_dlg_struct_editor(start, ["Index", "Active"])
		"link":
			var owner := str(_dlg_selection.get("owner", "entry"))
			var index := int(_dlg_selection.get("index", -1))
			var link_index := int(_dlg_selection.get("link_index", -1))
			var link := _dlg_document.get_link(owner, index, link_index)
			_add_dlg_section_title("%s" % _dlg_target_label(owner, index, link_index))
			_build_dlg_struct_editor(link, ["Index", "Active", "IsChild", "LinkComment", "Comment"])


func _add_dlg_link_summary(kind: String, index: int) -> void:
	var links := _dlg_document.get_node_links(kind, index)
	if links.is_empty():
		return
	var label := Label.new()
	label.text = "Outgoing Links"
	_dlg_details.add_child(label)
	for link_index in range(links.size()):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s — %s" % [
			_dlg_target_label(kind, index, link_index),
			_dlg_document.build_link_preview(kind, index, link_index),
		]
		button.pressed.connect(func() -> void:
			_select_dlg_metadata({
				"kind": "link",
				"owner": kind,
				"index": index,
				"link_index": link_index,
			})
		)
		_dlg_details.add_child(button)


func _build_dlg_struct_editor(struct_value: Dictionary, preferred_fields: Array[String]) -> void:
	if struct_value.is_empty():
		return
	var shown := {}
	for field_name in preferred_fields:
		if not struct_value.has(field_name):
			continue
		_add_dlg_field_editor(struct_value, field_name)
		shown[field_name] = true

	var remaining: Array[String] = []
	for key in struct_value.keys():
		var field_name := str(key)
		if shown.has(field_name):
			continue
		if not _dlg_field_is_editable(struct_value.get(field_name, null)):
			continue
		remaining.append(field_name)
	remaining.sort()
	for field_name in remaining:
		_add_dlg_field_editor(struct_value, field_name)


func _add_dlg_field_editor(struct_value: Dictionary, field_name: String) -> void:
	var value = struct_value.get(field_name, null)
	match typeof(value):
		TYPE_DICTIONARY:
			if _dlg_is_locstring(value):
				_add_dlg_locstring_editor(struct_value, field_name, value)
		TYPE_BOOL:
			_add_dlg_bool_editor(struct_value, field_name, bool(value))
		TYPE_INT:
			_add_dlg_number_editor(struct_value, field_name, int(value), true)
		TYPE_FLOAT:
			_add_dlg_number_editor(struct_value, field_name, float(value), false)
		TYPE_STRING:
			_add_dlg_string_editor(struct_value, field_name, String(value))


func _add_dlg_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_details.add_child(label)


func _add_dlg_string_editor(struct_value: Dictionary, field_name: String, value: String) -> void:
	var container := VBoxContainer.new()
	_dlg_details.add_child(container)

	var header := HBoxContainer.new()
	container.add_child(header)

	var label := Label.new()
	label.text = field_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	if _dlg_document.is_script_field(field_name):
		var open_btn := Button.new()
		open_btn.text = "Open Script"
		open_btn.pressed.connect(func() -> void:
			_open_script_ref(value)
		)
		header.add_child(open_btn)

	var multiline := field_name in ["Comment", "LinkComment"] or value.contains("\n") or value.length() > 72
	if multiline:
		var edit := TextEdit.new()
		edit.custom_minimum_size = Vector2(0, 84)
		edit.text = value
		edit.focus_exited.connect(func() -> void:
			if _dlg_document.set_struct_field(struct_value, field_name, edit.text):
				_on_dlg_document_changed()
		)
		container.add_child(edit)
	else:
		var edit := LineEdit.new()
		edit.text = value
		edit.text_submitted.connect(func(new_text: String) -> void:
			if _dlg_document.set_struct_field(struct_value, field_name, new_text):
				_on_dlg_document_changed()
		)
		edit.focus_exited.connect(func() -> void:
			if _dlg_document.set_struct_field(struct_value, field_name, edit.text):
				_on_dlg_document_changed()
		)
		container.add_child(edit)


func _add_dlg_locstring_editor(struct_value: Dictionary, field_name: String, value: Dictionary) -> void:
	var container := VBoxContainer.new()
	_dlg_details.add_child(container)

	var label := Label.new()
	label.text = field_name
	container.add_child(label)

	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 110)
	edit.text = _dlg_locstring_text(value)
	edit.placeholder_text = _dlg_resolved_locstring_text(value)
	edit.focus_exited.connect(func() -> void:
		if _dlg_document.set_struct_locstring_text(struct_value, field_name, edit.text):
			_on_dlg_document_changed()
	)
	container.add_child(edit)

	var strref := int(value.get("strref", 0xFFFFFFFF))
	if strref >= 0 and strref != 0xFFFFFFFF:
		var info := Label.new()
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.text = "StrRef %d → %s" % [strref, _dlg_resolved_locstring_text(value)]
		container.add_child(info)


func _add_dlg_bool_editor(struct_value: Dictionary, field_name: String, value: bool) -> void:
	var check := CheckBox.new()
	check.text = field_name
	check.button_pressed = value
	check.toggled.connect(func(pressed: bool) -> void:
		if _dlg_document.set_struct_field(struct_value, field_name, pressed):
			_on_dlg_document_changed()
	)
	_dlg_details.add_child(check)


func _add_dlg_number_editor(struct_value: Dictionary, field_name: String, value: float, integer: bool) -> void:
	var row := HBoxContainer.new()
	_dlg_details.add_child(row)

	var label := Label.new()
	label.text = field_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var spin := SpinBox.new()
	spin.min_value = -2147483648.0
	spin.max_value = 2147483647.0
	spin.step = 1.0 if integer else 0.1
	spin.value = value
	spin.rounded = integer
	spin.value_changed.connect(func(new_value: float) -> void:
		var normalized = int(new_value) if integer else new_value
		if _dlg_document.set_struct_field(struct_value, field_name, normalized):
			_on_dlg_document_changed()
	)
	row.add_child(spin)


func _on_dlg_document_changed() -> void:
	_dlg_dirty = true
	_dlg_status_text = "Edited"
	_refresh_dlg_selected_item_text()
	_refresh_dlg_detail()
	_refresh_dlg_validation()
	_refresh_dlg_status()


func _refresh_dlg_selected_item_text() -> void:
	if _dlg_tree == null:
		return
	var item := _dlg_tree.get_selected()
	if item == null:
		return
	match str(_dlg_selection.get("kind", "")):
		"root":
			item.set_text(1, _dlg_document.get_display_name())
		"start":
			item.set_text(1, _dlg_target_label("start", int(_dlg_selection.get("index", -1)), -1))
		"entry", "reply":
			var kind := str(_dlg_selection.get("kind", "entry"))
			var index := int(_dlg_selection.get("index", -1))
			item.set_text(1, _dlg_node_preview(kind, index))
		"link":
			var owner := str(_dlg_selection.get("owner", "entry"))
			var index := int(_dlg_selection.get("index", -1))
			var link_index := int(_dlg_selection.get("link_index", -1))
			item.set_text(0, _dlg_target_label(owner, index, link_index))
			item.set_text(1, _dlg_document.build_link_preview(owner, index, link_index))


func _refresh_dlg_validation() -> void:
	if _dlg_validation_report == null:
		return
	if _dlg_document == null:
		_dlg_validation_report.text = ""
		return
	var issues := _dlg_document.validate(_editor_state.gamefs if _editor_state != null else null)
	if issues.is_empty():
		_dlg_validation_report.text = "Dialogue validation passed.\n- Start list indices resolve.\n- Link targets resolve.\n- Referenced scripts found where possible."
	else:
		_dlg_validation_report.text = "Dialogue validation issues:\n- %s" % "\n- ".join(issues)


func _refresh_dlg_status() -> void:
	if _dlg_path_label == null:
		return
	if _dlg_document == null:
		_dlg_path_label.text = ""
		return
	_dlg_path_label.text = "%s%s  [%d starts / %d entries / %d replies]" % [
		_current_dlg_file_name(),
		" *" if _dlg_dirty else "",
		_dlg_document.get_start_count(),
		_dlg_document.get_entry_count(),
		_dlg_document.get_reply_count(),
	]
	if not _dlg_status_text.is_empty():
		_dlg_path_label.text += " — %s" % _dlg_status_text


func _save_dlg() -> void:
	if _dlg_resource == null:
		return
	if _dlg_source_path.is_empty():
		_save_dlg_as()
		return
	_save_dlg_to(_dlg_source_path)


func _save_dlg_as() -> void:
	if _dlg_resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.dlg ; KotOR Dialogue"]),
		"Save KotOR Dialogue",
		_dlg_source_path.get_base_dir() if not _dlg_source_path.is_empty() else "",
		_current_dlg_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_save_dlg_to(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_dlg_to(path: String) -> void:
	var target_path := _ensure_extension(path, "dlg")
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_export_to_path(target_path, _dlg_resource)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_export_to_path(target_path, _dlg_resource, proceed),
		func(result: Dictionary) -> void:
			_dlg_status_text = _mutation_status_text(result)
			if not _mutation_applied_ok(result):
				push_error("KotOR Tools: failed to save DLG to %s" % target_path)
				_refresh_dlg_status()
				return
			_dlg_source_path = target_path
			_dlg_file_name = target_path.get_file()
			_dlg_dirty = false
			_refresh_dlg_status()
			_append_activity(_dlg_status_text)
	)


func _install_dlg_to_override() -> void:
	if _dlg_resource == null:
		return
	var file_name := _current_dlg_file_name()
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_install_to_override(_editor_state.gamefs, file_name, _dlg_resource)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_install_to_override(_editor_state.gamefs, file_name, _dlg_resource, proceed),
		func(result: Dictionary) -> void:
			_dlg_status_text = _mutation_status_text(result)
			if _mutation_applied_ok(result):
				_dlg_dirty = false
				_editor_state.refresh_gamefs()
				_refresh_game_path_status()
				_refresh_gamefs_view()
			_refresh_dlg_status()
			_append_activity(_dlg_status_text)
	)


# --------------------------------------------------------------------------- #
# Event handlers — 2DA tab
# --------------------------------------------------------------------------- #

func _open_2da() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.2da ; KotOR 2DA Table"]),
		"Open KotOR 2DA"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_2da(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_2da(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data := f.get_buffer(f.get_length())
	f.close()
	_load_2da_bytes(path, data)


func _load_2da_bytes(label: String, data: PackedByteArray) -> void:
	var parsed := TwoDaParser.parse_bytes(data)
	if parsed.is_empty():
		_twoda_path_label.text = "Failed to load %s" % label
		_append_activity("Failed to load 2DA %s" % label)
		return

	_twoda_resource = TwoDaResource.new()
	_twoda_resource.apply_parser_result(parsed)
	_twoda_source_path = label if label.is_absolute_path() else ""
	_twoda_file_name = _guess_loaded_file_name(label, "table.2da")
	_twoda_dirty = false
	_twoda_status_text = ""
	_refresh_twoda_view()
	_append_activity("Loaded 2DA %s" % _twoda_file_name)


func _refresh_twoda_view() -> void:
	if _twoda_tree == null:
		return
	_twoda_tree.clear()
	if _twoda_resource == null:
		_refresh_twoda_status()
		return

	_twoda_tree.columns = _twoda_resource.columns.size() + 1
	_twoda_tree.set_column_title(0, "#")
	for ci in _twoda_resource.columns.size():
		_twoda_tree.set_column_title(ci + 1, _twoda_resource.columns[ci])
	_twoda_tree.column_titles_visible = true

	var root_item := _twoda_tree.create_item()
	for ri in _twoda_resource.rows.size():
		var item := _twoda_tree.create_item(root_item)
		item.set_text(0, str(ri))
		item.set_metadata(0, ri)
		for ci in _twoda_resource.columns.size():
			var value = _twoda_resource.rows[ri].get(_twoda_resource.columns[ci], null)
			item.set_text(ci + 1, str(value) if value != null else "")
			item.set_editable(ci + 1, true)

	_refresh_twoda_status()


func _on_twoda_item_edited() -> void:
	if _twoda_resource == null:
		return
	var item := _twoda_tree.get_edited()
	if item == null:
		return
	var column := _twoda_tree.get_edited_column()
	if column <= 0 or column - 1 >= _twoda_resource.columns.size():
		return

	var row_index := int(item.get_metadata(0))
	var column_name := _twoda_resource.columns[column - 1]
	var new_value := item.get_text(column)
	if _twoda_resource.set_cell(row_index, column_name, null if new_value.is_empty() else new_value):
		_twoda_dirty = true
		_refresh_twoda_status()


func _save_twoda() -> void:
	if _twoda_resource == null:
		return
	if _twoda_source_path.is_empty():
		_save_twoda_as()
		return
	_save_twoda_to(_twoda_source_path)


func _save_twoda_as() -> void:
	if _twoda_resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.2da ; KotOR 2DA Table"]),
		"Save KotOR 2DA",
		_twoda_source_path.get_base_dir() if not _twoda_source_path.is_empty() else "",
		_ensure_extension(_twoda_file_name, "2da")
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_save_twoda_to(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_twoda_to(path: String) -> void:
	var target_path := _ensure_extension(path, "2da")
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_export_to_path(target_path, _twoda_resource)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_export_to_path(target_path, _twoda_resource, proceed),
		func(result: Dictionary) -> void:
			_twoda_status_text = _mutation_status_text(result)
			if not _mutation_applied_ok(result):
				push_error("KotOR Tools: failed to save 2DA to %s" % target_path)
				_twoda_path_label.text = "Failed to save %s" % target_path.get_file()
				return
			_twoda_source_path = target_path
			_twoda_file_name = target_path.get_file()
			_twoda_dirty = false
			_refresh_twoda_status()
			_append_activity(_twoda_status_text)
	)


func _install_twoda_to_override() -> void:
	if _twoda_resource == null:
		return
	var file_name := _current_twoda_file_name()
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_install_to_override(_editor_state.gamefs, file_name, _twoda_resource)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_install_to_override(_editor_state.gamefs, file_name, _twoda_resource, proceed),
		func(result: Dictionary) -> void:
			_twoda_status_text = _mutation_status_text(result)
			if _mutation_applied_ok(result):
				_twoda_dirty = false
				_editor_state.refresh_gamefs()
				_refresh_game_path_status()
				_refresh_gamefs_view()
			_refresh_twoda_status()
			_append_activity(_twoda_status_text)
	)


# --------------------------------------------------------------------------- #
# Event handlers — TLK tab
# --------------------------------------------------------------------------- #

func _open_tlk() -> void:
	var tlk_path := _find_dialog_tlk()
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.tlk ; KotOR TLK Talk Table"]),
		"Open KotOR TLK",
		tlk_path.get_base_dir() if not tlk_path.is_empty() else ""
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_tlk(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_game_tlk() -> void:
	var tlk_path := _find_dialog_tlk()
	if tlk_path.is_empty():
		push_warning("KotOR Tools: dialog.tlk was not found under the configured game path")
		_refresh_game_path_status("dialog.tlk not found")
		return
	_load_tlk(tlk_path)
	_refresh_game_path_status("Loaded %s" % GAME_TLK_NAME)


func _load_tlk(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data := f.get_buffer(f.get_length())
	f.close()
	_load_tlk_bytes(path, data)


func _load_tlk_bytes(label: String, data: PackedByteArray) -> void:
	var parsed := TLKParser.parse_bytes(data)
	if parsed.is_empty():
		_tlk_path_label.text = "Failed to load %s" % label
		_append_activity("Failed to load TLK %s" % label)
		return

	_tlk_resource = TLKResource.new()
	_tlk_resource.apply_parser_result(parsed)
	_tlk_source_path = label if label.is_absolute_path() else ""
	_tlk_file_name = _guess_loaded_file_name(label, GAME_TLK_NAME)
	_tlk_dirty = false
	_tlk_status_text = ""
	_tlk_selected_strref = -1
	_tlk_tree.clear()
	_tlk_text_edit.text = ""
	_tlk_entry_status_label.text = "Search for a StrRef or text fragment"
	_refresh_tlk_status()
	_append_activity("Loaded TLK %s" % _tlk_file_name)


func _on_tlk_search(query: String) -> void:
	if _tlk_resource == null:
		return
	query = query.strip_edges()
	if query.is_empty():
		return

	_tlk_tree.clear()
	var root_item := _tlk_tree.create_item()

	var entries: Array[Dictionary] = _tlk_resource.entries

	# Numeric lookup — exact StrRef
	if query.is_valid_int():
		var idx := query.to_int()
		if idx >= 0 and idx < entries.size():
			var entry: Dictionary = entries[idx]
			var item := _tlk_tree.create_item(root_item)
			item.set_text(0, str(entry.get("strref", idx)))
			item.set_text(1, String(entry.get("text", "")))
			item.set_metadata(0, idx)
		return

	# Text fragment search (case-insensitive, limit 200 results)
	var lower_q := query.to_lower()
	var shown   := 0
	for entry: Dictionary in entries:
		var text := String(entry.get("text", ""))
		if text.to_lower().contains(lower_q):
			var item := _tlk_tree.create_item(root_item)
			item.set_text(0, str(entry.get("strref", shown)))
			item.set_text(1, text)
			item.set_metadata(0, int(entry.get("strref", shown)))
			shown += 1
			if shown >= 200:
				var more := _tlk_tree.create_item(root_item)
				more.set_text(0, "…")
				more.set_text(1, "(more results — refine search)")
				break


func _on_tlk_item_selected() -> void:
	if _tlk_resource == null:
		return
	var item := _tlk_tree.get_selected()
	if item == null:
		return
	var strref := int(item.get_metadata(0))
	var entry := _tlk_resource.get_entry(strref)
	if entry.is_empty():
		return

	_tlk_selected_strref = strref
	_tlk_text_edit.text = String(entry.get("text", ""))
	_tlk_entry_status_label.text = "Editing StrRef %d" % strref


func _apply_tlk_text() -> void:
	if _tlk_resource == null or _tlk_selected_strref < 0:
		return
	if not _tlk_resource.set_entry_text(_tlk_selected_strref, _tlk_text_edit.text):
		return

	var item := _tlk_tree.get_selected()
	if item != null and int(item.get_metadata(0)) == _tlk_selected_strref:
		item.set_text(1, _tlk_text_edit.text)
	_tlk_dirty = true
	_refresh_tlk_status()
	_tlk_entry_status_label.text = "Updated StrRef %d" % _tlk_selected_strref


func _save_tlk() -> void:
	if _tlk_resource == null:
		return
	if _tlk_source_path.is_empty():
		_save_tlk_as()
		return
	_save_tlk_to(_tlk_source_path)


func _save_tlk_as() -> void:
	if _tlk_resource == null:
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.tlk ; KotOR TLK Talk Table"]),
		"Save KotOR TLK",
		_tlk_source_path.get_base_dir() if not _tlk_source_path.is_empty() else "",
		_ensure_extension(_tlk_file_name, "tlk")
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_save_tlk_to(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_tlk_to(path: String) -> void:
	var target_path := _ensure_extension(path, "tlk")
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_export_to_path(target_path, _tlk_resource)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_export_to_path(target_path, _tlk_resource, proceed),
		func(result: Dictionary) -> void:
			_tlk_status_text = _mutation_status_text(result)
			if not _mutation_applied_ok(result):
				push_error("KotOR Tools: failed to save TLK to %s" % target_path)
				_tlk_path_label.text = "Failed to save %s" % target_path.get_file()
				return
			_tlk_source_path = target_path
			_tlk_file_name = target_path.get_file()
			_tlk_dirty = false
			_refresh_tlk_status()
			_tlk_entry_status_label.text = "Saved %s" % target_path.get_file()
			_append_activity(_tlk_status_text)
	)


func _install_tlk_to_override() -> void:
	if _tlk_resource == null:
		return
	var file_name := _current_tlk_file_name()
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_install_to_override(_editor_state.gamefs, file_name, _tlk_resource)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_install_to_override(_editor_state.gamefs, file_name, _tlk_resource, proceed),
		func(result: Dictionary) -> void:
			_tlk_status_text = _mutation_status_text(result)
			if _mutation_applied_ok(result):
				_tlk_dirty = false
				_editor_state.refresh_gamefs()
				_refresh_game_path_status()
				_refresh_gamefs_view()
				_tlk_entry_status_label.text = "Installed %s to override" % _current_tlk_file_name()
			_refresh_tlk_status()
			_append_activity(_tlk_status_text)
	)


func _open_script() -> void:
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_OPEN_FILE,
		PackedStringArray(["*.nss,*.ncs ; KotOR Scripts"]),
		"Open KotOR Script"
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_load_script(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _load_script(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	_load_script_bytes(path, bytes)


func _load_script_bytes(label: String, bytes: PackedByteArray, extension_hint: String = "") -> void:
	_script_extension = extension_hint.to_lower() if not extension_hint.is_empty() else label.get_extension().to_lower()
	if not SCRIPT_EXTENSIONS.has(_script_extension):
		_script_extension = "nss"
	_script_source_path = label if label.is_absolute_path() else ""
	_script_file_name = _guess_loaded_file_name(label, "script.%s" % _script_extension)
	_script_dirty = false
	_script_status_text = ""
	_script_bytes = bytes
	_script_loading = true

	if _script_extension == "nss":
		_script_text_edit.text = bytes.get_string_from_utf8()
		_script_text_edit.editable = true
	else:
		_script_text_edit.text = _build_hex_preview(bytes)
		_script_text_edit.editable = false
	_script_loading = false

	_refresh_script_summary()
	_validate_script()
	_refresh_script_tool_buttons()
	_append_activity("Loaded script %s" % _script_file_name)


func _on_script_text_changed() -> void:
	if _script_loading or _script_extension != "nss" or _script_file_name.is_empty():
		return
	_script_dirty = true
	_script_status_text = "Edited"
	_refresh_script_summary()


func _save_script() -> void:
	if _script_extension != "nss":
		return
	if _script_source_path.is_empty():
		_save_script_as()
		return
	_save_script_to(_script_source_path)


func _save_script_as() -> void:
	if _script_extension != "nss":
		return
	var dialog := _make_dialog(
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		PackedStringArray(["*.nss ; KotOR Script Source"]),
		"Save KotOR Script",
		_script_source_path.get_base_dir() if not _script_source_path.is_empty() else "",
		_current_script_file_name()
	)
	dialog.file_selected.connect(func(path: String) -> void:
		_save_script_to(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _save_script_to(path: String) -> void:
	var target_path := _ensure_extension(path, "nss")
	var payload := _script_text_edit.text
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_export_to_path(target_path, payload)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_export_to_path(target_path, payload, proceed),
		func(result: Dictionary) -> void:
			_script_status_text = _mutation_status_text(result)
			if _mutation_applied_ok(result):
				_script_source_path = target_path
				_script_file_name = target_path.get_file()
				_script_dirty = false
			_refresh_script_summary()
			_validate_script()
			_append_activity(_script_status_text)
	)


func _install_script_to_override() -> void:
	var file_name := ""
	var payload: Variant = null
	if _script_extension == "nss":
		file_name = _current_script_file_name()
		payload = _script_text_edit.text
	elif _script_extension == "ncs":
		if _script_bytes.is_empty():
			_script_status_text = "No compiled NCS bytes are loaded."
			_refresh_script_summary()
			_validate_script()
			return
		file_name = _current_ncs_override_file_name()
		payload = _script_bytes
	else:
		return
	var service := _resolve_mutation_service()
	var preview: Dictionary = service.preview_install_to_override(_editor_state.gamefs, file_name, payload)
	_run_mutation_preflight(
		preview,
		func(proceed: bool) -> Dictionary:
			return service.apply_install_to_override(_editor_state.gamefs, file_name, payload, proceed),
		func(result: Dictionary) -> void:
			_script_status_text = _mutation_status_text(result)
			if _mutation_applied_ok(result):
				if _script_extension == "nss":
					_script_dirty = false
				_editor_state.refresh_gamefs()
				_refresh_game_path_status()
				_refresh_gamefs_view()
			_refresh_script_summary()
			_validate_script()
			_append_activity(_script_status_text)
	)


func _open_script_counterpart() -> void:
	var companion := _find_script_counterpart()
	if companion.is_empty():
		_script_status_text = "No matching %s resource was found." % ("nss" if _script_extension == "ncs" else "ncs")
		_refresh_script_summary()
		return
	if companion.has("entry"):
		_open_gamefs_entry(companion.get("entry", {}))
	elif companion.has("path"):
		_load_script(str(companion.get("path", "")))


func _compile_script() -> void:
	if _script_extension != "nss" or _script_file_name.is_empty():
		return
	var input := _prepare_script_nss_input_path()
	if not input.get("ok", false):
		_write_script_tool_report(false, str(input.get("message", "Failed to prepare NSS input.")), [])
		return

	var resref := _current_script_file_name().get_basename()
	var output_path := _script_tool_output_path(resref, "ncs")
	var result := KotorScriptToolBridge.run_tool(
		_script_tool_run_config(
			KotorScriptToolBridge.Operation.ASSEMBLE,
			{
				"input_path": str(input.get("path", "")),
				"output_path": output_path,
			}
		)
	)
	_cleanup_temp_script_path(input)
	_handle_script_tool_result(
		result,
		"Compile",
		func() -> void:
			var file := FileAccess.open(output_path, FileAccess.READ)
			if file == null:
				_write_script_tool_report(false, "Compiled NCS could not be read.", result.get("warnings", []))
				return
			var bytes := file.get_buffer(file.get_length())
			file.close()
			_load_script_bytes(output_path, bytes, "ncs")
			_script_file_name = _ensure_extension(resref, "ncs")
			_script_status_text = "Compiled to %s" % _script_file_name
			_refresh_script_summary()
			_refresh_script_tool_buttons()
			_append_activity("Compiled %s to %s" % [resref, _script_file_name])
			_install_script_to_override()
	)


func _decompile_script() -> void:
	if _script_extension != "ncs" or _script_file_name.is_empty():
		return
	var input := _prepare_script_ncs_input_path()
	if not input.get("ok", false):
		_write_script_tool_report(false, str(input.get("message", "Failed to prepare NCS input.")), [])
		return

	var resref := _current_script_file_name().get_basename()
	var output_path := _script_tool_output_path(resref, "nss")
	var result := KotorScriptToolBridge.run_tool(
		_script_tool_run_config(
			KotorScriptToolBridge.Operation.DECOMPILE,
			{
				"input_path": str(input.get("path", "")),
				"output_path": output_path,
			}
		)
	)
	_cleanup_temp_script_path(input)
	_handle_script_tool_result(
		result,
		"Decompile",
		func() -> void:
			var file := FileAccess.open(output_path, FileAccess.READ)
			if file == null:
				_write_script_tool_report(false, "Decompiled NSS could not be read.", result.get("warnings", []))
				return
			var bytes := file.get_buffer(file.get_length())
			file.close()
			_load_script_bytes(output_path, bytes, "nss")
			_script_status_text = "Decompiled to %s" % output_path.get_file()
			_refresh_script_summary()
			_validate_script()
			_append_activity("Decompiled %s to %s" % [_current_script_file_name(), output_path.get_file()])
	)


func _disassemble_script() -> void:
	if _script_extension != "ncs" or _script_file_name.is_empty():
		return
	var input := _prepare_script_ncs_input_path()
	if not input.get("ok", false):
		_write_script_tool_report(false, str(input.get("message", "Failed to prepare NCS input.")), [])
		return

	var resref := _current_script_file_name().get_basename()
	var output_path := _script_tool_output_path(resref, "txt")
	var result := KotorScriptToolBridge.run_tool(
		_script_tool_run_config(
			KotorScriptToolBridge.Operation.DISASSEMBLE,
			{
				"input_path": str(input.get("path", "")),
				"output_path": output_path,
				"compact": true,
			}
		)
	)
	_cleanup_temp_script_path(input)
	_handle_script_tool_result(
		result,
		"Disassemble",
		func() -> void:
			var file := FileAccess.open(output_path, FileAccess.READ)
			if file == null:
				_write_script_tool_report(false, "Disassembly output could not be read.", result.get("warnings", []))
				return
			var text := file.get_as_text()
			file.close()
			_script_status_text = "Disassembled %s" % _current_script_file_name()
			_write_script_tool_report(true, text, result.get("warnings", []))
			_refresh_script_summary()
			_append_activity("Disassembled %s" % _current_script_file_name())
	)


func _script_tool_config_base(operation: int) -> Dictionary:
	return {
		"operation": operation,
		"game_path": _editor_state.game_path if _editor_state != null else "",
		"pykotor_cli_path": _editor_state.pykotor_cli_path if _editor_state != null else "",
	}


func _script_tool_run_config(operation: int, extra: Dictionary) -> Dictionary:
	var config := _script_tool_config_base(operation)
	for key in extra.keys():
		config[key] = extra[key]
	return config


func _script_tool_output_path(resref: String, extension: String) -> String:
	var cache_dir := OS.get_cache_dir().path_join("kotor_tools_script_tools")
	DirAccess.make_dir_recursive_absolute(cache_dir)
	return cache_dir.path_join("%s_%d.%s" % [resref, Time.get_ticks_usec(), extension])


func _prepare_script_ncs_input_path() -> Dictionary:
	if (
		not _script_source_path.is_empty()
		and FileAccess.file_exists(_script_source_path)
	):
		return {"ok": true, "path": _script_source_path, "temporary": false}
	if _script_bytes.is_empty():
		return {"ok": false, "message": "No NCS bytecode is loaded."}
	var temp := KotorScriptToolBridge.write_temp_ncs(
		_script_bytes,
		_current_script_file_name().get_basename()
	)
	if not temp.get("ok", false):
		return temp
	return {"ok": true, "path": str(temp.get("path", "")), "temporary": true}


func _prepare_script_nss_input_path() -> Dictionary:
	if (
		not _script_dirty
		and not _script_source_path.is_empty()
		and FileAccess.file_exists(_script_source_path)
	):
		return {"ok": true, "path": _script_source_path, "temporary": false}
	var temp := KotorScriptToolBridge.write_temp_nss(
		_script_text_edit.text,
		_current_script_file_name().get_basename()
	)
	if not temp.get("ok", false):
		return temp
	return {"ok": true, "path": str(temp.get("path", "")), "temporary": true}


func _cleanup_temp_script_path(input: Dictionary) -> void:
	if not bool(input.get("temporary", false)):
		return
	var path := str(input.get("path", "")).strip_edges()
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(path)


func _handle_script_tool_result(result: Dictionary, label: String, on_success: Callable) -> void:
	if not result.get("ok", false):
		_script_status_text = "%s failed" % label
		_write_script_tool_report(
			false,
			str(result.get("message", "%s failed." % label)),
			result.get("warnings", [])
		)
		_refresh_script_summary()
		_append_activity("%s failed for %s" % [label, _current_script_file_name()])
		return
	on_success.call()
	var warnings: Array = result.get("warnings", [])
	if warnings.is_empty():
		return
	var warning_lines: Array[String] = []
	for warning in warnings:
		warning_lines.append(str(warning))
	var existing := _script_report.text if _script_report != null else ""
	if not existing.is_empty():
		_script_report.text = existing + "\n\nWarnings:\n- " + "\n- ".join(warning_lines)


func _write_script_tool_report(success: bool, body: String, warnings: Variant) -> void:
	if _script_report == null:
		return
	var lines: Array[String] = []
	if not body.is_empty():
		lines.append(body)
	if typeof(warnings) == TYPE_ARRAY:
		var warning_lines: Array[String] = []
		for warning in warnings as Array:
			warning_lines.append(str(warning))
		if not warning_lines.is_empty():
			lines.append("Warnings:\n- %s" % "\n- ".join(warning_lines))
	_script_report.text = "\n".join(lines)


func _refresh_script_tool_buttons() -> void:
	var has_script := not _script_file_name.is_empty()
	if _script_install_btn != null:
		var can_install_nss := has_script and _script_extension == "nss"
		var can_install_ncs := has_script and _script_extension == "ncs" and not _script_bytes.is_empty()
		_script_install_btn.disabled = not (can_install_nss or can_install_ncs)
		_script_install_btn.text = "Install NCS to Override" if _script_extension == "ncs" else "Install NSS to Override"
	if _script_compile_btn != null:
		_script_compile_btn.disabled = not has_script or _script_extension != "nss"
	if _script_decompile_btn != null:
		_script_decompile_btn.disabled = not has_script or _script_extension != "ncs"
	if _script_disassemble_btn != null:
		_script_disassemble_btn.disabled = not has_script or _script_extension != "ncs"


func _validate_script() -> void:
	if _script_report == null:
		return
	if _script_extension == "ncs":
		var lines: Array[String] = [
			"Compiled NWScript binary loaded.",
			"Matching source: %s" % _script_counterpart_label(),
			"Use Install NCS to Override to write bytecode to the game install.",
			"Use Decompile to recover NSS source or Disassemble for bytecode listing.",
		]
		_script_report.text = "\n".join(lines)
		_refresh_script_tool_buttons()
		return

	var issues: Array[String] = []
	var text := _script_text_edit.text
	if text.strip_edges().is_empty():
		issues.append("Script source is empty.")
	if _current_script_file_name().get_basename().length() > 16:
		issues.append("File basename exceeds the 16-character resref limit.")
	if not text.contains("void main") and not text.contains("StartingConditional"):
		issues.append("No standard entry point detected (void main / StartingConditional).")

	var balance := _compute_delimiter_balance(text)
	for key in balance.keys():
		var delta := int(balance.get(key, 0))
		if delta != 0:
			issues.append("Unbalanced %s delimiters (%d)." % [key, delta])

	for include_name in _extract_script_includes(text):
		if not _script_include_exists(include_name):
			issues.append("Missing #include \"%s\" in the workspace or active install." % include_name)

	if issues.is_empty():
		_script_report.text = "Source validation passed.\nMatching compiled script: %s" % _script_counterpart_label()
	else:
		_script_report.text = "Source validation issues:\n- %s" % "\n- ".join(issues)
	_refresh_script_tool_buttons()


func _refresh_game_path_status(override_text: String = "") -> void:
	if _path_status_label == null:
		return
	if not override_text.is_empty():
		_path_status_label.text = override_text
		return
	_path_status_label.text = _editor_state.get_game_path_status()


func _has_valid_game_path() -> bool:
	return _editor_state.has_valid_game_path()


func _find_dialog_tlk() -> String:
	return _editor_state.find_dialog_tlk()


func _find_first_existing_dir(candidates: Array[String]) -> String:
	return _editor_state.find_first_existing_dir(candidates)


func _refresh_erf_status() -> void:
	if _erf_status_label == null:
		return
	_erf_status_label.text = _erf_status_text


func _refresh_twoda_status() -> void:
	if _twoda_path_label == null:
		return
	if _twoda_resource == null:
		_twoda_path_label.text = ""
		return
	var file_name := _twoda_file_name
	_twoda_path_label.text = "%s%s  [%d rows]" % [
		file_name,
		" *" if _twoda_dirty else "",
		_twoda_resource.row_count(),
	]
	if not _twoda_status_text.is_empty():
		_twoda_path_label.text += " — %s" % _twoda_status_text


func _refresh_tlk_status() -> void:
	if _tlk_path_label == null:
		return
	if _tlk_resource == null:
		_tlk_path_label.text = ""
		return
	var file_name := _tlk_file_name
	_tlk_path_label.text = "%s%s  [%d strings]" % [
		file_name,
		" *" if _tlk_dirty else "",
		_tlk_resource.entries.size(),
	]
	if not _tlk_status_text.is_empty():
		_tlk_path_label.text += " — %s" % _tlk_status_text


func _current_twoda_file_name() -> String:
	return _ensure_extension(_twoda_file_name, "2da")


func _current_tlk_file_name() -> String:
	return _ensure_extension(_tlk_file_name, "tlk")


func _current_dlg_file_name() -> String:
	return _ensure_extension(_dlg_file_name, "dlg")


func _current_script_file_name() -> String:
	return _ensure_extension(_script_file_name, _script_extension if not _script_extension.is_empty() else "nss")


func _current_ncs_override_file_name() -> String:
	return _ensure_extension(_current_script_file_name().get_basename(), "ncs")


func _refresh_script_summary() -> void:
	if _script_path_label == null:
		return
	if _script_file_name.is_empty():
		_script_path_label.text = ""
		_script_summary_label.text = ""
		return
	_script_path_label.text = "%s%s" % [_current_script_file_name(), " *" if _script_dirty else ""]
	if not _script_status_text.is_empty():
		_script_path_label.text += " — %s" % _script_status_text
	var size := _script_bytes.size()
	if _script_extension == "nss":
		_script_summary_label.text = "NWScript source • %s • counterpart: %s" % [
			_format_size(size),
			_script_counterpart_label(),
		]
	else:
		_script_summary_label.text = "Compiled NWScript binary • %s • counterpart: %s" % [
			_format_size(size),
			_script_counterpart_label(),
		]
	_refresh_script_tool_buttons()


func _script_counterpart_label() -> String:
	var counterpart := _find_script_counterpart()
	if counterpart.is_empty():
		return "not found"
	if counterpart.has("entry"):
		var entry: Dictionary = counterpart.get("entry", {})
		return "%s.%s [%s]" % [
			entry.get("resref", ""),
			entry.get("extension", ""),
			entry.get("source", ""),
		]
	return str(counterpart.get("path", "")).get_file()


func _find_script_counterpart() -> Dictionary:
	var counterpart_extension := "nss" if _script_extension == "ncs" else "ncs"
	var resref := _current_script_file_name().get_basename().get_file()
	if _editor_state != null and _editor_state.gamefs != null and not resref.is_empty():
		var entry: Dictionary = _editor_state.gamefs.resolve_resource(resref, counterpart_extension)
		if not entry.is_empty():
			return {"entry": entry}
	if not _script_source_path.is_empty():
		var counterpart_path := _script_source_path.get_base_dir().path_join("%s.%s" % [resref, counterpart_extension])
		if FileAccess.file_exists(counterpart_path):
			return {"path": counterpart_path}
	return {}


func _script_include_exists(include_name: String) -> bool:
	var normalized := include_name.strip_edges()
	if normalized.is_empty():
		return true
	if _script_source_path.is_absolute_path():
		var local_path := _script_source_path.get_base_dir().path_join("%s.nss" % normalized)
		if FileAccess.file_exists(local_path):
			return true
	if _editor_state != null and _editor_state.gamefs != null:
		return not _editor_state.gamefs.resolve_resource(normalized, "nss").is_empty()
	return false


func _extract_script_includes(text: String) -> Array[String]:
	var includes: Array[String] = []
	var regex := RegEx.new()
	if regex.compile('#include\\s+"([^"]+)"') != OK:
		return includes
	for result in regex.search_all(text):
		includes.append(result.get_string(1))
	return includes


func _compute_delimiter_balance(text: String) -> Dictionary:
	return {
		"{}": text.count("{") - text.count("}"),
		"()": text.count("(") - text.count(")"),
		"[]": text.count("[") - text.count("]"),
	}


func _build_hex_preview(bytes: PackedByteArray, bytes_per_line: int = 16, line_limit: int = 128) -> String:
	var lines: Array[String] = []
	var visible_size := mini(bytes.size(), bytes_per_line * line_limit)
	for offset in range(0, visible_size, bytes_per_line):
		var hex_parts: Array[String] = []
		var ascii := ""
		for column in range(bytes_per_line):
			var index := offset + column
			if index >= visible_size:
				hex_parts.append("  ")
				continue
			var value := bytes[index]
			hex_parts.append("%02X" % value)
			ascii += char(value) if value >= 32 and value <= 126 else "."
		lines.append("%08X  %s  %s" % [offset, " ".join(hex_parts), ascii])
	if bytes.size() > visible_size:
		lines.append("")
		lines.append("… truncated after %d bytes of %d total." % [visible_size, bytes.size()])
	return "\n".join(lines)


func _dlg_field_is_editable(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_DICTIONARY:
			return _dlg_is_locstring(value)
		_:
			return false


func _dlg_is_locstring(value: Variant) -> bool:
	return typeof(value) == TYPE_DICTIONARY and value.has("strref") and value.has("strings")


func _dlg_locstring_text(locstring: Dictionary) -> String:
	var strings = locstring.get("strings", {})
	if typeof(strings) != TYPE_DICTIONARY:
		return ""
	if strings.has(0):
		return String(strings.get(0, ""))
	for key in strings.keys():
		var text := String(strings.get(key, ""))
		if not text.is_empty():
			return text
	return ""


func _dlg_resolved_locstring_text(locstring: Dictionary) -> String:
	var local_text := _dlg_locstring_text(locstring).strip_edges()
	if not local_text.is_empty():
		return local_text
	var strref := int(locstring.get("strref", 0xFFFFFFFF))
	if strref >= 0 and strref != 0xFFFFFFFF and _editor_state != null and _editor_state.gamefs != null:
		var tlk_text := String(_editor_state.gamefs.get_dialog_string(strref)).strip_edges()
		if not tlk_text.is_empty():
			return tlk_text
	return KotorDLGDocument.describe_locstring(locstring, "")


func _dlg_node_preview(kind: String, index: int) -> String:
	var node := _dlg_document.get_node(kind, index)
	if node.is_empty():
		return ""
	var text := _dlg_resolved_locstring_text(node.get("Text", {}))
	if text.is_empty():
		text = String(node.get("Comment", node.get("Speaker", ""))).strip_edges()
	return text.substr(0, 96) + ("…" if text.length() > 96 else "")


func _dlg_target_label(kind: String, index: int, link_index: int) -> String:
	if _dlg_document == null:
		return ""
	if kind == "start":
		var start := _dlg_document.get_start(index)
		var target_index := int(start.get("Index", -1))
		return "→ Entry %d — %s" % [target_index, _dlg_node_preview("entry", target_index)]
	var target_kind := _dlg_document.get_link_target_kind(kind)
	var link := _dlg_document.get_link(kind, index, link_index)
	var target_index := _dlg_document.get_link_target_index(link)
	return "→ %s %d — %s" % [
		"Reply" if target_kind == "reply" else "Entry",
		target_index,
		_dlg_node_preview(target_kind, target_index),
	]


func _open_script_ref(script_name: String) -> void:
	var normalized := script_name.strip_edges()
	if normalized.is_empty():
		return
	if _editor_state != null and _editor_state.gamefs != null:
		var source_entry: Dictionary = _editor_state.gamefs.resolve_resource(normalized, "nss")
		if not source_entry.is_empty():
			_open_gamefs_entry(source_entry)
			return
		var binary_entry: Dictionary = _editor_state.gamefs.resolve_resource(normalized, "ncs")
		if not binary_entry.is_empty():
			_open_gamefs_entry(binary_entry)
			return
	var local_dirs: Array[String] = []
	if _script_source_path.is_absolute_path():
		local_dirs.append(_script_source_path.get_base_dir())
	if _dlg_source_path.is_absolute_path():
		local_dirs.append(_dlg_source_path.get_base_dir())
	for directory in local_dirs:
		var local_path := directory.path_join("%s.nss" % normalized)
		if FileAccess.file_exists(local_path):
			_load_script(local_path)
			return
	_append_activity("Script %s was not found in the current workspace or install." % normalized)


func _select_first_dlg_item(root_item: TreeItem) -> void:
	if _dlg_tree == null or root_item == null:
		return
	var item := root_item.get_first_child()
	if item != null:
		item.select(0)
		_dlg_selection = item.get_metadata(0)


func _select_dlg_metadata(metadata: Dictionary) -> void:
	if _dlg_tree == null:
		return
	var root_item := _dlg_tree.get_root()
	if root_item == null:
		return
	var item := _find_tree_item_by_metadata(root_item, metadata)
	if item != null:
		item.select(0)
		_dlg_selection = metadata
		_refresh_dlg_detail()


func _find_tree_item_by_metadata(item: TreeItem, metadata: Dictionary) -> TreeItem:
	var current := item
	while current != null:
		var current_metadata = current.get_metadata(0)
		if typeof(current_metadata) == TYPE_DICTIONARY and _metadata_matches(current_metadata, metadata):
			return current
		var child := current.get_first_child()
		if child != null:
			var match := _find_tree_item_by_metadata(child, metadata)
			if match != null:
				return match
		current = current.get_next()
	return null


func _metadata_matches(left: Dictionary, right: Dictionary) -> bool:
	if str(left.get("kind", "")) != str(right.get("kind", "")):
		return false
	for key in ["owner", "index", "link_index"]:
		if left.get(key, null) != right.get(key, null):
			return false
	return true


func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var file_name := label.strip_edges()
	if file_name.is_empty():
		return fallback
	var separator := file_name.find("  [")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	separator = file_name.find(" — ")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	separator = file_name.find(" [")
	if separator >= 0:
		file_name = file_name.substr(0, separator)
	file_name = file_name.get_file()
	return file_name if not file_name.is_empty() else fallback


func _ensure_mutation_services() -> void:
	if _modding_pipeline == null:
		_modding_pipeline = KotorModdingPipeline.new()
	if _mutation_service == null:
		_mutation_service = KotorMutationService.new()


func _resolve_mutation_service() -> RefCounted:
	_ensure_mutation_services()
	return _mutation_service


func _gamefs_entry_file_name(entry: Dictionary) -> String:
	return "%s.%s" % [entry.get("resref", ""), entry.get("extension", "")]


func _ensure_preflight_dialog() -> void:
	if _preflight_dialog != null:
		return
	_preflight_dialog = KotorPreflightDialog.new()
	_preflight_dialog.preflight_proceed.connect(_on_dock_preflight_proceed)
	_preflight_dialog.preflight_cancel.connect(_on_dock_preflight_cancel)
	add_child(_preflight_dialog)


func _run_mutation_preflight(preview: Dictionary, apply_fn: Callable, on_complete: Callable) -> void:
	if not preview.get("ok", false):
		on_complete.call(preview)
		return
	if str(preview.get("action", "")) == "noop":
		var noop_result := preview.duplicate(true)
		noop_result["applied"] = false
		on_complete.call(noop_result)
		return
	if _skip_preflight_for_testing:
		on_complete.call(apply_fn.call(true))
		return
	_preflight_pending_apply = apply_fn
	_preflight_pending_complete = on_complete
	_ensure_preflight_dialog()
	_preflight_dialog.show_preflight(preview)


func _on_dock_preflight_proceed() -> void:
	if not _preflight_pending_apply.is_valid():
		return
	var result: Dictionary = _preflight_pending_apply.call(true)
	var complete := _preflight_pending_complete
	_preflight_pending_apply = Callable()
	_preflight_pending_complete = Callable()
	if complete.is_valid():
		complete.call(result)


func _on_dock_preflight_cancel() -> void:
	var complete := _preflight_pending_complete
	_preflight_pending_apply = Callable()
	_preflight_pending_complete = Callable()
	var cancelled := {"ok": true, "applied": false, "message": "Operation cancelled."}
	if complete.is_valid():
		complete.call(cancelled)


func _mutation_applied_ok(result: Dictionary) -> bool:
	if not bool(result.get("applied", false)):
		return false
	var pipeline_result: Dictionary = result.get("result", {}) as Dictionary
	if pipeline_result.is_empty():
		return bool(result.get("ok", false))
	return bool(pipeline_result.get("ok", false))


func _mutation_status_text(result: Dictionary) -> String:
	var pipeline_result: Dictionary = result.get("result", {}) as Dictionary
	if not pipeline_result.is_empty():
		return _format_pipeline_result(pipeline_result)
	return _format_pipeline_result(result)


func _format_pipeline_result(result: Dictionary) -> String:
	if result.is_empty():
		return "No result."
	var text := String(result.get("message", ""))
	if result.get("status", "") == "written":
		var target_path := str(result.get("target_path", ""))
		if not target_path.is_empty():
			text += " → %s" % target_path
		var backup_path := str(result.get("backup_path", ""))
		if not backup_path.is_empty():
			text += " (backup: %s)" % backup_path.get_file()
	return text


func _format_compare_result(result: Dictionary) -> String:
	if result.is_empty():
		return "No comparison result."
	var lines: Array[String] = [String(result.get("message", ""))]
	if result.has("core_entry"):
		var core_entry: Dictionary = result.get("core_entry", {})
		lines.append("Core: %s" % str(core_entry.get("location", "")))
	if result.has("override_entry"):
		var override_entry: Dictionary = result.get("override_entry", {})
		lines.append("Override: %s" % str(override_entry.get("location", "")))
	if result.has("details"):
		lines.append("")
		lines.append(String(result.get("details", "")))
	return "\n".join(lines)


func _format_batch_compare_result(result: Dictionary) -> String:
	if result.is_empty():
		return "No batch comparison result."
	if result.has("details"):
		return String(result.get("details", ""))
	return _format_compare_result(result)


func _append_activity(text: String) -> void:
	if _activity_log == null:
		return
	var message := text.strip_edges()
	if message.is_empty():
		return
	if _activity_log.text.is_empty():
		_activity_log.text = message
	else:
		_activity_log.text += "\n\n" + message
	_activity_log.scroll_vertical = _activity_log.get_line_count()


func _should_delegate_to_workspace_editor(extension: String) -> bool:
	var normalized := extension.strip_edges().to_lower()
	if normalized == "dlg":
		return true
	if normalized == "2da" or normalized == "tlk" or normalized == "ssf" or normalized == "tpc" or normalized == "wav" or normalized == "lip" or normalized == "ltr":
		return true
	if KotorErfWorkspaceEditor.archive_extension_allowed(normalized):
		return true
	if SCRIPT_EXTENSIONS.has(normalized):
		return true
	if KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed(normalized):
		return true
	return KotorGFFWorkspaceEditor.workspace_gff_extension_allowed(normalized)


func _viewer_for_extension(extension: String) -> String:
	if extension == "dlg":
		return "DLG Editor"
	if KotorModuleDesignerWorkspaceEditor.module_designer_extension_allowed(extension):
		return "Module Designer"
	if SCRIPT_EXTENSIONS.has(extension):
		return "Script Editor"
	if GFF_EXTENSIONS.has(extension):
		return "GFF Inspector"
	if AREA_TOOL_EXTENSIONS.has(extension):
		return "Area Tools"
	if extension == "2da":
		return "2DA Viewer"
	if extension == "tlk":
		return "TLK Search"
	if extension == "ssf":
		return "SSF Editor"
	if extension == "tpc":
		return "Texture Editor"
	if extension == "wav":
		return "Sound Editor"
	if extension == "lip":
		return "LIP Sync Editor"
	if extension == "ltr":
		return "Letter Table Editor"
	if ARCHIVE_EXTENSIONS.has(extension):
		return "ERF Browser"
	return "No viewer yet"


func _sorted_dictionary_keys(dictionary: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in dictionary.keys():
		keys.append(str(key))
	keys.sort()
	return keys


func _format_source_label(source: String) -> String:
	match source.to_lower():
		"chitin.key":
			return "Chitin"
		"dialog.tlk":
			return "dialog.tlk"
		"modules":
			return "Modules"
		"override":
			return "Override"
		_:
			return source


func _format_size(size: int) -> String:
	if size < 0:
		return "—"
	if size < 1024:
		return "%d B" % size
	if size < 1024 * 1024:
		return "%.1f KiB" % (float(size) / 1024.0)
	return "%.1f MiB" % (float(size) / (1024.0 * 1024.0))


func _ensure_extension(path: String, extension: String) -> String:
	if path.get_extension().to_lower() == extension.to_lower():
		return path
	return "%s.%s" % [path, extension]


func _make_dialog(
		file_mode: EditorFileDialog.FileMode,
		filters: PackedStringArray,
		title: String,
		start_dir: String = "",
		current_file: String = ""
) -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = file_mode
	dialog.title = title
	dialog.filters = filters
	var initial_dir: String = _editor_state.resolve_dialog_start_dir(start_dir)
	if not initial_dir.is_empty():
		dialog.current_dir = initial_dir
	if not current_file.is_empty():
		dialog.current_file = current_file
	return dialog
