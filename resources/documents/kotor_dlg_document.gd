@tool
extends "../kotor_gff_document.gd"
class_name KotorDLGDocument

const KIND_ENTRY := "entry"
const KIND_REPLY := "reply"
const KIND_START := "start"

const SCRIPT_FIELD_HINTS := {
	"active": true,
}


func get_tag() -> String:
	return get_string("Tag")


func get_entry_count() -> int:
	return get_struct_list("EntryList").size()


func get_reply_count() -> int:
	return get_struct_list("ReplyList").size()


func get_start_count() -> int:
	return get_struct_list("StartingList").size()


func get_display_name() -> String:
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Starting Nodes", get_start_count())
	_append_summary_line(lines, "Entries", get_entry_count())
	_append_summary_line(lines, "Replies", get_reply_count())
	_append_summary_line(lines, "Word Count", get_field("NumWords", get_field("WordCount", null)))
	return lines


func get_node_list(kind: String) -> Array[Dictionary]:
	match kind.to_lower():
		KIND_ENTRY:
			return get_struct_list("EntryList")
		KIND_REPLY:
			return get_struct_list("ReplyList")
		_:
			return []


func get_start_list() -> Array[Dictionary]:
	return get_struct_list("StartingList")


func get_node(kind: String, index: int) -> Dictionary:
	var nodes := get_node_list(kind)
	if index < 0 or index >= nodes.size():
		return {}
	return nodes[index]


func get_start(index: int) -> Dictionary:
	var starts := get_start_list()
	if index < 0 or index >= starts.size():
		return {}
	return starts[index]


func get_node_links(kind: String, index: int) -> Array[Dictionary]:
	var node := get_node(kind, index)
	if node.is_empty():
		return []
	return _get_link_list_for_struct(kind, node)


func get_link(kind: String, index: int, link_index: int) -> Dictionary:
	var links := get_node_links(kind, index)
	if link_index < 0 or link_index >= links.size():
		return {}
	return links[link_index]


func get_node_text(kind: String, index: int) -> String:
	return describe_locstring(get_node(kind, index).get("Text", {}), "")


func get_node_target_kind(kind: String) -> String:
	return KIND_REPLY if kind.to_lower() == KIND_ENTRY else KIND_ENTRY


func get_link_target_index(link: Dictionary) -> int:
	return int(link.get("Index", -1))


## Return tree-selection metadata for the node a link points to, or {} if invalid.
func get_link_target_metadata(owner_kind: String, owner_index: int, link_index: int) -> Dictionary:
	var link := get_link(owner_kind, owner_index, link_index)
	if link.is_empty():
		return {}
	var target_index := get_link_target_index(link)
	if target_index < 0:
		return {}
	var target_kind := get_link_target_kind(owner_kind)
	if target_index >= get_node_list(target_kind).size():
		return {}
	return {
		"kind": target_kind,
		"index": target_index,
	}


func get_link_target_kind(kind: String) -> String:
	return get_node_target_kind(kind)


const GRAPH_ENTRY_COLUMN_X := 40.0
const GRAPH_REPLY_COLUMN_X := 420.0
const GRAPH_ROW_HEIGHT := 120.0


func build_graph_node_id(kind: String, index: int) -> String:
	return "%s:%d" % [kind.to_lower(), index]


static func parse_graph_node_id(node_id: String) -> Dictionary:
	var parts := node_id.split(":")
	if parts.size() != 2:
		return {}
	var kind := str(parts[0]).to_lower()
	if kind != KIND_ENTRY and kind != KIND_REPLY:
		return {}
	var index := int(parts[1])
	if index < 0:
		return {}
	return {
		"kind": kind,
		"index": index,
	}


