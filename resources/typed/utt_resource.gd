@tool
extends "../gff_resource.gd"
class_name UTTResource

const KotorUTTDocument := preload("../documents/kotor_utt_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTTDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTTDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTTDocument).get_name_text()


func get_trap_count() -> int:
	return (create_document() as KotorUTTDocument).get_trap_count()


func is_auto_remove_key_enabled() -> bool:
	return (create_document() as KotorUTTDocument).is_auto_remove_key_enabled()


func _create_document():
	return KotorUTTDocument.new().setup(file_type, gff_data, self)
