## Batch TGA/PNG to TPC conversion — native RGBA encode for folder workflows.
class_name TpcBatchConverter

const TPCReader := preload("tpc_reader.gd")
const TPCWriter := preload("tpc_writer.gd")

const SUPPORTED_EXTENSIONS := ["png", "tga"]


## Encode a single image file as uncompressed RGBA TPC bytes.
static func convert_from_image_file(
		image_path: String,
		alpha_test: float = 0.0
) -> Dictionary:
	if image_path.is_empty() or not FileAccess.file_exists(image_path):
		return {"ok": false, "message": "Image file not found: %s" % image_path}

	var extension := image_path.get_extension().to_lower()
	if extension not in SUPPORTED_EXTENSIONS:
		return {"ok": false, "message": "Unsupported image extension: .%s" % extension}

	var image := Image.new()
	var load_error := image.load(image_path)
	if load_error != OK:
		return {"ok": false, "message": "Failed to load image: %s" % image_path.get_file()}

	var bytes := TPCWriter.serialize_rgba(image, alpha_test)
	if bytes.is_empty():
		return {"ok": false, "message": "Failed to encode RGBA TPC from %s" % image_path.get_file()}

	var metadata := TPCReader.read_metadata(bytes)
	if not metadata.get("ok", false):
		return {"ok": false, "message": "Encoded TPC failed validation for %s" % image_path.get_file()}

	return {
		"ok": true,
		"bytes": bytes,
		"image_path": image_path,
		"tpc_path": _tpc_path_for_image(image_path),
		"width": int(metadata.get("width", 0)),
		"height": int(metadata.get("height", 0)),
	}


## Scan a flat directory for `.png` and `.tga` files and write matching `.tpc` files.
static func batch_directory(
		dir_path: String,
		options: Dictionary = {}
) -> Dictionary:
	var skip_existing := bool(options.get("skip_existing", true))
	var alpha_test := float(options.get("alpha_test", 0.0))

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
		var extension := entry_name.get_extension().to_lower()
		if extension not in SUPPORTED_EXTENSIONS:
			continue

		var image_path := dir_path.path_join(entry_name)
		var tpc_path := _tpc_path_for_image(image_path)
		if skip_existing and FileAccess.file_exists(tpc_path):
			skipped.append({"image_path": image_path, "tpc_path": tpc_path, "reason": "exists"})
			continue

		var result := convert_from_image_file(image_path, alpha_test)
		if not result.get("ok", false):
			failed.append({
				"image_path": image_path,
				"message": str(result.get("message", "Conversion failed")),
			})
			continue

		var write_error := _write_bytes(tpc_path, result.get("bytes", PackedByteArray()) as PackedByteArray)
		if write_error != OK:
			failed.append({
				"image_path": image_path,
				"tpc_path": tpc_path,
				"message": "Failed to write TPC (error %d)" % write_error,
			})
			continue

		generated.append({
			"image_path": image_path,
			"tpc_path": tpc_path,
			"width": int(result.get("width", 0)),
			"height": int(result.get("height", 0)),
		})

	dir.list_dir_end()

	return {
		"ok": failed.is_empty() or not generated.is_empty(),
		"generated": generated,
		"skipped": skipped,
		"failed": failed,
		"summary": _format_summary(generated.size(), skipped.size(), failed.size()),
	}


static func _tpc_path_for_image(image_path: String) -> String:
	return "%s.tpc" % image_path.get_basename()


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
	return "Batch TPC: %d generated, %d skipped, %d failed." % [
		generated_count,
		skipped_count,
		failed_count,
	]
