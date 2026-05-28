@tool
extends "../gff_resource.gd"
class_name UTDResource

const KotorUTDDocument := preload("../documents/kotor_utd_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTDDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTDDocument).get_tag()


func get_conversation_resref() -> String:
	return (create_document() as KotorUTDDocument).get_conversation_resref()


func _create_document():
	return KotorUTDDocument.new().setup(file_type, gff_data, self)
