@tool
extends "../gff_resource.gd"
class_name UTWResource

const KotorUTWDocument := preload("../documents/kotor_utw_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTWDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTWDocument).get_tag()


func get_linked_to() -> String:
	return (create_document() as KotorUTWDocument).get_linked_to()


func _create_document():
	return KotorUTWDocument.new().setup(file_type, gff_data, self)
