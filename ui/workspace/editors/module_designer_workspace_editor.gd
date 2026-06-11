@tool
extends "./kotor_workspace_editor.gd"
class_name KotorModuleDesignerWorkspaceEditor

const GFFParser := preload("../../../formats/gff_parser.gd")
const GFFResourceFactory := preload("../../../resources/gff_resource_factory.gd")
const GITResource := preload("../../../resources/typed/git_resource.gd")
const KotorGITDocument := preload("../../../resources/documents/kotor_git_document.gd")
const KotorEditorState := preload("../../../editor/core/kotor_editor_state.gd")
const KotorMutationService := preload("../../../editor/transactions/kotor_mutation_service.gd")
const KotorModuleContext := preload("../../../editor/module/kotor_module_context.gd")
const BWMWriter := preload("../../../formats/bwm_writer.gd")
const GFFWriter := preload("../../../formats/gff_writer.gd")
const LYTWriter := preload("../../../formats/lyt_writer.gd")
const VISWriter := preload("../../../formats/vis_writer.gd")
const PTHResource := preload("../../../resources/typed/pth_resource.gd")
const KotorPTHDocument := preload("../../../resources/documents/kotor_pth_document.gd")
const KotorTemplateModelResolver := preload("../../../editor/module/kotor_template_model_resolver.gd")
const KotorPreflightDialog := preload("../dialogs/kotor_preflight_dialog.gd")
const ModuleDesignerMapView := preload("../panels/module_designer_map_view.gd")
const ModuleDesignerViewport3D := preload("../panels/module_designer_viewport_3d.gd")

const MODULE_DESIGNER_EXTENSIONS := ["git"]
const TREE_KIND_INSTANCE := "instance"
const TREE_KIND_PATH_POINT := "path_point"
const TREE_KIND_PATH_CONNECTION := "path_connection"

var _toolbar: HBoxContainer
var _path_label: Label
var _bundle_label: Label
var _summary_label: Label
var _detail_label: Label
var _instance_tree: Tree
var _map_view: ModuleDesignerMapView
var _viewport_3d: ModuleDesignerViewport3D
var _parsed_layout: Dictionary = {}
var _parsed_visibility: Dictionary = {}
var _path_resource: PTHResource
var _path_document: KotorPTHDocument
var _parsed_walkmesh: Dictionary = {}
var _parsed_room_meshes: Array = []
var _mutation_service: RefCounted
var _resource: GITResource
var _document: KotorGITDocument
var _source_path := ""
var _file_name := "module.git"
var _dirty := false
var _git_dirty := false
var _pth_dirty := false
var _status_text := ""
var _document_key := ""
var _module_bundle: Dictionary = {}

var _pending_resource: GITResource
var _pending_source_path := ""
var _pending_file_name := ""

var _preflight_dialog: KotorPreflightDialog
var _preflight_pending_path := ""
var _preflight_pending_preview: Dictionary = {}
var _preflight_pending_kind := ""
var _skip_preflight_for_testing := false


func _on_workspace_setup() -> void:
	if _editor_state == null:
		_editor_state = KotorEditorState.new()
		_editor_state.load_settings()
	_mutation_service = _resolve_mutation_service()
	_build_ui()
	if _pending_resource != null:
		var pending_resource := _pending_resource
		var pending_source_path := _pending_source_path
		var pending_file_name := _pending_file_name
		_pending_resource = null
		_pending_source_path = ""
		_pending_file_name = ""
		open_resource(pending_resource, pending_source_path, pending_file_name)


func open_resource(resource: GITResource, source_path: String = "", file_name: String = "") -> void:
	if not is_node_ready():
		_pending_resource = resource
		_pending_source_path = source_path
		_pending_file_name = file_name
		return
	_resource = resource
	if _resource == null:
		_clear_document_state("No GIT resource is loaded.")
		return
	_document = _resource.create_document() as KotorGITDocument
	_disconnect_document_signal()
	_source_path = source_path if source_path.is_absolute_path() else ""
	_file_name = file_name.get_file() if not file_name.is_empty() else "module.git"
	_git_dirty = false
	_pth_dirty = false
	_refresh_dirty_state()
	_status_text = ""
	_reset_overlay_selection()
	if _detail_label != null:
		_detail_label.text = ""
	_refresh_module_bundle()
	_register_controller_document()
	_connect_document_signal()
	_refresh_view()


func open_git_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_clear_document_state("Failed to open %s" % path.get_file())
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	open_git_bytes(path, bytes, path if module_designer_extension_allowed(path.get_extension()) else "")


func open_git_bytes(label: String, data: PackedByteArray, source_path: String = "") -> void:
	var parsed := GFFParser.parse_bytes(data)
	if parsed.is_empty():
		_clear_document_state("Failed to load %s" % _guess_loaded_file_name(label, "module.git"))
		return
	var file_type := String(parsed.get("file_type", "")).strip_edges().to_upper()
	if file_type != "GIT":
		_clear_document_state("Unsupported GFF type %s for module designer" % file_type)
		return
	var resource := GFFResourceFactory.create_from_parser_result(parsed)
	if not resource is GITResource:
		_clear_document_state("Resource is not a GIT layout")
		return
	open_resource(resource, source_path, _guess_loaded_file_name(label, "module.git"))


static func module_designer_extension_allowed(extension: String) -> bool:
	return extension.strip_edges().to_lower() in MODULE_DESIGNER_EXTENSIONS


func has_document() -> bool:
	return _document != null and _resource != null


func get_document() -> KotorGITDocument:
	return _document


func is_document_dirty() -> bool:
	return _dirty


func save_document_to_path(path: String) -> Dictionary:
	if _resource == null:
		return {}
	var target_path := _ensure_extension(path, "git")
	var preview: Dictionary = _mutation_service.preview_export_to_path(target_path, _resource)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Export failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_export_now(target_path)
	_preflight_pending_path = target_path
	_preflight_pending_preview = preview
	_preflight_pending_kind = "export"
	_show_preflight_dialog(preview)
	return {}


func install_document_to_override() -> Dictionary:
	if _resource == null:
		return {}
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_resource
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "File is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_install_now()
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install"
	_show_preflight_dialog(preview)
	return {}


func install_walkmesh_to_override() -> Dictionary:
	if _parsed_walkmesh.is_empty():
		var message := "No area walkmesh loaded for this module."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var bytes := serialize_loaded_walkmesh_bytes()
	if bytes.is_empty():
		var message := "Failed to serialize walkmesh for install."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var file_name := walkmesh_file_name()
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		file_name,
		bytes
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Walkmesh install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "Walkmesh is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_walkmesh_install_now(bytes, file_name)
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install_walkmesh"
	_preflight_pending_path = file_name
	_show_preflight_dialog(preview)
	return {}


