@tool
extends "../gff_resource.gd"
class_name UTPResource

const KotorUTPDocument := preload("../documents/kotor_utp_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTPDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTPDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTPDocument).get_name_text()


func get_conversation_resref() -> String:
	return (create_document() as KotorUTPDocument).get_conversation_resref()


func has_inventory() -> bool:
	return (create_document() as KotorUTPDocument).has_inventory()


func is_useable() -> bool:
	return (create_document() as KotorUTPDocument).is_useable()


func _create_document():
	return KotorUTPDocument.new().setup(file_type, gff_data, self)
