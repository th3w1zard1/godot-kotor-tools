## Batch WAV sound conversion via PyKotor sound-convert CLI bridge.
class_name WavBatchConverter

const KotorMediaToolBridge := preload("../resources/scripts/kotor_media_tool_bridge.gd")


## Convert each `.wav` in a flat directory to a matching `{resref}_clean.wav`.
static func batch_directory(
		dir_path: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var pykotor_cli_path := str(options.get("pykotor_cli_path", "")).strip_edges()
	var sound_type := str(options.get("sound_type", "SFX")).strip_edges().to_upper()
	var to_clean := bool(options.get("to_clean", true))

	if dir_path.is_empty() or not DirAccess.dir_exists_absolute(dir_path):
		return {"ok": false, "message": "Directory not found: %s" % dir_path}

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return {"ok": false, "message": "Failed to open directory: %s" % dir_path}

	dir.list_dir_begin()
	var generated: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var failed: Array[Dictionary] = []

	while true:
		var entry_name := dir.get_next()
		if entry_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if entry_name.get_extension().to_lower() != "wav":
			continue

		var resref := entry_name.get_basename()
		if resref.ends_with("_clean"):
			continue

		var wav_path := dir_path.path_join(entry_name)
		var output_path := _clean_output_path_for_wav(wav_path)
		if skip_existing and FileAccess.file_exists(output_path):
			skipped.append({
				"resref": resref,
				"wav_path": wav_path,
				"output_path": output_path,
				"reason": "exists",
			})
			continue

		var result := _convert_single(
			wav_path,
			output_path,
			pykotor_cli_path,
			sound_type,
			to_clean,
			dry_run
		)
		if not result.get("ok", false):
			failed.append({
				"resref": resref,
				"wav_path": wav_path,
				"output_path": output_path,
				"message": str(result.get("message", "Conversion failed")),
			})
			continue

		generated.append({
			"resref": resref,
			"wav_path": wav_path,
			"output_path": output_path,
			"sound_type": sound_type,
			"dry_run": dry_run,
		})

	dir.list_dir_end()

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func _convert_single(
		wav_path: String,
		output_path: String,
		pykotor_cli_path: String,
		sound_type: String,
		to_clean: bool,
		dry_run: bool
) -> Dictionary:
	var config := {
		"operation": KotorMediaToolBridge.Operation.SOUND_CONVERT,
		"input_path": wav_path,
		"output_path": output_path,
		"pykotor_cli_path": pykotor_cli_path,
		"sound_type": sound_type,
		"to_clean": to_clean,
		"dry_run": dry_run,
	}
	if dry_run:
		var built := KotorMediaToolBridge.build_command(config)
		if not built.get("ok", false):
			return {
				"ok": false,
				"message": _join_lines(built.get("errors", [])),
			}
		return {"ok": true, "message": "Command ready."}

	return KotorMediaToolBridge.run_sound_convert(
		wav_path,
		output_path,
		to_clean,
		sound_type,
		pykotor_cli_path
	)


static func _clean_output_path_for_wav(wav_path: String) -> String:
	return "%s_clean.wav" % wav_path.get_basename()


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Batch WAV convert: %d converted, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]


static func _join_lines(lines: Variant) -> String:
	if typeof(lines) != TYPE_ARRAY:
		return ""
	var packed := PackedStringArray()
	for line in lines as Array:
		packed.append(str(line))
	return "\n".join(packed)