func serialize_loaded_walkmesh_bytes() -> PackedByteArray:
	if _parsed_walkmesh.is_empty():
		return PackedByteArray()
	return BWMWriter.write_bytes(_parsed_walkmesh)


func walkmesh_file_name() -> String:
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	return "%s.wok" % module_resref


func install_layout_to_override() -> Dictionary:
	if _parsed_layout.is_empty():
		var message := "No area layout loaded for this module."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var bytes := serialize_loaded_layout_bytes()
	if bytes.is_empty():
		var message := "Failed to serialize layout for install."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var file_name := layout_file_name()
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		file_name,
		bytes
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Layout install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "Layout is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_layout_install_now(bytes, file_name)
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install_layout"
	_preflight_pending_path = file_name
	_show_preflight_dialog(preview)
	return {}


func install_visibility_to_override() -> Dictionary:
	if _parsed_visibility.is_empty():
		var message := "No area visibility loaded for this module."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var bytes := serialize_loaded_visibility_bytes()
	if bytes.is_empty():
		var message := "Failed to serialize visibility for install."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var file_name := visibility_file_name()
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		file_name,
		bytes
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "Visibility install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "Visibility is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_visibility_install_now(bytes, file_name)
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install_visibility"
	_preflight_pending_path = file_name
	_show_preflight_dialog(preview)
	return {}


func install_pth_to_override() -> Dictionary:
	if _path_resource == null:
		var message := "No area path graph loaded for this module."
		_status_text = message
		_refresh_status()
		return {"ok": false, "message": message}
	var file_name := pth_file_name()
	var preview: Dictionary = _mutation_service.preview_install_to_override(
		_resolve_gamefs(),
		file_name,
		_path_resource
	)
	if not preview.get("ok", false):
		_status_text = preview.get("message", "PTH install failed")
		_refresh_status()
		return preview
	if preview.get("action", "") == "noop":
		_status_text = preview.get("message", "PTH is already up to date")
		_refresh_status()
		return preview
	if _skip_preflight_for_testing:
		return _apply_pth_install_now(file_name)
	_preflight_pending_preview = preview
	_preflight_pending_kind = "install_pth"
	_preflight_pending_path = file_name
	_show_preflight_dialog(preview)
	return {}


func serialize_loaded_layout_bytes() -> PackedByteArray:
	if _parsed_layout.is_empty():
		return PackedByteArray()
	return LYTWriter.write_bytes(_parsed_layout)


func serialize_loaded_visibility_bytes() -> PackedByteArray:
	if _parsed_visibility.is_empty():
		return PackedByteArray()
	return VISWriter.write_bytes(_parsed_visibility)


func layout_file_name() -> String:
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	return "%s.lyt" % module_resref


func visibility_file_name() -> String:
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	return "%s.vis" % module_resref


func pth_file_name() -> String:
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	return "%s.pth" % module_resref


func _build_ui() -> void:
	if _toolbar != null:
		return
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)

	var install_btn := Button.new()
	install_btn.text = "Install to Override"
	install_btn.pressed.connect(_install_git_to_override)
	_toolbar.add_child(install_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_git)
	_toolbar.add_child(save_btn)

	var export_walkmesh_btn := Button.new()
	export_walkmesh_btn.text = "Export Walkmesh Preview…"
	export_walkmesh_btn.pressed.connect(_export_walkmesh_preview_dialog)
	_toolbar.add_child(export_walkmesh_btn)

	var export_layout_btn := Button.new()
	export_layout_btn.text = "Export LYT Preview…"
	export_layout_btn.pressed.connect(_export_layout_preview_dialog)
	_toolbar.add_child(export_layout_btn)

	var export_visibility_btn := Button.new()
	export_visibility_btn.text = "Export VIS Preview…"
	export_visibility_btn.pressed.connect(_export_visibility_preview_dialog)
	_toolbar.add_child(export_visibility_btn)

	var export_pth_btn := Button.new()
	export_pth_btn.text = "Export PTH Preview…"
	export_pth_btn.pressed.connect(_export_pth_preview_dialog)
	_toolbar.add_child(export_pth_btn)

	var install_walkmesh_btn := Button.new()
	install_walkmesh_btn.text = "Install Walkmesh to Override"
	install_walkmesh_btn.pressed.connect(_install_walkmesh_to_override)
	_toolbar.add_child(install_walkmesh_btn)

	var install_layout_btn := Button.new()
	install_layout_btn.text = "Install LYT to Override"
	install_layout_btn.pressed.connect(_install_layout_to_override)
	_toolbar.add_child(install_layout_btn)

	var install_visibility_btn := Button.new()
	install_visibility_btn.text = "Install VIS to Override"
	install_visibility_btn.pressed.connect(_install_visibility_to_override)
	_toolbar.add_child(install_visibility_btn)

	var install_pth_btn := Button.new()
	install_pth_btn.text = "Install PTH to Override"
	install_pth_btn.pressed.connect(_install_pth_to_override)
	_toolbar.add_child(install_pth_btn)

	var add_pth_point_btn := Button.new()
	add_pth_point_btn.text = "Add Path Point"
	add_pth_point_btn.pressed.connect(_arm_add_path_point)
	_toolbar.add_child(add_pth_point_btn)

	var remove_pth_point_btn := Button.new()
	remove_pth_point_btn.text = "Remove Path Point"
	remove_pth_point_btn.pressed.connect(_remove_selected_path_point)
	_toolbar.add_child(remove_pth_point_btn)

	var add_pth_connection_btn := Button.new()
	add_pth_connection_btn.text = "Add Path Connection"
	add_pth_connection_btn.pressed.connect(_arm_add_path_connection)
	_toolbar.add_child(add_pth_connection_btn)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toolbar.add_child(_path_label)

	_bundle_label = Label.new()
	_bundle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_bundle_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(260, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left_panel)

	_instance_tree = Tree.new()
	_instance_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_instance_tree.item_selected.connect(_on_instance_tree_selected)
	left_panel.add_child(_instance_tree)

	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(_detail_label)

	_map_view = ModuleDesignerMapView.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.instance_selected.connect(_on_map_instance_selected)
	_map_view.path_point_selected.connect(_on_map_path_point_selected)
	_map_view.path_connection_selected.connect(_on_map_path_connection_selected)
	_map_view.path_connection_retarget_requested.connect(_on_map_path_connection_retarget_requested)
	_map_view.path_connection_add_requested.connect(_on_map_path_connection_add_requested)
	_map_view.path_point_add_requested.connect(_on_map_path_point_add_requested)
	_map_view.instance_drag_finished.connect(_on_map_instance_drag_finished)
	_map_view.path_point_drag_finished.connect(_on_map_path_point_drag_finished)
	_map_view.instance_rotate_finished.connect(_on_map_instance_rotate_finished)

	var right_split := VSplitContainer.new()
	right_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_split.add_child(_map_view)

	_viewport_3d = ModuleDesignerViewport3D.new()
	_viewport_3d.instance_selected.connect(_on_viewport_instance_selected)
	_viewport_3d.path_point_selected.connect(_on_viewport_path_point_selected)
	_viewport_3d.path_connection_selected.connect(_on_viewport_path_connection_selected)
	_viewport_3d.instance_rotate_finished.connect(_on_map_instance_rotate_finished)
	right_split.add_child(_viewport_3d)

	split.add_child(right_split)


