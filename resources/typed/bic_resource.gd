@tool
extends "../gff_resource.gd"
class_name BICResource

const KotorBICDocument := preload("../documents/kotor_bic_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorBICDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorBICDocument).get_tag()


func get_first_name_text() -> String:
	return (create_document() as KotorBICDocument).get_first_name_text()


func get_last_name_text() -> String:
	return (create_document() as KotorBICDocument).get_last_name_text()


func get_player_name() -> String:
	return (create_document() as KotorBICDocument).get_player_name()


func _create_document():
	return KotorBICDocument.new().setup(file_type, gff_data, self)
