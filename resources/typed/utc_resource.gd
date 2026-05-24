@tool
extends "../gff_resource.gd"
class_name UTCResource

const KotorUTCDocument := preload("../documents/kotor_utc_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTCDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTCDocument).get_tag()


func get_conversation_resref() -> String:
	return (create_document() as KotorUTCDocument).get_conversation_resref()


func _create_document():
	return KotorUTCDocument.new().setup(file_type, gff_data, self)
