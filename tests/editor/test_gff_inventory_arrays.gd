@tool
extends SceneTree

const UTCResource := preload("../../resources/typed/utc_resource.gd")
const UTPResource := preload("../../resources/typed/utp_resource.gd")
const TypedFieldHelpers := preload("../../ui/workspace/typed_field_helpers.gd")
const GFFTreePopulator := preload("../../ui/workspace/gff_tree_populator.gd")

const INVENTORY_DEFAULT := {
	"InventoryRes": "",
	"Dropable": 1,
	"Infinite": 0,
	"Recharge": 0,
}


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_editable_array_registration()
	_test_item_resref_paths()
	_test_itemlist_insert_defaults()
	_test_inventory_insert_remove()
	_test_equipped_inventory_reorder()
	print("✓ GFF inventory array tests passed")
	quit()


func _test_editable_array_registration() -> void:
	assert(GFFTreePopulator.EDITABLE_STRUCT_ARRAY_FIELDS.has("itemList"))
	assert(GFFTreePopulator.EDITABLE_STRUCT_ARRAY_FIELDS.has("Inventory"))
	assert(GFFTreePopulator.EDITABLE_STRUCT_ARRAY_FIELDS.has("EquippedInventory"))
	print("✓ Editable inventory arrays registered")


func _test_item_resref_paths() -> void:
	assert(TypedFieldHelpers.is_item_resref_field("InventoryRes", ["Inventory", 0]))
	assert(TypedFieldHelpers.is_item_resref_field("InventoryRes", ["EquippedInventory", 1]))
	assert(TypedFieldHelpers.is_item_resref_field("ResRef", ["Inventory", 0]))
	var warning := TypedFieldHelpers.get_validation_warning("InventoryRes", "")
	assert(warning.contains("InventoryRes"))
	print("✓ Inventory item resref paths passed")


func _test_itemlist_insert_defaults() -> void:
	var resource := _build_creature_with_itemlist()
	var document = resource.create_document()
	var new_item := INVENTORY_DEFAULT.duplicate()
	new_item["InventoryRes"] = "new_item"
	document.insert_struct_at_array("itemList", 0, new_item)
	var items := document.get_field("itemList") as Array
	assert(items.size() == 2)
	assert(items[0].get("InventoryRes") == "new_item")
	assert(items[0].get("Dropable") == 1)
	print("✓ itemList insert passed")


func _test_inventory_insert_remove() -> void:
	var resource := _build_placeable_with_inventory()
	var document = resource.create_document()
	var initial_size := (document.get_field("Inventory") as Array).size()
	document.insert_struct_at_array("Inventory", initial_size, INVENTORY_DEFAULT.duplicate())
	assert((document.get_field("Inventory") as Array).size() == initial_size + 1)
	document.remove_struct_from_array("Inventory", 0)
	assert((document.get_field("Inventory") as Array).size() == initial_size)
	print("✓ Inventory insert/remove passed")


func _test_equipped_inventory_reorder() -> void:
	var resource := _build_creature_with_equipped()
	var document = resource.create_document()
	var items := document.get_field("EquippedInventory") as Array
	var first_res := String((items[0] as Dictionary).get("InventoryRes", ""))
	var second_res := String((items[1] as Dictionary).get("InventoryRes", ""))
	document.reorder_array_item("EquippedInventory", 0, 1)
	var reordered := document.get_field("EquippedInventory") as Array
	assert(reordered[0].get("InventoryRes") == second_res)
	assert(reordered[1].get("InventoryRes") == first_res)
	print("✓ EquippedInventory reorder passed")


func _build_creature_with_itemlist() -> UTCResource:
	var resource := UTCResource.new()
	resource.file_type = "UTC "
	resource.gff_data = {
		"Tag": "inv_creature",
		"itemList": [
			{"InventoryRes": "existing_item", "Dropable": 1, "Infinite": 0, "Recharge": 0},
		],
	}
	return resource


func _build_placeable_with_inventory() -> UTPResource:
	var resource := UTPResource.new()
	resource.file_type = "UTP "
	resource.gff_data = {
		"Tag": "inv_placeable",
		"Inventory": [
			{"InventoryRes": "loot_a", "Dropable": 1, "Infinite": 0, "Recharge": 0},
		],
	}
	return resource


func _build_creature_with_equipped() -> UTCResource:
	var resource := UTCResource.new()
	resource.file_type = "UTC "
	resource.gff_data = {
		"Tag": "equipped_creature",
		"EquippedInventory": [
			{"InventoryRes": "slot_a", "Dropable": 0, "Infinite": 0, "Recharge": 0},
			{"InventoryRes": "slot_b", "Dropable": 0, "Infinite": 0, "Recharge": 0},
		],
	}
	return resource
