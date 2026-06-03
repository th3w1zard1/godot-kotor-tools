@tool
extends "../gff_resource.gd"
class_name UTIResource

const KotorUTIDocument := preload("../documents/kotor_uti_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTIDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTIDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTIDocument).get_name_text()


func get_base_item_id() -> int:
	return (create_document() as KotorUTIDocument).get_base_item_id()


func get_stack_size() -> int:
	return (create_document() as KotorUTIDocument).get_stack_size()


func _create_document():
	return KotorUTIDocument.new().setup(file_type, gff_data, self)
