@tool
extends "../gff_resource.gd"
class_name UTCResource

const KotorUTCDocument := preload("../documents/kotor_utc_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTCDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTCDocument).get_tag()


func get_first_name_text() -> String:
	return (create_document() as KotorUTCDocument).get_first_name_text()


func get_last_name_text() -> String:
	return (create_document() as KotorUTCDocument).get_last_name_text()


func get_name_text() -> String:
	return (create_document() as KotorUTCDocument).get_name_text()


func get_conversation_resref() -> String:
	return (create_document() as KotorUTCDocument).get_conversation_resref()


func get_on_spawn_script() -> String:
	return (create_document() as KotorUTCDocument).get_on_spawn_script()


func get_on_heartbeat_script() -> String:
	return (create_document() as KotorUTCDocument).get_on_heartbeat_script()


func get_on_notice_script() -> String:
	return (create_document() as KotorUTCDocument).get_on_notice_script()


func get_on_disturbed_script() -> String:
	return (create_document() as KotorUTCDocument).get_on_disturbed_script()


func _create_document():
	return KotorUTCDocument.new().setup(file_type, gff_data, self)
