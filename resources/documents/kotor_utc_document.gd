@tool
extends "../kotor_gff_document.gd"
class_name KotorUTCDocument


func get_template_resref() -> String:
	return get_resref("TemplateResRef")


func get_tag() -> String:
	return get_string("Tag")


func get_first_name_text() -> String:
	return get_locstring_text("FirstName")


func get_last_name_text() -> String:
	return get_locstring_text("LastName")


func get_name_text() -> String:
	return join_non_empty([
		get_first_name_text(),
		get_last_name_text(),
	])


func get_conversation_resref() -> String:
	return get_resref("Conversation")


func get_on_spawn_script() -> String:
	return get_resref("ScriptSpawn")


func get_on_heartbeat_script() -> String:
	return get_resref("ScriptHeartbeat")


func get_on_notice_script() -> String:
	return get_resref("ScriptOnNotice")


func get_on_disturbed_script() -> String:
	return get_resref("ScriptDisturbed")


func get_on_attacked_script() -> String:
	return get_resref("ScriptAttacked")


func get_on_damaged_script() -> String:
	return get_resref("ScriptDamaged")


func get_on_death_script() -> String:
	return get_resref("ScriptDeath")


func get_on_spell_at_script() -> String:
	return get_resref("ScriptSpellAt")


func get_on_dialogue_script() -> String:
	return get_resref("ScriptDialogue")


func get_on_end_dialogue_script() -> String:
	return get_resref("ScriptEndDialogu")


func get_on_end_round_script() -> String:
	return get_resref("ScriptEndRound")


func get_on_rested_script() -> String:
	return get_resref("ScriptRested")


func get_on_blocked_script() -> String:
	return get_resref("ScriptOnBlocked")


func get_on_user_defined_script() -> String:
	return get_resref("ScriptUserDefine")


func get_display_name() -> String:
	var name := get_name_text()
	if not name.is_empty():
		return name
	var template := get_template_resref()
	if not template.is_empty():
		return template
	var tag := get_tag()
	return tag if not tag.is_empty() else super.get_display_name()


func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	_append_summary_line(lines, "Type", get_type_label())
	_append_summary_line(lines, "Name", get_name_text())
	_append_summary_line(lines, "Template", get_template_resref())
	_append_summary_line(lines, "Tag", get_tag())
	_append_summary_line(lines, "Conversation", get_conversation_resref())
	_append_summary_line(lines, "On Spawn", get_on_spawn_script())
	_append_summary_line(lines, "On Heartbeat", get_on_heartbeat_script())
	append_enum_summary_line(lines, "Appearance_Type", "Appearance")
	_append_summary_line(lines, "Challenge Rating", get_field("ChallengeRating", null))
	append_script_hook_summary_lines(lines)
	return lines
