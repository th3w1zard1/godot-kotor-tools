@tool
extends "../gff_resource.gd"
class_name GITResource

const KotorGITDocument := preload("../documents/kotor_git_document.gd")


func get_total_instance_count() -> int:
	return (create_document() as KotorGITDocument).get_total_instance_count()


func get_instance_records() -> Array[Dictionary]:
	return (create_document() as KotorGITDocument).get_instance_records()


func get_category_counts() -> Dictionary:
	return (create_document() as KotorGITDocument).get_category_counts()


func get_layout_bounds(padding: float = 2.0) -> Rect2:
	return (create_document() as KotorGITDocument).get_layout_bounds(padding)


func find_instance_record(category: String, index: int) -> Dictionary:
	return (create_document() as KotorGITDocument).find_instance_record(category, index)


func set_instance_bearing(category: String, index: int, bearing: float) -> bool:
	return (create_document() as KotorGITDocument).set_instance_bearing(category, index, bearing)


func set_instance_position(
	category: String,
	index: int,
	x: float,
	y: float,
	z: Variant = null
) -> bool:
	return (create_document() as KotorGITDocument).set_instance_position(category, index, x, y, z)


func _create_document():
	return KotorGITDocument.new().setup(file_type, gff_data, self)