func _refresh_view() -> void:
	if _document == null:
		return
	_refresh_path_label()
	_refresh_bundle_label()
	_refresh_summary()
	_refresh_instance_tree()
	_refresh_map()
	_refresh_status()


func _refresh_path_label() -> void:
	if _path_label == null:
		return
	var label := _current_file_name()
	if _dirty:
		label += " *"
	var parts: Array[String] = [label]
	if not _source_path.is_empty():
		parts.append(_source_path)
	_path_label.text = " · ".join(parts)


func _refresh_bundle_label() -> void:
	if _bundle_label == null:
		return
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	_bundle_label.text = "Module %s — %s" % [
		module_resref,
		KotorModuleContext.describe_bundle(_module_bundle),
	]


func _refresh_summary() -> void:
	if _summary_label == null or _document == null:
		return
	var lines: Array[String] = [_document.build_summary_text()]
	if not _parsed_layout.is_empty():
		lines.append(KotorModuleContext.format_layout_summary(_parsed_layout))
	if not _parsed_visibility.is_empty():
		lines.append(KotorModuleContext.format_visibility_summary(_parsed_visibility))
	if _path_resource != null:
		lines.append(KotorModuleContext.format_path_summary(_path_resource))
	if not _parsed_walkmesh.is_empty():
		lines.append(
			"Walkmesh: %d face(s), %d vertex/vertices"
			% [int(_parsed_walkmesh.get("face_count", 0)), int(_parsed_walkmesh.get("vertex_count", 0))]
		)
	_summary_label.text = "\n".join(lines)


func _refresh_instance_tree() -> void:
	if _instance_tree == null or _document == null:
		return
	_instance_tree.clear()
	var root := _instance_tree.create_item()
	root.set_text(0, _document.get_display_name())
	var grouped := {}
	for record in _document.get_instance_records():
		var category := str(record.get("category", "Unknown"))
		if not grouped.has(category):
			grouped[category] = []
		grouped[category].append(record)
	for category in KotorGITDocument.LIST_FIELDS:
		if not grouped.has(category):
			continue
		var category_item := _instance_tree.create_item(root)
		category_item.set_text(0, "%s (%d)" % [category, grouped[category].size()])
		for record in grouped[category]:
			var item := _instance_tree.create_item(category_item)
			var template := str(record.get("template", ""))
			var tag := str(record.get("tag", ""))
			var label := template if not template.is_empty() else tag
			if label.is_empty():
				label = "%s #%d" % [category, int(record.get("index", 0))]
			item.set_text(0, label)
			item.set_metadata(0, {
				"kind": TREE_KIND_INSTANCE,
				"category": str(record.get("category", "")),
				"index": int(record.get("index", -1)),
			})
	var path_points := _module_path_points()
	if not path_points.is_empty():
		var path_item := _instance_tree.create_item(root)
		path_item.set_text(0, "Path Points (%d)" % path_points.size())
		for point_record in path_points:
			var item := _instance_tree.create_item(path_item)
			item.set_text(0, "Point %d" % int(point_record.get("id", int(point_record.get("index", 0)))))
			item.set_metadata(0, {
				"kind": TREE_KIND_PATH_POINT,
				"index": int(point_record.get("index", -1)),
			})
	var path_connections := _module_path_edges()
	if not path_connections.is_empty():
		var connection_item := _instance_tree.create_item(root)
		connection_item.set_text(0, "Path Connections (%d)" % path_connections.size())
		for connection_record in path_connections:
			var item := _instance_tree.create_item(connection_item)
			item.set_text(0, _module_path_connection_label(connection_record))
			item.set_metadata(0, {
				"kind": TREE_KIND_PATH_CONNECTION,
				"index": int(connection_record.get("index", -1)),
			})


func _refresh_map() -> void:
	if _map_view == null or _document == null:
		return
	var records := _document.get_instance_records()
	var path_points := _module_path_points()
	var path_edges := _module_path_edges()
	_map_view.set_instances(records, _module_overlay_bounds(_document.get_layout_bounds(), path_points), path_points, path_edges)
	_refresh_viewport_3d()


func _refresh_viewport_3d() -> void:
	if _viewport_3d == null or _document == null:
		return
	var records := _document.get_instance_records()
	var path_points := _module_path_points()
	var path_edges := _module_path_edges()
	_viewport_3d.set_instances(records, _parsed_layout)
	_viewport_3d.set_path_points(path_points)
	_viewport_3d.set_path_edges(path_edges)
	_viewport_3d.set_walkmesh(_parsed_walkmesh)
	_viewport_3d.set_room_meshes(_parsed_room_meshes)
	_viewport_3d.set_instance_meshes(_load_instance_meshes(_resolve_gamefs(), records))


func _refresh_status() -> void:
	var parts: Array[String] = []
	if _git_dirty:
		parts.append("Unsaved GIT changes")
	if _pth_dirty:
		parts.append("Unsaved PTH changes")
	if not _status_text.is_empty():
		parts.append(_status_text)
	var text := "Ready" if parts.is_empty() else " · ".join(parts)
	_emit_status_text(text)


func _refresh_module_bundle() -> void:
	var gamefs := _resolve_gamefs()
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	_module_bundle = KotorModuleContext.find_module_bundle(gamefs, module_resref)
	_parsed_layout = KotorModuleContext.load_parsed_layout(gamefs, _module_bundle)
	_parsed_visibility = KotorModuleContext.load_parsed_visibility(gamefs, _module_bundle)
	_set_path_resource(KotorModuleContext.load_path_resource(gamefs, _module_bundle))
	_parsed_walkmesh = KotorModuleContext.load_parsed_walkmesh(gamefs, _module_bundle)
	_parsed_room_meshes = _load_room_meshes(gamefs)


