@tool
extends "../gff_resource.gd"
class_name IFOResource

const KotorIFODocument := preload("../documents/kotor_ifo_document.gd")


func get_module_name() -> String:
	return (create_document() as KotorIFODocument).get_module_name()


func get_module_tag() -> String:
	return (create_document() as KotorIFODocument).get_module_tag()


func get_module_resref() -> String:
	return (create_document() as KotorIFODocument).get_module_resref()


func get_starting_area_count() -> int:
	return (create_document() as KotorIFODocument).get_starting_area_count()


func get_starting_area_names() -> Array[String]:
	return (create_document() as KotorIFODocument).get_starting_area_names()


func get_on_load_script() -> String:
	return (create_document() as KotorIFODocument).get_on_load_script()


func get_on_heartbeat_script() -> String:
	return (create_document() as KotorIFODocument).get_on_heartbeat_script()


func _create_document():
	return KotorIFODocument.new().setup(file_type, gff_data, self)
