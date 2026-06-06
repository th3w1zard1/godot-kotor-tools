@tool
extends "../gff_resource.gd"
class_name PTHResource

const KotorPTHDocument := preload("../documents/kotor_pth_document.gd")


func get_tag() -> String:
	return (create_document() as KotorPTHDocument).get_tag()


func get_point_field_name() -> String:
	return (create_document() as KotorPTHDocument).get_point_field_name()


func get_point_count() -> int:
	return (create_document() as KotorPTHDocument).get_point_count()


func get_point_records() -> Array[Dictionary]:
	return (create_document() as KotorPTHDocument).get_point_records()


func _create_document():
	return KotorPTHDocument.new().setup(file_type, gff_data, self)
