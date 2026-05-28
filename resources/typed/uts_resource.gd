@tool
extends "../gff_resource.gd"
class_name UTSResource

const KotorUTSDocument := preload("../documents/kotor_uts_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTSDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTSDocument).get_tag()


func get_active_count() -> int:
	return (create_document() as KotorUTSDocument).get_active_count()


func _create_document():
	return KotorUTSDocument.new().setup(file_type, gff_data, self)