func _load_room_meshes(gamefs: RefCounted) -> Array:
	var entries: Array = []
	if gamefs == null or _parsed_layout.is_empty():
		return entries
	var rooms: Array = _parsed_layout.get("rooms", [])
	var mesh_cache: Dictionary = {}
	for raw_room in rooms:
		if typeof(raw_room) != TYPE_DICTIONARY:
			continue
		var room: Dictionary = raw_room
		var model_name := str(room.get("model", "")).strip_edges()
		if model_name.is_empty():
			continue
		var normalized := model_name.to_lower()
		if not mesh_cache.has(normalized):
			mesh_cache[normalized] = KotorModuleContext.load_parsed_model_mesh(gamefs, normalized)
		entries.append({
			"model": normalized,
			"position": room.get("position", Vector3.ZERO),
			"mesh": mesh_cache[normalized],
		})
	return entries


func _load_instance_meshes(gamefs: RefCounted, records: Array) -> Array:
	var entries: Array = []
	if gamefs == null:
		return entries
	var resolve_cache: Dictionary = {}
	var mesh_cache: Dictionary = {}
	for raw_record in records:
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = raw_record
		var category := str(record.get("category", ""))
		if not KotorTemplateModelResolver.supports_mesh_category(category):
			continue
		var template := str(record.get("template", "")).strip_edges()
		if template.is_empty():
			continue
		var resolve_key := "%s:%s" % [category, template.to_lower()]
		if not resolve_cache.has(resolve_key):
			resolve_cache[resolve_key] = KotorTemplateModelResolver.resolve_model_resref(
				gamefs,
				category,
				template
			)
		var model_resref := str(resolve_cache[resolve_key])
		if model_resref.is_empty():
			continue
		if not mesh_cache.has(model_resref):
			mesh_cache[model_resref] = KotorModuleContext.load_parsed_model_mesh(gamefs, model_resref)
		var mesh_dict: Dictionary = mesh_cache[model_resref]
		if mesh_dict.is_empty():
			continue
		entries.append({
			"category": category,
			"index": int(record.get("index", -1)),
			"mesh": mesh_dict,
		})
	return entries


func _module_path_points() -> Array[Dictionary]:
	if _path_resource == null:
		return []
	return _path_resource.get_point_records()


func _module_path_edges() -> Array[Dictionary]:
	if _path_resource == null:
		return []
	return _path_resource.get_connection_records()


func _module_path_point_by_index(index: int) -> Dictionary:
	for point_record in _module_path_points():
		if int(point_record.get("index", -1)) == index:
			return point_record
	return {}


func _module_path_outgoing_edges(index: int) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for edge_record in _module_path_edges():
		if int(edge_record.get("source_index", -1)) == index:
			records.append(edge_record)
	return records


func _module_path_connection_by_index(index: int) -> Dictionary:
	for edge_record in _module_path_edges():
		if int(edge_record.get("index", -1)) == index:
			return edge_record
	return {}


func _module_path_connection_label(record: Dictionary) -> String:
	return "Connection %d: %d -> %d" % [
		int(record.get("index", 0)),
		int(record.get("source_id", int(record.get("source_index", 0)))),
		int(record.get("target_id", int(record.get("target_index", 0)))),
	]


func _module_overlay_bounds(base_bounds: Rect2, path_points: Array[Dictionary]) -> Rect2:
	if path_points.is_empty():
		return base_bounds
	var has_bounds := base_bounds.size.x > 0.0 and base_bounds.size.y > 0.0
	var min_point := base_bounds.position if has_bounds else Vector2.ZERO
	var max_point := base_bounds.end if has_bounds else Vector2.ZERO
	for raw_point in path_points:
		var point := Vector2(float(raw_point.get("x", 0.0)), float(raw_point.get("y", 0.0)))
		if not has_bounds:
			min_point = point
			max_point = point
			has_bounds = true
			continue
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	if not has_bounds:
		return base_bounds
	var size := max_point - min_point
	if is_zero_approx(size.x):
		size.x = 1.0
	if is_zero_approx(size.y):
		size.y = 1.0
	return Rect2(min_point, size).grow(1.0)


func _on_instance_tree_selected() -> void:
	var selected := _instance_tree.get_selected()
	if selected == null:
		return
	var metadata = selected.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY:
		if _detail_label != null:
			_detail_label.text = ""
		if _map_view != null:
			_map_view.set_selection("", -1)
			_map_view.set_path_point_selection(-1)
			_map_view.set_path_connection_selection(-1)
		if _viewport_3d != null:
			_viewport_3d.set_selection("", -1)
			_viewport_3d.set_path_point_selection(-1)
			_viewport_3d.set_path_connection_selection(-1)
		return
	var kind := str(metadata.get("kind", ""))
	if kind == TREE_KIND_INSTANCE:
		_select_instance(str(metadata.get("category", "")), int(metadata.get("index", -1)))
		return
	if kind == TREE_KIND_PATH_POINT:
		_select_path_point(int(metadata.get("index", -1)))
		return
	if kind == TREE_KIND_PATH_CONNECTION:
		_select_path_connection(int(metadata.get("index", -1)))
		return


func _on_map_instance_selected(category: String, index: int) -> void:
	_select_instance(category, index)


func _on_map_path_point_selected(index: int) -> void:
	_select_path_point(index)


func _on_map_path_connection_selected(index: int) -> void:
	_select_path_connection(index)


func _on_map_path_connection_retarget_requested(connection_index: int, target_index: int) -> void:
	var connection_record := _module_path_connection_by_index(connection_index)
	if connection_record.is_empty():
		return
	var source_index := int(connection_record.get("source_index", -1))
	if source_index == target_index:
		return
	var old_target := int(connection_record.get("target_index", -1))
	if old_target == target_index:
		return
	_apply_path_connection_retarget_with_undo(connection_index, old_target, target_index)


func _arm_add_path_point() -> void:
	if _map_view == null or _path_document == null:
		return
	_map_view.set_add_path_point_armed(true)
	_status_text = "Click the map to place a new path point."
	_refresh_status()


func _remove_selected_path_point() -> void:
	if _map_view == null or _path_document == null:
		return
	var index := _map_view._selected_path_point_index
	if index < 0:
		_status_text = "Select a path point to remove."
		_refresh_status()
		return
	_status_text = ""
	_refresh_status()
	_apply_path_point_remove_with_undo(index)


