@tool
extends "../gff_resource.gd"
class_name JRLResource

const KotorJRLDocument := preload("../documents/kotor_jrl_document.gd")


func get_name_text() -> String:
	return (create_document() as KotorJRLDocument).get_name_text()


func get_tag() -> String:
	return (create_document() as KotorJRLDocument).get_tag()


func get_entry_count() -> int:
	return (create_document() as KotorJRLDocument).get_entry_count()


func get_entry_ids() -> Array[int]:
	return (create_document() as KotorJRLDocument).get_entry_ids()


func _create_document():
	return KotorJRLDocument.new().setup(file_type, gff_data, self)