func build_graph_layout_metadata() -> Dictionary:
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []

	for entry_index in range(get_entry_count()):
		nodes.append({
			"id": build_graph_node_id(KIND_ENTRY, entry_index),
			"kind": KIND_ENTRY,
			"index": entry_index,
			"label": build_node_title(KIND_ENTRY, entry_index),
			"preview": build_node_preview(KIND_ENTRY, entry_index, ""),
			"pos": Vector2(GRAPH_ENTRY_COLUMN_X, entry_index * GRAPH_ROW_HEIGHT),
		})

	for reply_index in range(get_reply_count()):
		nodes.append({
			"id": build_graph_node_id(KIND_REPLY, reply_index),
			"kind": KIND_REPLY,
			"index": reply_index,
			"label": build_node_title(KIND_REPLY, reply_index),
			"preview": build_node_preview(KIND_REPLY, reply_index, ""),
			"pos": Vector2(GRAPH_REPLY_COLUMN_X, reply_index * GRAPH_ROW_HEIGHT),
		})

	for entry_index in range(get_entry_count()):
		for link_index in range(get_node_links(KIND_ENTRY, entry_index).size()):
			var target := get_link_target_metadata(KIND_ENTRY, entry_index, link_index)
			if target.is_empty():
				continue
			edges.append({
				"from_id": build_graph_node_id(KIND_ENTRY, entry_index),
				"to_id": build_graph_node_id(str(target.get("kind", "")), int(target.get("index", -1))),
				"link_index": link_index,
			})

	for reply_index in range(get_reply_count()):
		for link_index in range(get_node_links(KIND_REPLY, reply_index).size()):
			var target := get_link_target_metadata(KIND_REPLY, reply_index, link_index)
			if target.is_empty():
				continue
			edges.append({
				"from_id": build_graph_node_id(KIND_REPLY, reply_index),
				"to_id": build_graph_node_id(str(target.get("kind", "")), int(target.get("index", -1))),
				"link_index": link_index,
			})

	return {
		"nodes": nodes,
		"edges": edges,
	}


func build_node_title(kind: String, index: int) -> String:
	var label := "Entry" if kind.to_lower() == KIND_ENTRY else "Reply"
	return "%s %d" % [label, index]


func build_node_preview(kind: String, index: int, fallback: String = "") -> String:
	var text := get_node_text(kind, index).strip_edges()
	if text.is_empty():
		var node := get_node(kind, index)
		text = String(node.get("Comment", node.get("Speaker", fallback))).strip_edges()
	if text.is_empty():
		return fallback
	return _truncate_preview(text)


static func create_default_locstring() -> Dictionary:
	return {
		"strref": 0xFFFFFFFF,
		"strings": {},
	}


static func create_default_link_struct(target_index: int = 0) -> Dictionary:
	return {
		"Index": target_index,
		"Comment": "",
		"Active": "",
		"IsChild": 0,
	}


static func create_default_entry_struct() -> Dictionary:
	return {
		"Text": create_default_locstring(),
		"RepliesList": [],
	}


static func create_default_reply_struct() -> Dictionary:
	return {
		"Text": create_default_locstring(),
		"EntriesList": [],
	}


static func create_default_start_struct(entry_index: int = 0) -> Dictionary:
	return {
		"Index": entry_index,
	}


func add_entry() -> int:
	var index := get_entry_count()
	if not insert_struct_at_array("EntryList", index, create_default_entry_struct()):
		return -1
	return index


func add_reply() -> int:
	var index := get_reply_count()
	if not insert_struct_at_array("ReplyList", index, create_default_reply_struct()):
		return -1
	return index


func add_start(entry_index: int = 0) -> int:
	var index := get_start_count()
	if not insert_struct_at_array("StartingList", index, create_default_start_struct(entry_index)):
		return -1
	return index


func remove_start(start_index: int) -> bool:
	return remove_struct_from_array("StartingList", start_index)


func remove_entry(entry_index: int) -> bool:
	if entry_index < 0 or entry_index >= get_entry_count():
		return false
	_repair_indices_after_node_removal(KIND_ENTRY, entry_index)
	return remove_struct_from_array("EntryList", entry_index)


func remove_reply(reply_index: int) -> bool:
	if reply_index < 0 or reply_index >= get_reply_count():
		return false
	_repair_indices_after_node_removal(KIND_REPLY, reply_index)
	return remove_struct_from_array("ReplyList", reply_index)


func remove_node(kind: String, index: int) -> bool:
	match kind.to_lower():
		KIND_ENTRY:
			return remove_entry(index)
		KIND_REPLY:
			return remove_reply(index)
		_:
			return false


