## Batch LIP generation from WAV files — minimal duration-aligned placeholders.
class_name LipBatchGenerator

const WavMetadata := preload("wav_metadata.gd")
const LIPParser := preload("lip_parser.gd")
const LIPWriter := preload("lip_writer.gd")

const DEFAULT_SHAPE := 0  # NEUTRAL


## Build LIP bytes from WAV bytes using duration metadata and placeholder keyframes.
static func generate_from_wav_bytes(
		wav_bytes: PackedByteArray,
		default_shape: int = DEFAULT_SHAPE
) -> Dictionary:
	var meta := WavMetadata.parse_bytes(wav_bytes)
	if not meta.get("ok", false):
		return {"ok": false, "message": str(meta.get("message", "Invalid WAV"))}

	var duration := float(meta.get("duration_seconds", 0.0))
	if duration <= 0.0:
		return {"ok": false, "message": "WAV has zero duration"}

	if not meta.get("playable_pcm", false):
		return {
			"ok": false,
			"message": "Batch LIP requires 16-bit PCM WAV (%s). Convert in WAV editor first."
					% meta.get("format_label", "?"),
		}

	var shape := clampi(default_shape, 0, LIPParser.SHAPE_COUNT - 1)
	var keyframes: Array[Dictionary] = [{"time": 0.0, "shape": shape}]
	if duration > 0.001:
		keyframes.append({"time": duration, "shape": shape})

	var lip_bytes := LIPWriter.serialize_keyframes(duration, keyframes)
	if lip_bytes.is_empty():
		return {"ok": false, "message": "Failed to serialize LIP"}

	return {
		"ok": true,
		"bytes": lip_bytes,
		"duration": duration,
		"shape": shape,
	}


## Generate LIP bytes from a WAV file on disk.
static func generate_from_wav_file(
		wav_path: String,
		default_shape: int = DEFAULT_SHAPE
) -> Dictionary:
	if wav_path.is_empty() or not FileAccess.file_exists(wav_path):
		return {"ok": false, "message": "WAV file not found: %s" % wav_path}

	var file := FileAccess.open(wav_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Failed to open WAV: %s" % wav_path.get_file()}

	var wav_bytes := file.get_buffer(file.get_length())
	file.close()
	var result := generate_from_wav_bytes(wav_bytes, default_shape)
	if not result.get("ok", false):
		result["wav_path"] = wav_path
		return result

	result["wav_path"] = wav_path
	result["lip_path"] = _lip_path_for_wav(wav_path)
	return result


## Scan a flat directory for `.wav` files and write matching `.lip` files.
static func batch_directory(
		dir_path: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var default_shape := int(options.get("default_shape", DEFAULT_SHAPE))

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

		var wav_path := dir_path.path_join(entry_name)
		var lip_path := _lip_path_for_wav(wav_path)
		if skip_existing and FileAccess.file_exists(lip_path):
			skipped.append({"wav_path": wav_path, "lip_path": lip_path, "reason": "exists"})
			continue

		var result := generate_from_wav_file(wav_path, default_shape)
		if not result.get("ok", false):
			failed.append({
				"wav_path": wav_path,
				"message": str(result.get("message", "Generation failed")),
			})
			continue

		var write_error := _write_bytes(lip_path, result.get("bytes", PackedByteArray()) as PackedByteArray)
		if write_error != OK:
			failed.append({
				"wav_path": wav_path,
				"lip_path": lip_path,
				"message": "Failed to write LIP (error %d)" % write_error,
			})
			continue

		generated.append({
			"wav_path": wav_path,
			"lip_path": lip_path,
			"duration": float(result.get("duration", 0.0)),
		})

	dir.list_dir_end()

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func _lip_path_for_wav(wav_path: String) -> String:
	return "%s.lip" % wav_path.get_basename()


static func _write_bytes(path: String, bytes: PackedByteArray) -> Error:
	if bytes.is_empty():
		return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	file.close()
	return OK


static func _format_summary(generated_count: int, skipped_count: int, failed_count: int) -> String:
	return "Batch LIP: %d generated, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
