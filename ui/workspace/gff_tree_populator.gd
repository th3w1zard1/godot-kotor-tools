@tool
extends RefCounted
class_name GFFTreePopulator

const META_FIELD_PATH := &"field_path"

const TypedFieldHelpers := preload("../workspace/typed_field_helpers.gd")


static func populate(parent: TreeItem, data: Dictionary, path_prefix: Array = []) -> void:
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
				populate(item, val, path)
			TYPE_ARRAY:
				item.set_text(1, "<list[%d]>" % (val as Array).size())
				item.collapsed = true
				for i in (val as Array).size():
					var li := parent.get_tree().create_item(item)
					li.set_text(0, "[%d]" % i)
					var element_path: Array = path.duplicate()
					element_path.append(i)
					if typeof(val[i]) == TYPE_DICTIONARY:
						li.set_text(1, "<struct>")
						li.collapsed = true
						populate(li, val[i], element_path)
					else:
						_configure_scalar_leaf(li, val[i], element_path, str(key_variant))
			_:
				_configure_scalar_leaf(item, val, path, str(key_variant))


static func _configure_scalar_leaf(item: TreeItem, value: Variant, path: Array, field_name: String = "") -> void:
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
			if TypedFieldHelpers.is_resref_field(field_name):
				item.set_meta("is_resref", true)
			
			if TypedFieldHelpers.has_enum_hints(field_name):
				item.set_meta("enum_field_name", field_name)


static func _is_scalar_leaf(value: Variant) -> bool:
	return typeof(value) in [
		TYPE_STRING,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_BOOL,
	]

