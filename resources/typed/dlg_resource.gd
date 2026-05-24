@tool
extends "../gff_resource.gd"
class_name DLGResource

const KotorDLGDocument := preload("../documents/kotor_dlg_document.gd")


func get_entry_count() -> int:
	return (create_document() as KotorDLGDocument).get_entry_count()


func get_reply_count() -> int:
	return (create_document() as KotorDLGDocument).get_reply_count()


func _create_document():
	return KotorDLGDocument.new().setup(file_type, gff_data, self)
