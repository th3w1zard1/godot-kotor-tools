@tool
extends "../gff_resource.gd"
class_name FACResource

const KotorFACDocument := preload("../documents/kotor_fac_document.gd")


func get_label() -> String:
	return (create_document() as KotorFACDocument).get_label()


func get_tag() -> String:
	return (create_document() as KotorFACDocument).get_tag()


func get_appearance_count() -> int:
	return (create_document() as KotorFACDocument).get_appearance_count()


func _create_document():
	return KotorFACDocument.new().setup(file_type, gff_data, self)
