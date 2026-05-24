@tool
extends "../gff_resource.gd"
class_name GITResource

const KotorGITDocument := preload("../documents/kotor_git_document.gd")


func get_total_instance_count() -> int:
	return (create_document() as KotorGITDocument).get_total_instance_count()


func _create_document():
	return KotorGITDocument.new().setup(file_type, gff_data, self)
