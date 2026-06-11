## Batch WAV sound conversion via PyKotor sound-convert CLI bridge.
class_name WavBatchConverter

const KotorMediaToolBridge := preload("../resources/scripts/kotor_media_tool_bridge.gd")


## Convert each `.wav` in a flat directory to a matching `{resref}_clean.wav` in-place.
static func batch_directory(
		dir_path: String,
		options: Dictionary = {}
) -> Dictionary:
	return batch_directory_to_output(dir_path, dir_path, options)


## Convert each `.wav` in `source_dir` and write `{resref}_clean.wav` into `output_dir`.
static func batch_directory_to_output(
		source_dir: String,
		output_dir: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var dry_run := bool(options.get("dry_run", false))
	var pykotor_cli_path := str(options.get("pykotor_cli_path", "")).strip_edges()
	var sound_type := str(options.get("sound_type", "SFX")).strip_edges().to_upper()
	var to_clean := bool(options.get("to_clean", true))

	if source_dir.is_empty() or not DirAccess.dir_exists_absolute(source_dir):
		return {"ok": false, "message": "Source directory not found: %s" % source_dir}
	if output_dir.is_empty() or not DirAccess.dir_exists_absolute(output_dir):
		return {"ok": false, "message": "Output directory not found: %s" % output_dir}

	var dir := DirAccess.open(source_dir)
	if dir == null:
		return {"ok": false, "message": "Failed to open source directory: %s" % source_dir}

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

		var wav_path := source_dir.path_join(entry_name)
		var output_path := _clean_output_path_for_resref(output_dir, resref)
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


## Convert one WAV file to a target output path via PyKotor sound-convert.
static func convert_file(
		wav_path: String,
		output_path: String,
		options: Dictionary = {}
) -> Dictionary:
	return _convert_single(
		wav_path,
		output_path,
		str(options.get("pykotor_cli_path", "")).strip_edges(),
		str(options.get("sound_type", "SFX")).strip_edges().to_upper(),
		bool(options.get("to_clean", true)),
		bool(options.get("dry_run", false))
	)


static func clean_output_path_for_resref(output_dir: String, resref: String) -> String:
	return _clean_output_path_for_resref(output_dir, resref)


static func format_report(result: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(str(result.get("summary", "Batch WAV convert finished.")))
	var generated: Array = result.get("generated", [])
	for raw_record in generated:
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = raw_record
		lines.append("%s → %s" % [
			str(record.get("resref", "")),
			str(record.get("output_path", "")).get_file(),
		])
	var failed: Array = result.get("failed", [])
	for raw_failure in failed:
		if typeof(raw_failure) != TYPE_DICTIONARY:
			continue
		var failure: Dictionary = raw_failure
		lines.append("FAILED %s: %s" % [
			str(failure.get("resref", "")),
			str(failure.get("message", "?")),
		])
	return "\n".join(lines)


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
	return _clean_output_path_for_resref(wav_path.get_base_dir(), wav_path.get_basename())


static func _clean_output_path_for_resref(output_dir: String, resref: String) -> String:
	return output_dir.path_join("%s_clean.wav" % resref)


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