func _arm_add_path_connection() -> void:
	if _map_view == null or _path_document == null:
		return
	var source_index := _map_view._selected_path_point_index
	if source_index < 0:
		_status_text = "Select a source path point before adding a connection."
		_refresh_status()
		return
	_map_view.set_add_path_connection_armed(true)
	_status_text = "Click a target path point to connect from the selected source."
	_refresh_status()


func _on_map_path_connection_add_requested(source_index: int, target_index: int) -> void:
	if _map_view != null:
		_map_view.set_add_path_connection_armed(false)
	_status_text = ""
	_refresh_status()
	_apply_path_connection_add_with_undo(source_index, target_index)


func _on_map_path_point_add_requested(x: float, y: float) -> void:
	if _map_view != null:
		_map_view.set_add_path_point_armed(false)
	_status_text = ""
	_refresh_status()
	_apply_path_point_add_with_undo(x, y)


func _on_map_instance_drag_finished(
	category: String,
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
) -> void:
	_apply_instance_position_with_undo(category, index, old_x, old_y, new_x, new_y)


func _on_map_path_point_drag_finished(
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
) -> void:
	_apply_path_point_position_with_undo(index, old_x, old_y, new_x, new_y)


func _on_map_instance_rotate_finished(
	category: String,
	index: int,
	old_bearing: float,
	new_bearing: float
) -> void:
	_apply_instance_bearing_with_undo(category, index, old_bearing, new_bearing)


func _on_viewport_instance_selected(category: String, index: int) -> void:
	_select_instance(category, index)


func _on_viewport_path_point_selected(index: int) -> void:
	_select_path_point(index)


func _on_viewport_path_connection_selected(index: int) -> void:
	_select_path_connection(index)


func _select_instance(category: String, index: int) -> void:
	var record := _document.find_instance_record(category, index)
	if record.is_empty():
		return
	_show_instance_detail(record)
	if _map_view != null:
		_map_view.set_selection(category, index)
		_map_view.set_path_point_selection(-1)
		_map_view.set_path_connection_selection(-1)
	if _viewport_3d != null:
		_viewport_3d.set_selection(category, index)
		_viewport_3d.set_path_point_selection(-1)
		_viewport_3d.set_path_connection_selection(-1)
	_select_tree_item(TREE_KIND_INSTANCE, category, index)


func _select_path_point(index: int) -> void:
	var point_record := _module_path_point_by_index(index)
	if point_record.is_empty():
		return
	_show_path_point_detail(point_record)
	if _map_view != null:
		_map_view.set_selection("", -1)
		_map_view.set_path_point_selection(index)
		_map_view.set_path_connection_selection(-1)
	if _viewport_3d != null:
		_viewport_3d.set_selection("", -1)
		_viewport_3d.set_path_point_selection(index)
		_viewport_3d.set_path_connection_selection(-1)
	_select_tree_item(TREE_KIND_PATH_POINT, "", index)


func _select_path_connection(index: int) -> void:
	var connection_record := _module_path_connection_by_index(index)
	if connection_record.is_empty():
		return
	_show_path_connection_detail(connection_record)
	if _map_view != null:
		_map_view.set_selection("", -1)
		_map_view.set_path_point_selection(-1)
		_map_view.set_path_connection_selection(index)
	if _viewport_3d != null:
		_viewport_3d.set_selection("", -1)
		_viewport_3d.set_path_point_selection(-1)
		_viewport_3d.set_path_connection_selection(index)
	_select_tree_item(TREE_KIND_PATH_CONNECTION, "", index)


func _show_instance_detail(record: Dictionary) -> void:
	if _detail_label == null:
		return
	_detail_label.text = (
		"%s #%d\nTemplate: %s\nTag: %s\nPosition: %.2f, %.2f, %.2f\nBearing: %.2f"
		% [
			str(record.get("category", "")),
			int(record.get("index", 0)),
			str(record.get("template", "")),
			str(record.get("tag", "")),
			float(record.get("x", 0.0)),
			float(record.get("y", 0.0)),
			float(record.get("z", 0.0)),
			float(record.get("bearing", 0.0)),
		]
	)


func _show_path_point_detail(record: Dictionary) -> void:
	if _detail_label == null:
		return
	var point_index := int(record.get("index", -1))
	var outgoing := _module_path_outgoing_edges(point_index)
	var target_ids: Array[String] = []
	for edge_record in outgoing:
		target_ids.append(str(int(edge_record.get("target_id", int(edge_record.get("target_index", -1))))))
	var targets_text := "none" if target_ids.is_empty() else ", ".join(target_ids)
	_detail_label.text = (
		"Path Point #%d\nPoint ID: %d\nPosition: %.2f, %.2f, %.2f\nOutgoing connections: %d\nTargets: %s"
		% [
			point_index,
			int(record.get("id", point_index)),
			float(record.get("x", 0.0)),
			float(record.get("y", 0.0)),
			float(record.get("z", 0.0)),
			outgoing.size(),
			targets_text,
		]
	)


func _show_path_connection_detail(record: Dictionary) -> void:
	if _detail_label == null:
		return
	_detail_label.text = (
		"Path Connection #%d\nSource: Point %d at %.2f, %.2f, %.2f\nTarget: Point %d at %.2f, %.2f, %.2f"
		% [
			int(record.get("index", 0)),
			int(record.get("source_id", int(record.get("source_index", 0)))),
			float(record.get("source_x", 0.0)),
			float(record.get("source_y", 0.0)),
			float(record.get("source_z", 0.0)),
			int(record.get("target_id", int(record.get("target_index", 0)))),
			float(record.get("target_x", 0.0)),
			float(record.get("target_y", 0.0)),
			float(record.get("target_z", 0.0)),
		]
	)


func _select_tree_item(kind: String, category: String, index: int) -> void:
	if _instance_tree == null:
		return
	var root := _instance_tree.get_root()
	if root == null:
		return
	for category_item in root.get_children():
		for item in category_item.get_children():
			var metadata = item.get_metadata(0)
			if typeof(metadata) != TYPE_DICTIONARY:
				continue
			if str(metadata.get("kind", "")) != kind:
				continue
			if kind == TREE_KIND_INSTANCE and str(metadata.get("category", "")) != category:
				continue
			if int(metadata.get("index", -1)) != index:
				continue
			item.select(0)
			return