func remove_all_references_to_node(target_kind: String, target_index: int) -> int:
	var removed_count := 0
	if target_kind.to_lower() == KIND_ENTRY:
		var starts := get_start_list()
		for start_index in range(starts.size() - 1, -1, -1):
			if int(starts[start_index].get("Index", -1)) == target_index:
				if remove_struct_from_array("StartingList", start_index):
					removed_count += 1
		removed_count += _remove_incoming_links_to_target(KIND_REPLY, "EntriesList", target_index)
	else:
		removed_count += _remove_incoming_links_to_target(KIND_ENTRY, "RepliesList", target_index)
	return removed_count


func find_orphaned_nodes() -> Array[Dictionary]:
	var orphans: Array[Dictionary] = []
	for entry_index in range(get_entry_count()):
		if _incoming_link_count(KIND_ENTRY, entry_index) == 0:
			orphans.append({"kind": KIND_ENTRY, "index": entry_index})
	for reply_index in range(get_reply_count()):
		if _incoming_link_count(KIND_REPLY, reply_index) == 0:
			orphans.append({"kind": KIND_REPLY, "index": reply_index})
	return orphans


func find_linkable_orphans_for_owner(owner_kind: String) -> Array[Dictionary]:
	var normalized_owner := owner_kind.to_lower()
	if normalized_owner != KIND_ENTRY and normalized_owner != KIND_REPLY:
		return []
	var target_kind := get_link_target_kind(normalized_owner)
	var linkable: Array[Dictionary] = []
	for orphan in find_orphaned_nodes():
		if str(orphan.get("kind", "")) == target_kind:
			linkable.append(orphan)
	return linkable


func can_link_orphan_to_owner(owner_kind: String, orphan_kind: String) -> bool:
	var normalized_owner := owner_kind.to_lower()
	if normalized_owner != KIND_ENTRY and normalized_owner != KIND_REPLY:
		return false
	return get_link_target_kind(normalized_owner) == orphan_kind.to_lower()


func add_node_link(
		owner_kind: String,
		owner_index: int,
		target_kind: String,
		target_index: int
) -> bool:
	var normalized_owner := owner_kind.to_lower()
	var normalized_target := target_kind.to_lower()
	if normalized_owner != KIND_ENTRY and normalized_owner != KIND_REPLY:
		return false
	if get_link_target_kind(normalized_owner) != normalized_target:
		return false
	var owner := get_node(normalized_owner, owner_index)
	if owner.is_empty():
		return false
	if target_index < 0 or target_index >= get_node_list(normalized_target).size():
		return false
	var link_field := "RepliesList" if normalized_owner == KIND_ENTRY else "EntriesList"
	var links_raw = owner.get(link_field, [])
	var links: Array = links_raw if typeof(links_raw) == TYPE_ARRAY else []
	links.append(create_default_link_struct(target_index))
	owner[link_field] = links
	mark_changed()
	return true


func restore_link_to_orphan(
		owner_kind: String,
		owner_index: int,
		target_kind: String,
		target_index: int
) -> bool:
	return add_node_link(owner_kind, owner_index, target_kind, target_index)


func capture_topology_snapshot() -> Dictionary:
	return {
		"EntryList": _duplicate_array_of_dicts(get_struct_list_array("EntryList")),
		"ReplyList": _duplicate_array_of_dicts(get_struct_list_array("ReplyList")),
		"StartingList": _duplicate_array_of_dicts(get_struct_list_array("StartingList")),
	}


func restore_topology_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false
	var root := get_root()
	root["EntryList"] = _duplicate_array_of_dicts(snapshot.get("EntryList", []))
	root["ReplyList"] = _duplicate_array_of_dicts(snapshot.get("ReplyList", []))
	root["StartingList"] = _duplicate_array_of_dicts(snapshot.get("StartingList", []))
	mark_changed()
	return true


func build_link_preview(kind: String, index: int, link_index: int) -> String:
	var link := get_link(kind, index, link_index)
	if link.is_empty():
		return ""
	var parts: Array[String] = []
	var script_name := String(link.get("Active", "")).strip_edges()
	if not script_name.is_empty():
		parts.append("if %s" % script_name)
	var comment := String(link.get("LinkComment", link.get("Comment", ""))).strip_edges()
	if not comment.is_empty():
		parts.append(_truncate_preview(comment, 48))
	return join_non_empty(parts, " — ")


