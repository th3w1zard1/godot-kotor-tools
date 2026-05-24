@tool
extends "../gff_resource.gd"
class_name IFOResource

const KotorIFODocument := preload("../documents/kotor_ifo_document.gd")


func get_module_name() -> String:
	return (create_document() as KotorIFODocument).get_module_name()


func get_module_resref() -> String:
	return (create_document() as KotorIFODocument).get_module_resref()


func _create_document():
	return KotorIFODocument.new().setup(file_type, gff_data, self)