func _reset_overlay_selection() -> void:
	if _map_view != null:
		_map_view.set_add_path_point_armed(false)
		_map_view.set_selection("", -1)
		_map_view.set_path_point_selection(-1)
		_map_view.set_path_connection_selection(-1)
	if _viewport_3d != null:
		_viewport_3d.set_selection("", -1)
		_viewport_3d.set_path_point_selection(-1)
		_viewport_3d.set_path_connection_selection(-1)


func _clear_document_state(message: String) -> void:
	_disconnect_document_signal()
	_disconnect_path_document_signal()
	_resource = null
	_document = null
	_source_path = ""
	_file_name = "module.git"
	_git_dirty = false
	_pth_dirty = false
	_refresh_dirty_state()
	_status_text = message
	_module_bundle = {}
	_parsed_layout = {}
	_parsed_visibility = {}
	_path_resource = null
	_path_document = null
	_parsed_walkmesh = {}
	_parsed_room_meshes = []
	if _instance_tree != null:
		_instance_tree.clear()
	if _map_view != null:
		_map_view.set_instances([], Rect2())
	if _viewport_3d != null:
		_viewport_3d.set_instances([], {})
		_viewport_3d.set_path_points([])
		_viewport_3d.set_path_edges([])
		_viewport_3d.set_walkmesh({})
		_viewport_3d.set_room_meshes([])
	_reset_overlay_selection()
	if _detail_label != null:
		_detail_label.text = ""
	if _summary_label != null:
		_summary_label.text = ""
	if _bundle_label != null:
		_bundle_label.text = ""
	_refresh_path_label()
	_refresh_status()


func _save_git() -> void:
	if _source_path.is_empty():
		_status_text = "Use Install to Override or open from a file path first"
		_refresh_status()
		return
	save_document_to_path(_source_path)


