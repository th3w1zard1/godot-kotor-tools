@tool
extends "../gff_resource.gd"
class_name UTDResource

const KotorUTDDocument := preload("../documents/kotor_utd_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTDDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTDDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTDDocument).get_name_text()


func get_conversation_resref() -> String:
	return (create_document() as KotorUTDDocument).get_conversation_resref()


func is_static() -> bool:
	return (create_document() as KotorUTDDocument).is_static()


func is_plot() -> bool:
	return (create_document() as KotorUTDDocument).is_plot()


func _create_document():
	return KotorUTDDocument.new().setup(file_type, gff_data, self)
