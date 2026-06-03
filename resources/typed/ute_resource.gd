@tool
extends "../gff_resource.gd"
class_name UTEResource

const KotorUTEDocument := preload("../documents/kotor_ute_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTEDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTEDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTEDocument).get_name_text()


func get_creature_count() -> int:
	return (create_document() as KotorUTEDocument).get_creature_count()


func is_respawning() -> bool:
	return (create_document() as KotorUTEDocument).is_respawning()


func _create_document():
	return KotorUTEDocument.new().setup(file_type, gff_data, self)
