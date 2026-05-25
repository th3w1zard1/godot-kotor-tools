@tool
extends RefCounted
class_name GFFTreePopulator

const META_FIELD_PATH := &"field_path"
const META_ARRAY_FIELD := &"array_field_name"
const META_ARRAY_INDEX := &"array_index"
const META_IS_STRUCT_ARRAY_ITEM := &"is_struct_array_item"
const META_IS_DLG_ARRAY_ITEM := &"is_dlg_array_item"  # Deprecated; use META_IS_STRUCT_ARRAY_ITEM

const TypedFieldHelpers := preload("../workspace/typed_field_helpers.gd")

# GFF struct array field names that support context menu operations and array editing.
# Includes DLG arrays (EntryList, ReplyList, StartingList) and other GFF types.
const EDITABLE_STRUCT_ARRAY_FIELDS := {
	# DLG (Dialogue) arrays
	"EntryList": true,
	"ReplyList": true,
	"StartingList": true,
	# UTC (Creature) arrays
	"CreatureActions": true,
	"itemList": true,
	"Inventory": true,
	"EquippedInventory": true,
	"SkillList": true,
	"FeatList": true,
	# UTP (Placeable) arrays
	"Scripts": true,
	"UTCInstanceList": true,
	# Generic struct arrays (Conditions, Links, etc.)
	"ConditionList": true,
	"OnCondition": true,  # Quest-like conditions
	"OnSuccess": true,    # Condition blocks
	"OnFailure": true,    # Condition blocks
}


static func populate(parent: TreeItem, data: Dictionary, path_prefix: Array = [], registry: RefCounted = null) -> void:
	for key_variant in data.keys():
		var val = data[key_variant]
		var path: Array = path_prefix.duplicate()
		path.append(key_variant)
		var item := parent.get_tree().create_item(parent)
		item.set_text(0, str(key_variant))
		match typeof(val):
			TYPE_DICTIONARY:
				item.set_text(1, "<struct>")
				item.collapsed = true
				populate(item, val, path, registry)
			TYPE_ARRAY:
				item.set_text(1, "<list[%d]>" % (val as Array).size())
				item.collapsed = true
				var array_field_name := str(key_variant)
				for i in (val as Array).size():
					var li := parent.get_tree().create_item(item)
					var index_label := "[%d]" % i
					if array_field_name == "SkillList" and registry != null and registry.has_method("get_skill_label"):
						var skill_label := String(registry.get_skill_label(i))
						if not skill_label.is_empty():
							index_label = "[%d] %s" % [i, skill_label]
					li.set_text(0, index_label)
					var element_path: Array = path.duplicate()
					element_path.append(i)
					if typeof(val[i]) == TYPE_DICTIONARY:
						li.set_text(1, "<struct>")
						li.collapsed = true
						# Mark struct array items for context menu and editing support.
						# Applies to DLG arrays (EntryList, ReplyList, etc.) and GFF struct arrays
						# (CreatureActions, Scripts, generic Conditions, etc.)
						if array_field_name in EDITABLE_STRUCT_ARRAY_FIELDS:
							li.set_meta(META_IS_STRUCT_ARRAY_ITEM, true)
							li.set_meta(META_IS_DLG_ARRAY_ITEM, true)  # Deprecated; kept for backwards compat
							li.set_meta(META_ARRAY_FIELD, array_field_name)
							li.set_meta(META_ARRAY_INDEX, i)
						populate(li, val[i], element_path, registry)
					else:
						_configure_scalar_leaf(li, val[i], element_path, array_field_name, registry)
			_:
				_configure_scalar_leaf(item, val, path, str(key_variant), registry)


static func _configure_scalar_leaf(item: TreeItem, value: Variant, path: Array, field_name: String = "", registry: RefCounted = null) -> void:
	if typeof(value) == TYPE_BOOL:
		item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
		item.set_checked(1, bool(value))
		item.set_editable(1, true)
		item.set_metadata(1, path)
		return
	item.set_text(1, str(value))
	if _is_scalar_leaf(value):
		item.set_metadata(1, path)
		item.set_editable(1, true)
		
		if not field_name.is_empty():
			if TypedFieldHelpers.is_item_resref_field(field_name, path):
				item.set_meta("is_item_resref", true)
			elif TypedFieldHelpers.is_resref_field(field_name):
				item.set_meta("is_resref", true)
			
			if TypedFieldHelpers.has_enum_hints(field_name, registry):
				item.set_meta("enum_field_name", field_name)
			if field_name == "Feat" and typeof(value) == TYPE_INT and registry != null:
				var feat_label := TypedFieldHelpers.get_enum_display_name(field_name, int(value), registry)
				if not feat_label.begins_with("Unknown"):
					item.set_text(1, "%d (%s)" % [int(value), feat_label])


static func _is_scalar_leaf(value: Variant) -> bool:
	return typeof(value) in [
		TYPE_STRING,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_BOOL,
	]

