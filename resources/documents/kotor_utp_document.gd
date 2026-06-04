@tool
extends "../kotor_gff_document.gd"
class_name KotorUTPDocument


func get_template_resref() -> String:
	return get_resref("TemplateResRef")


func get_tag() -> String:
	return get_string("Tag")


func get_name_text() -> String:
	return get_locstring_text("LocName")


func get_conversation_resref() -> String:
	return get_resref("Conversation")


func has_inventory() -> bool:
	return get_bool("HasInventory")


func is_useable() -> bool:
	return get_bool("Useable")


func is_trap_enabled() -> bool:
	return get_bool("TrapFlag")


func get_trap_type_id() -> int:
	return get_int("TrapType", -1)


func is_trap_one_shot() -> bool:
	return get_bool("TrapOneShot")


func is_trap_detectable() -> bool:
	return get_bool("TrapDetectable")


func get_trap_detect_dc() -> int:
	return get_int("TrapDetectDC", 0)


func is_trap_disarmable() -> bool:
	return get_bool("TrapDisarmable")


func get_disarm_dc() -> int:
	return get_int("DisarmDC", 0)


func get_key_name_resref() -> String:
	return get_resref("KeyName")


func get_on_click_script() -> String:
	return get_script_resref("OnClick")


func get_on_closed_script() -> String:
	return get_script_resref("OnClosed")


func get_on_damaged_script() -> String:
	return get_script_resref("OnDamaged")


func get_on_death_script() -> String:
	return get_script_resref("OnDeath")


func get_on_disarm_script() -> String:
	return get_script_resref("OnDisarm")


func get_on_heartbeat_script() -> String:
	return get_script_resref("OnHeartbeat")


func get_on_lock_script() -> String:
	return get_script_resref("OnLock")


func get_on_melee_attacked_script() -> String:
	return get_script_resref("OnMeleeAttacked")


func get_on_open_script() -> String:
	return get_script_resref("OnOpen")


func get_on_spell_cast_at_script() -> String:
	return get_script_resref("OnSpellCastAt")


func get_on_trap_triggered_script() -> String:
	return get_script_resref("OnTrapTriggered")


func get_on_unlock_script() -> String:
	return get_script_resref("OnUnlock")


func get_on_user_defined_script() -> String:
	return get_script_resref("OnUserDefined")


func get_display_name() -> String:
	var name := get_name_text()
	if not name.is_empty():
		return name
	var template := get_template_resref()
	if not template.is_empty():
		return template
	return get_tag() if not get_tag().is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_name_text())
	_append_summary_line(lines, "Template", get_template_resref())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Conversation", get_conversation_resref())
	_append_summary_line(lines, "Has Inventory", has_inventory())
	_append_summary_line(lines, "Useable", is_useable())
	append_trap_scalar_summary_lines(lines)
	append_script_hook_summary_lines(lines)
	return lines
