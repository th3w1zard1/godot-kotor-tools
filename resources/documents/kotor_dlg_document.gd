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
	if struct_value.get(field_name, null) == value:
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


static func _truncate_preview(text: String, max_length: int = 64) -> String:
	var single_line := text.strip_edges().replace("\n", " ").replace("\r", " ")
	if single_line.length() <= max_length:
		return single_line
	return "%s…" % single_line.substr(0, max_length - 1)
