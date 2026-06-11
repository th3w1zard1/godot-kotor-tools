## Flat and recursive directory file listing for batch tooling.
class_name BatchDirectoryScanner


static func list_files(
		root_dir: String,
		extensions: PackedStringArray,
		recursive: bool = false
) -> Array[String]:
	if root_dir.is_empty() or not DirAccess.dir_exists_absolute(root_dir):
		return []

	var normalized_exts: Array[String] = []
	for extension in extensions:
		var normalized := extension.to_lower().trim_prefix(".")
		if not normalized.is_empty() and normalized not in normalized_exts:
			normalized_exts.append(normalized)

	var paths: Array[String] = []
	if recursive:
		_collect_recursive(root_dir, normalized_exts, paths)
	else:
		_collect_flat(root_dir, normalized_exts, paths)
	paths.sort()
	return paths


static func _collect_flat(dir_path: String, extensions: Array[String], out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var entry_name := dir.get_next()
		if entry_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if _matches_extension(entry_name, extensions):
			out.append(dir_path.path_join(entry_name))
	dir.list_dir_end()


static func _collect_recursive(dir_path: String, extensions: Array[String], out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var entry_name := dir.get_next()
		if entry_name.is_empty():
			break
		if entry_name == "." or entry_name == "..":
			continue
		var full_path := dir_path.path_join(entry_name)
		if dir.current_is_dir():
			_collect_recursive(full_path, extensions, out)
			continue
		if _matches_extension(entry_name, extensions):
			out.append(full_path)
	dir.list_dir_end()


static func _matches_extension(file_name: String, extensions: Array[String]) -> bool:
	if extensions.is_empty():
		return true
	return file_name.get_extension().to_lower() in extensions