func set_struct_field(struct_value: Dictionary, field_name: String, value: Variant) -> bool:
	if struct_value.is_empty():
		return false
	var current: Variant = struct_value.get(field_name, null)
	if typeof(current) == typeof(value) and current == value:
		return false
	struct_value[field_name] = value
	mark_changed()
	return true


func set_struct_locstring_text(struct_value: Dictionary, field_name: String, text: String, language_id: int = 0) -> bool:
	if struct_value.is_empty():
		return false
	var locstring = struct_value.get(field_name, {})
	if typeof(locstring) != TYPE_DICTIONARY:
		locstring = {
			"strref": 0xFFFFFFFF,
			"strings": {},
		}
	var strings: Dictionary = locstring.get("strings", {})
	var normalized := text.strip_edges()
	if normalized.is_empty():
		strings.erase(language_id)
	else:
		if String(strings.get(language_id, "")) == normalized:
			return false
		strings[language_id] = normalized
	locstring["strings"] = strings
	struct_value[field_name] = locstring
	mark_changed()
	return true


func validate(gamefs: RefCounted = null) -> Array[String]:
	var issues: Array[String] = []
	var entries := get_node_list(KIND_ENTRY)
	var replies := get_node_list(KIND_REPLY)
	var starts := get_start_list()

	for start_index in range(starts.size()):
		var start := starts[start_index]
		var target := int(start.get("Index", -1))
		if target < 0 or target >= entries.size():
			issues.append("Start %d points to missing Entry %d." % [start_index, target])
		_validate_script_fields(start, "Start %d" % start_index, issues, gamefs)

	for entry_index in range(entries.size()):
		var entry := entries[entry_index]
		_validate_link_targets(KIND_ENTRY, entry_index, _get_link_list_for_struct(KIND_ENTRY, entry), replies.size(), issues, gamefs)
		_validate_script_fields(entry, "Entry %d" % entry_index, issues, gamefs)

	for reply_index in range(replies.size()):
		var reply := replies[reply_index]
		_validate_link_targets(KIND_REPLY, reply_index, _get_link_list_for_struct(KIND_REPLY, reply), entries.size(), issues, gamefs)
		_validate_script_fields(reply, "Reply %d" % reply_index, issues, gamefs)

	return issues


func build_validation_report(gamefs: RefCounted = null) -> String:
	var issues := validate(gamefs)
	if issues.is_empty():
		return "Dialogue validation passed.\n- Start list indices resolve.\n- Link targets resolve.\n- Referenced scripts found where possible."
	return "Dialogue validation issues:\n- %s" % "\n- ".join(issues)


static func is_script_field(field_name: String) -> bool:
	var lower := field_name.strip_edges().to_lower()
	return lower.contains("script") or SCRIPT_FIELD_HINTS.has(lower)


func _get_link_list_for_struct(kind: String, struct_value: Dictionary) -> Array[Dictionary]:
	var field_name := "RepliesList" if kind.to_lower() == KIND_ENTRY else "EntriesList"
	var links: Array[Dictionary] = []
	var raw_value = struct_value.get(field_name, [])
	if typeof(raw_value) != TYPE_ARRAY:
		return links
	for entry in raw_value:
		if typeof(entry) == TYPE_DICTIONARY:
			links.append(entry)
	return links


func _validate_link_targets(
		kind: String,
		index: int,
		links: Array[Dictionary],
		target_count: int,
		issues: Array[String],
		gamefs: RefCounted
) -> void:
	for link_index in range(links.size()):
		var link := links[link_index]
		var target := int(link.get("Index", -1))
		if target < 0 or target >= target_count:
			issues.append("%s %d link %d points to missing %s %d." % [
				"Entry" if kind == KIND_ENTRY else "Reply",
				index,
				link_index,
				"Reply" if kind == KIND_ENTRY else "Entry",
				target,
			])
		_validate_script_fields(link, "%s %d link %d" % [
			"Entry" if kind == KIND_ENTRY else "Reply",
			index,
			link_index,
		], issues, gamefs)


