@tool
extends "../gff_resource.gd"
class_name UTMResource

const KotorUTMDocument := preload("../documents/kotor_utm_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTMDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTMDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTMDocument).get_name_text()


func get_inventory_count() -> int:
	return (create_document() as KotorUTMDocument).get_inventory_count()


func get_markup_percent() -> int:
	return (create_document() as KotorUTMDocument).get_markup_percent()


func _create_document():
	return KotorUTMDocument.new().setup(file_type, gff_data, self)
