@tool
extends "../gff_resource.gd"
class_name AREResource

const KotorAREDocument := preload("../documents/kotor_are_document.gd")


func get_area_name() -> String:
	return (create_document() as KotorAREDocument).get_area_name()


func get_tag() -> String:
	return (create_document() as KotorAREDocument).get_tag()


func _create_document():
	return KotorAREDocument.new().setup(file_type, gff_data, self)
