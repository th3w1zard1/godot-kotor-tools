@tool
extends RefCounted
class_name GFFTreePopulator


static func populate(parent: TreeItem, data: Dictionary) -> void:
	for key: String in data:
		var val = data[key]
		var item := parent.get_tree().create_item(parent)
		item.set_text(0, key)
		match typeof(val):
			TYPE_DICTIONARY:
				item.set_text(1, "<struct>")
				item.collapsed = true
				populate(item, val)
			TYPE_ARRAY:
				item.set_text(1, "<list[%d]>" % (val as Array).size())
				item.collapsed = true
				for i in (val as Array).size():
					var li := parent.get_tree().create_item(item)
					li.set_text(0, "[%d]" % i)
					li.set_text(1, "<struct>")
					li.collapsed = true
					if typeof(val[i]) == TYPE_DICTIONARY:
						populate(li, val[i])
			_:
				item.set_text(1, str(val))