func _validate_script_fields(struct_value: Dictionary, context: String, issues: Array[String], gamefs: RefCounted) -> void:
	for key in struct_value.keys():
		var field_name := str(key)
		if not is_script_field(field_name):
			continue
		var script_name := String(struct_value.get(field_name, "")).strip_edges()
		if script_name.is_empty():
			continue
		if script_name.length() > 16:
			issues.append("%s %s exceeds the 16-character resref limit." % [context, field_name])
		if gamefs == null or not gamefs.has_method("resolve_resource"):
			continue
		var has_source := not (gamefs.call("resolve_resource", script_name, "nss") as Dictionary).is_empty()
		var has_binary := not (gamefs.call("resolve_resource", script_name, "ncs") as Dictionary).is_empty()
		if not has_source and not has_binary:
			issues.append("%s %s references missing script %s." % [context, field_name, script_name])


func _repair_indices_after_node_removal(removed_kind: String, removed_index: int) -> void:
	if removed_kind.to_lower() == KIND_ENTRY:
		_repair_start_list_indices(removed_index)
		_repair_link_lists_for_target(KIND_REPLY, "EntriesList", removed_index)
	elif removed_kind.to_lower() == KIND_REPLY:
		_repair_link_lists_for_target(KIND_ENTRY, "RepliesList", removed_index)


func _repair_start_list_indices(removed_entry_index: int) -> void:
	var starts := get_start_list()
	for start_index in range(starts.size() - 1, -1, -1):
		var entry_index := int(starts[start_index].get("Index", -1))
		if entry_index == removed_entry_index:
			remove_struct_from_array("StartingList", start_index)
		elif entry_index > removed_entry_index:
			starts[start_index]["Index"] = entry_index - 1
			mark_changed()


func _repair_link_lists_for_target(owner_kind: String, link_field: String, removed_target_index: int) -> void:
	var owners := get_node_list(owner_kind)
	for owner_index in range(owners.size()):
		var owner := owners[owner_index]
		var links_raw = owner.get(link_field, [])
		if typeof(links_raw) != TYPE_ARRAY:
			continue
		var links := links_raw as Array
		var changed := false
		for link_index in range(links.size() - 1, -1, -1):
			var link: Variant = links[link_index]
			if typeof(link) != TYPE_DICTIONARY:
				continue
			var target_index := int((link as Dictionary).get("Index", -1))
			if target_index == removed_target_index:
				links.remove_at(link_index)
				changed = true
			elif target_index > removed_target_index:
				(link as Dictionary)["Index"] = target_index - 1
				changed = true
		if changed:
			owner[link_field] = links
			mark_changed()


func _remove_incoming_links_to_target(owner_kind: String, link_field: String, target_index: int) -> int:
	var removed_count := 0
	var owners := get_node_list(owner_kind)
	for owner_index in range(owners.size()):
		var owner := owners[owner_index]
		var links_raw = owner.get(link_field, [])
		if typeof(links_raw) != TYPE_ARRAY:
			continue
		var links := links_raw as Array
		for link_index in range(links.size() - 1, -1, -1):
			var link: Variant = links[link_index]
			if typeof(link) != TYPE_DICTIONARY:
				continue
			if int((link as Dictionary).get("Index", -1)) == target_index:
				links.remove_at(link_index)
				removed_count += 1
				owner[link_field] = links
				mark_changed()
	return removed_count


func _incoming_link_count(target_kind: String, target_index: int) -> int:
	var count := 0
	if target_kind.to_lower() == KIND_ENTRY:
		for start in get_start_list():
			if int(start.get("Index", -1)) == target_index:
				count += 1
		for reply_index in range(get_reply_count()):
			for link in get_node_links(KIND_REPLY, reply_index):
				if int(link.get("Index", -1)) == target_index:
					count += 1
	else:
		for entry_index in range(get_entry_count()):
			for link in get_node_links(KIND_ENTRY, entry_index):
				if int(link.get("Index", -1)) == target_index:
					count += 1
	return count


static func _duplicate_array_of_dicts(source: Array) -> Array:
	var copy: Array = []
	for item in source:
		if typeof(item) == TYPE_DICTIONARY:
			copy.append((item as Dictionary).duplicate(true))
		else:
			copy.append(item)
	return copy


static func _truncate_preview(text: String, max_length: int = 64) -> String:
	var single_line := text.strip_edges().replace("\n", " ").replace("\r", " ")
	if single_line.length() <= max_length:
		return single_line
	return "%s…" % single_line.substr(0, max_length - 1)