func _export_walkmesh_preview_dialog() -> void:
	if _parsed_walkmesh.is_empty():
		_status_text = "No area walkmesh loaded for this module."
		_refresh_status()
		return
	var start_dir := ""
	var editor_state := get_editor_state()
	if editor_state != null:
		start_dir = str(editor_state.game_path)
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Export Walkmesh Preview"
	if not start_dir.is_empty():
		dialog.current_dir = start_dir
	var module_resref := KotorModuleContext.module_resref_from_file_name(_file_name)
	dialog.current_file = "%s.wok" % module_resref
	dialog.add_filter("*.wok ; Walkmesh")
	dialog.file_selected.connect(func(path: String) -> void:
		_write_walkmesh_preview(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _export_layout_preview_dialog() -> void:
	if _parsed_layout.is_empty():
		_status_text = "No area layout loaded for this module."
		_refresh_status()
		return
	var start_dir := ""
	var editor_state := get_editor_state()
	if editor_state != null:
		start_dir = str(editor_state.game_path)
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Export LYT Preview"
	if not start_dir.is_empty():
		dialog.current_dir = start_dir
	dialog.current_file = layout_file_name()
	dialog.add_filter("*.lyt ; KotOR Layout")
	dialog.file_selected.connect(func(path: String) -> void:
		export_layout_preview_to_path(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _export_visibility_preview_dialog() -> void:
	if _parsed_visibility.is_empty():
		_status_text = "No area visibility loaded for this module."
		_refresh_status()
		return
	var start_dir := ""
	var editor_state := get_editor_state()
	if editor_state != null:
		start_dir = str(editor_state.game_path)
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Export VIS Preview"
	if not start_dir.is_empty():
		dialog.current_dir = start_dir
	dialog.current_file = visibility_file_name()
	dialog.add_filter("*.vis ; KotOR Visibility")
	dialog.file_selected.connect(func(path: String) -> void:
		export_visibility_preview_to_path(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _export_pth_preview_dialog() -> void:
	if _path_resource == null:
		_status_text = "No area path graph loaded for this module."
		_refresh_status()
		return
	var start_dir := ""
	var editor_state := get_editor_state()
	if editor_state != null:
		start_dir = str(editor_state.game_path)
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.title = "Export PTH Preview"
	if not start_dir.is_empty():
		dialog.current_dir = start_dir
	dialog.current_file = pth_file_name()
	dialog.add_filter("*.pth ; KotOR Path Graph")
	dialog.file_selected.connect(func(path: String) -> void:
		export_pth_preview_to_path(path)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _write_walkmesh_preview(path: String) -> void:
	var target_path := path
	if target_path.get_extension().to_lower() != "wok":
		target_path = "%s.wok" % target_path.get_basename()
	var bytes := serialize_loaded_walkmesh_bytes()
	if bytes.is_empty():
		_status_text = "Failed to serialize walkmesh preview."
		_refresh_status()
		return
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		_status_text = "Failed to write walkmesh preview: %s" % target_path
		_refresh_status()
		return
	file.store_buffer(bytes)
	file.close()
	_status_text = "Walkmesh preview written to %s" % target_path.get_file()
	_refresh_status()


func export_layout_preview_to_path(path: String) -> Dictionary:
	if _parsed_layout.is_empty():
		var missing_message := "No area layout loaded for this module."
		_status_text = missing_message
		_refresh_status()
		return {"ok": false, "message": missing_message}
	var target_path := _ensure_extension(path, "lyt")
	var bytes := serialize_loaded_layout_bytes()
	if bytes.is_empty():
		var serialize_message := "Failed to serialize layout preview."
		_status_text = serialize_message
		_refresh_status()
		return {"ok": false, "message": serialize_message}
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		var write_message := "Failed to write layout preview: %s" % target_path
		_status_text = write_message
		_refresh_status()
		return {"ok": false, "message": write_message, "path": target_path}
	file.store_buffer(bytes)
	file.close()
	_status_text = "LYT preview written to %s" % target_path.get_file()
	_refresh_status()
	return {"ok": true, "path": target_path}


func export_visibility_preview_to_path(path: String) -> Dictionary:
	if _parsed_visibility.is_empty():
		var missing_message := "No area visibility loaded for this module."
		_status_text = missing_message
		_refresh_status()
		return {"ok": false, "message": missing_message}
	var target_path := _ensure_extension(path, "vis")
	var bytes := serialize_loaded_visibility_bytes()
	if bytes.is_empty():
		var serialize_message := "Failed to serialize visibility preview."
		_status_text = serialize_message
		_refresh_status()
		return {"ok": false, "message": serialize_message}
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		var write_message := "Failed to write visibility preview: %s" % target_path
		_status_text = write_message
		_refresh_status()
		return {"ok": false, "message": write_message, "path": target_path}
	file.store_buffer(bytes)
	file.close()
	_status_text = "VIS preview written to %s" % target_path.get_file()
	_refresh_status()
	return {"ok": true, "path": target_path}


func export_pth_preview_to_path(path: String) -> Dictionary:
	if _path_resource == null:
		var missing_message := "No area path graph loaded for this module."
		_status_text = missing_message
		_refresh_status()
		return {"ok": false, "message": missing_message}
	var target_path := _ensure_extension(path, "pth")
	var bytes := GFFWriter.serialize(_path_resource)
	if bytes.is_empty():
		var serialize_message := "Failed to serialize path preview."
		_status_text = serialize_message
		_refresh_status()
		return {"ok": false, "message": serialize_message}
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		var write_message := "Failed to write path preview: %s" % target_path
		_status_text = write_message
		_refresh_status()
		return {"ok": false, "message": write_message, "path": target_path}
	file.store_buffer(bytes)
	file.close()
	_status_text = "PTH preview written to %s" % target_path.get_file()
	_refresh_status()
	return {"ok": true, "path": target_path}


func _install_walkmesh_to_override() -> void:
	install_walkmesh_to_override()


func _install_layout_to_override() -> void:
	install_layout_to_override()


func _install_visibility_to_override() -> void:
	install_visibility_to_override()


func _install_pth_to_override() -> void:
	install_pth_to_override()


func _install_git_to_override() -> void:
	install_document_to_override()


func _apply_export_now(target_path: String) -> Dictionary:
	var previous_key := _document_key
	var result: Dictionary = _mutation_service.apply_export_to_path(target_path, _resource, true)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_source_path = target_path
		_file_name = target_path.get_file()
		_git_dirty = false
		_refresh_dirty_state()
		_register_controller_document()
		_remove_previous_controller_document(previous_key)
	_update_controller_dirty_state()
	_refresh_status()
	return result


func _apply_install_now() -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		_current_file_name(),
		_resource,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_git_dirty = false
		_refresh_gamefs()
		_refresh_module_bundle()
		_refresh_bundle_label()
		_refresh_dirty_state()
	_update_controller_dirty_state()
	_refresh_status()
	return result


func _apply_walkmesh_install_now(bytes: PackedByteArray, file_name: String) -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		file_name,
		bytes,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_refresh_gamefs()
		_refresh_module_bundle()
		_refresh_bundle_label()
	_refresh_status()
	return result


func _apply_layout_install_now(bytes: PackedByteArray, file_name: String) -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		file_name,
		bytes,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_refresh_gamefs()
		_refresh_module_bundle()
		_refresh_bundle_label()
	_refresh_status()
	return result


func _apply_visibility_install_now(bytes: PackedByteArray, file_name: String) -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		file_name,
		bytes,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_refresh_gamefs()
		_refresh_module_bundle()
		_refresh_bundle_label()
	_refresh_status()
	return result


func _apply_pth_install_now(file_name: String) -> Dictionary:
	var result: Dictionary = _mutation_service.apply_install_to_override(
		_resolve_gamefs(),
		file_name,
		_path_resource,
		true
	)
	_status_text = _mutation_message(result)
	if result.get("applied", false):
		_pth_dirty = false
		_refresh_gamefs()
		_refresh_module_bundle()
		_refresh_bundle_label()
		_refresh_dirty_state()
	_update_controller_dirty_state()
	_refresh_status()
	return result


func _show_preflight_dialog(preview: Dictionary) -> void:
	if _preflight_dialog == null:
		_preflight_dialog = KotorPreflightDialog.new()
		_preflight_dialog.preflight_proceed.connect(_on_preflight_proceed)
		_preflight_dialog.preflight_cancel.connect(_on_preflight_cancel)
		add_child(_preflight_dialog)
	_preflight_dialog.show_preflight(preview)


func _on_preflight_proceed() -> void:
	if _preflight_pending_kind == "export":
		_apply_export_now(_preflight_pending_path)
	elif _preflight_pending_kind == "install":
		_apply_install_now()
	elif _preflight_pending_kind == "install_walkmesh":
		var bytes := serialize_loaded_walkmesh_bytes()
		_apply_walkmesh_install_now(bytes, _preflight_pending_path)
	elif _preflight_pending_kind == "install_layout":
		var layout_bytes := serialize_loaded_layout_bytes()
		_apply_layout_install_now(layout_bytes, _preflight_pending_path)
	elif _preflight_pending_kind == "install_visibility":
		var visibility_bytes := serialize_loaded_visibility_bytes()
		_apply_visibility_install_now(visibility_bytes, _preflight_pending_path)
	elif _preflight_pending_kind == "install_pth":
		_apply_pth_install_now(_preflight_pending_path)
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _on_preflight_cancel() -> void:
	_status_text = "Operation cancelled."
	_refresh_status()
	_preflight_pending_kind = ""
	_preflight_pending_path = ""
	_preflight_pending_preview = {}


func _register_controller_document() -> void:
	var controller := get_controller()
	if controller == null or not controller.has_method("register_document"):
		return
	var entry: Dictionary = controller.call(
		"register_document",
		"module",
		_resource,
		_document,
		_source_path,
		_current_file_name(),
		{}
	)
	_document_key = str(entry.get("key", ""))


func _update_controller_dirty_state() -> void:
	var controller := get_controller()
	if controller == null or _document_key.is_empty() or not controller.has_method("update_document_dirty"):
		return
	controller.call("update_document_dirty", _document_key, _dirty)


func _remove_previous_controller_document(previous_key: String) -> void:
	var controller := get_controller()
	if controller == null or previous_key.is_empty() or previous_key == _document_key or not controller.has_method("remove_document"):
		return
	controller.call("remove_document", previous_key)


func _get_undo_redo() -> EditorUndoRedoManager:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_undo_redo()
	return null


func _apply_instance_position_with_undo(
	category: String,
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Move GIT instance", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_instance_position", category, index, new_x, new_y)
		ur.add_undo_method(self, "_exec_instance_position", category, index, old_x, old_y)
		ur.commit_action()
	else:
		_exec_instance_position(category, index, new_x, new_y)


func _exec_instance_position(category: String, index: int, x: float, y: float) -> void:
	if _document == null:
		return
	if not _document.set_instance_position(category, index, x, y):
		return
	_select_instance(category, index)


func _apply_path_point_position_with_undo(
	index: int,
	old_x: float,
	old_y: float,
	new_x: float,
	new_y: float
) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Move PTH point", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_path_point_position", index, new_x, new_y)
		ur.add_undo_method(self, "_exec_path_point_position", index, old_x, old_y)
		ur.commit_action()
	else:
		_exec_path_point_position(index, new_x, new_y)


func _exec_path_point_position(index: int, x: float, y: float) -> void:
	if _path_document == null:
		return
	if not _path_document.set_point_position(index, x, y):
		return
	_select_path_point(index)


func _apply_path_connection_retarget_with_undo(
	connection_index: int,
	old_target: int,
	new_target: int
) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Retarget PTH connection", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_path_connection_retarget", connection_index, new_target)
		ur.add_undo_method(self, "_exec_path_connection_retarget", connection_index, old_target)
		ur.commit_action()
	else:
		_exec_path_connection_retarget(connection_index, new_target)


func _exec_path_connection_retarget(connection_index: int, target_index: int) -> void:
	if _path_document == null:
		return
	if not _path_document.set_connection_destination(connection_index, target_index):
		return
	_select_path_connection(connection_index)


func _apply_path_connection_add_with_undo(source_index: int, target_index: int) -> void:
	if _path_document == null:
		return
	var snapshot := _path_document.capture_topology_snapshot()
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Add PTH connection", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_path_connection_add", source_index, target_index)
		ur.add_undo_method(self, "_exec_path_point_restore_snapshot", snapshot)
		ur.commit_action()
	else:
		_exec_path_connection_add(source_index, target_index)


func _exec_path_connection_add(source_index: int, target_index: int) -> void:
	if _path_document == null:
		return
	var connection_index := _path_document.add_connection(source_index, target_index)
	if connection_index < 0:
		return
	_select_path_connection(connection_index)


func _apply_path_point_add_with_undo(x: float, y: float) -> void:
	if _path_document == null:
		return
	var index := _path_document.get_point_count()
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Add PTH point", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_path_point_add", x, y)
		ur.add_undo_method(self, "_exec_path_point_remove", index)
		ur.commit_action()
	else:
		_exec_path_point_add(x, y)


func _apply_path_point_remove_with_undo(index: int) -> void:
	if _path_document == null:
		return
	var snapshot := _path_document.capture_topology_snapshot()
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Remove PTH point", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_path_point_remove", index)
		ur.add_undo_method(self, "_exec_path_point_restore_snapshot", snapshot)
		ur.commit_action()
	else:
		_exec_path_point_remove(index)


func _exec_path_point_add(x: float, y: float) -> void:
	if _path_document == null:
		return
	var index := _path_document.add_point(x, y)
	if index < 0:
		return
	_select_path_point(index)


func _exec_path_point_remove(index: int) -> void:
	if _path_document == null:
		return
	if not _path_document.remove_point(index):
		return
	if _detail_label != null:
		_detail_label.text = ""
	_reset_overlay_selection()


func _exec_path_point_restore_snapshot(snapshot: Dictionary) -> void:
	if _path_document == null:
		return
	if not _path_document.restore_topology_snapshot(snapshot):
		return
	if _detail_label != null:
		_detail_label.text = ""
	_reset_overlay_selection()


func _apply_instance_bearing_with_undo(
	category: String,
	index: int,
	old_bearing: float,
	new_bearing: float
) -> void:
	var ur := _get_undo_redo()
	if ur != null:
		ur.create_action("Rotate GIT instance", UndoRedo.MERGE_DISABLE, self)
		ur.add_do_method(self, "_exec_instance_bearing", category, index, new_bearing)
		ur.add_undo_method(self, "_exec_instance_bearing", category, index, old_bearing)
		ur.commit_action()
	else:
		_exec_instance_bearing(category, index, new_bearing)


func _exec_instance_bearing(category: String, index: int, bearing: float) -> void:
	if _document == null:
		return
	if not _document.set_instance_bearing(category, index, bearing):
		return
	_select_instance(category, index)


func _connect_document_signal() -> void:
	if _document == null:
		return
	var changed := Callable(self, "_on_document_changed")
	if not _document.changed.is_connected(changed):
		_document.changed.connect(changed)


func _disconnect_document_signal() -> void:
	if _document == null:
		return
	var changed := Callable(self, "_on_document_changed")
	if _document.changed.is_connected(changed):
		_document.changed.disconnect(changed)


func _connect_path_document_signal() -> void:
	if _path_document == null:
		return
	var changed := Callable(self, "_on_path_document_changed")
	if not _path_document.changed.is_connected(changed):
		_path_document.changed.connect(changed)


func _disconnect_path_document_signal() -> void:
	if _path_document == null:
		return
	var changed := Callable(self, "_on_path_document_changed")
	if _path_document.changed.is_connected(changed):
		_path_document.changed.disconnect(changed)


func _on_document_changed() -> void:
	_git_dirty = true
	_refresh_dirty_state()
	_update_controller_dirty_state()
	_refresh_view()


func _on_path_document_changed() -> void:
	_pth_dirty = true
	_refresh_dirty_state()
	_update_controller_dirty_state()
	_refresh_view()


func _resolve_mutation_service() -> RefCounted:
	var controller := get_controller()
	if controller != null:
		var service = controller.get("mutation_service")
		if service != null:
			return service
	return KotorMutationService.new()


func _resolve_gamefs() -> RefCounted:
	var editor_state := get_editor_state()
	if editor_state == null:
		return null
	return editor_state.get("gamefs") as RefCounted


func _refresh_gamefs() -> void:
	var editor_state := get_editor_state()
	if editor_state != null and editor_state.has_method("refresh_gamefs"):
		editor_state.call("refresh_gamefs")


func _current_file_name() -> String:
	return _ensure_extension(_file_name, "git")


func _ensure_extension(path: String, extension: String) -> String:
	var normalized := path.strip_edges()
	if normalized.is_empty():
		return "module.%s" % extension
	if normalized.get_extension().to_lower() == extension:
		return normalized
	return "%s.%s" % [normalized.get_basename(), extension]


func _guess_loaded_file_name(label: String, fallback: String) -> String:
	var candidate := label.get_file()
	if candidate.is_empty():
		return fallback
	return candidate


func _mutation_message(result: Dictionary) -> String:
	if result.is_empty():
		return "Operation failed"
	return str(result.get("message", "Operation complete"))


func is_dirty() -> bool:
	return _dirty


func get_status_text() -> String:
	return _status_text


func _set_path_resource(resource: PTHResource) -> void:
	_disconnect_path_document_signal()
	_path_resource = resource
	_path_document = _path_resource.create_document() as KotorPTHDocument if _path_resource != null else null
	_connect_path_document_signal()


func _refresh_dirty_state() -> void:
	_dirty = _git_dirty or _pth_dirty
	_refresh_path_label()
	_emit_dirty_state(_dirty)
