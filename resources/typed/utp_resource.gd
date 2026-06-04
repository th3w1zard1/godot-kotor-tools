@tool
extends "../gff_resource.gd"
class_name UTPResource

const KotorUTPDocument := preload("../documents/kotor_utp_document.gd")


func get_template_resref() -> String:
	return (create_document() as KotorUTPDocument).get_template_resref()


func get_tag() -> String:
	return (create_document() as KotorUTPDocument).get_tag()


func get_name_text() -> String:
	return (create_document() as KotorUTPDocument).get_name_text()


func get_conversation_resref() -> String:
	return (create_document() as KotorUTPDocument).get_conversation_resref()


func has_inventory() -> bool:
	return (create_document() as KotorUTPDocument).has_inventory()


func is_useable() -> bool:
	return (create_document() as KotorUTPDocument).is_useable()


func is_trap_enabled() -> bool:
	return (create_document() as KotorUTPDocument).is_trap_enabled()


func get_trap_type_id() -> int:
	return (create_document() as KotorUTPDocument).get_trap_type_id()


func is_trap_one_shot() -> bool:
	return (create_document() as KotorUTPDocument).is_trap_one_shot()


func is_trap_detectable() -> bool:
	return (create_document() as KotorUTPDocument).is_trap_detectable()


func get_trap_detect_dc() -> int:
	return (create_document() as KotorUTPDocument).get_trap_detect_dc()


func is_trap_disarmable() -> bool:
	return (create_document() as KotorUTPDocument).is_trap_disarmable()


func get_disarm_dc() -> int:
	return (create_document() as KotorUTPDocument).get_disarm_dc()


func get_key_name_resref() -> String:
	return (create_document() as KotorUTPDocument).get_key_name_resref()


func get_on_click_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_click_script()


func get_on_closed_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_closed_script()


func get_on_damaged_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_damaged_script()


func get_on_death_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_death_script()


func get_on_disarm_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_disarm_script()


func get_on_heartbeat_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_heartbeat_script()


func get_on_lock_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_lock_script()


func get_on_melee_attacked_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_melee_attacked_script()


func get_on_open_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_open_script()


func get_on_spell_cast_at_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_spell_cast_at_script()


func get_on_trap_triggered_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_trap_triggered_script()


func get_on_unlock_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_unlock_script()


func get_on_user_defined_script() -> String:
	return (create_document() as KotorUTPDocument).get_on_user_defined_script()


func _create_document():
	return KotorUTPDocument.new().setup(file_type, gff_data, self)
