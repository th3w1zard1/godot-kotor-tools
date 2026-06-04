@tool
extends "../gff_resource.gd"
class_name UTWResource

const KotorUTWDocument := preload("../documents/kotor_utw_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTWDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTWDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTWDocument).get_name_text()


func get_linked_to() -> String:
	return (create_document() as KotorUTWDocument).get_linked_to()


func has_map_note() -> bool:
	return (create_document() as KotorUTWDocument).has_map_note()


func get_map_note_text() -> String:
	return (create_document() as KotorUTWDocument).get_map_note_text()


func _create_document():
	return KotorUTWDocument.new().setup(file_type, gff_data, self)
