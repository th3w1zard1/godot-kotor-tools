## Semantic GFF difference summaries for install compare reports.
class_name GFFCompare

const GFFParser := preload("gff_parser.gd")

const SAMPLE_LIMIT := 5


static func is_gff_extension(extension: String) -> bool:
	var normalized := extension.to_lower()
	return normalized in [
		"are", "dlg", "fac", "gff", "git", "ifo", "jrl", "pth",
		"utc", "utd", "ute", "uti", "utm", "utp", "uts", "utt", "utw",
	]


## Return a human-readable diff summary, or empty to fall back to binary compare.
static func build_difference_report(base_bytes: PackedByteArray, mod_bytes: PackedByteArray) -> String:
	var base := GFFParser.parse_bytes(base_bytes)
	var mod := GFFParser.parse_bytes(mod_bytes)
	if base.is_empty() or mod.is_empty():
		return ""

	var samples: Array[String] = []
	var change_count := _diff_values("", base.get("root", {}), mod.get("root", {}), samples)

	var file_type := String(base.get("file_type", "")).strip_edges()
	if file_type == "DLG":
		_append_dlg_list_summary(base.get("root", {}), mod.get("root", {}), samples)

	if change_count == 0 and samples.is_empty():
		return ""

	var label := file_type if not file_type.is_empty() else "GFF"
	var parts: Array[String] = ["%s differs" % label, "%d field changes" % change_count]
	if samples.is_empty():
		return "%s." % ", ".join(parts)
	return "%s.\nExamples:\n- %s" % [", ".join(parts), "\n- ".join(samples)]


static func _append_dlg_list_summary(
		base_root: Dictionary,
		mod_root: Dictionary,
		samples: Array[String]
) -> void:
	for list_name in ["EntryList", "ReplyList", "StartingList"]:
		var base_size := _list_size(base_root, list_name)
		var mod_size := _list_size(mod_root, list_name)
		if base_size == mod_size:
			continue
		var line := "%s count: %d -> %d" % [list_name, base_size, mod_size]
		if samples.has(line):
			continue
		if samples.size() < SAMPLE_LIMIT:
			samples.append(line)


static func _list_size(root: Dictionary, field_name: String) -> int:
	var value = root.get(field_name, [])
	return value.size() if value is Array else 0


static func _diff_values(
		path: String,
		base_value: Variant,
		mod_value: Variant,
		samples: Array[String]
) -> int:
	if base_value == mod_value:
		return 0

	if typeof(base_value) != typeof(mod_value):
		_append_sample(samples, _sample_path(path), _value_text(base_value), _value_text(mod_value))
		return 1

	match typeof(base_value):
		TYPE_DICTIONARY:
			if _is_locstring(base_value):
				if not _locstring_equal(base_value, mod_value):
					_append_sample(
						samples,
						_sample_path(path),
						_locstring_text(base_value),
						_locstring_text(mod_value)
					)
					return 1
				return 0
			var changes := 0
			var keys := _union_keys(base_value, mod_value)
			for key in keys:
				var child_path := "%s.%s" % [path, key] if not path.is_empty() else str(key)
				changes += _diff_values(
					child_path,
					base_value.get(key, null),
					mod_value.get(key, null),
					samples
				)
			return changes
		TYPE_ARRAY:
			var changes := 0
			var base_array: Array = base_value
			var mod_array: Array = mod_value
			if base_array.size() != mod_array.size():
				_append_sample(
					samples,
					_sample_path(path),
					"list size %d" % base_array.size(),
					"list size %d" % mod_array.size()
				)
				changes += 1
			var limit := mini(base_array.size(), mod_array.size())
			for index in range(limit):
				var item_path := "%s[%d]" % [path, index] if not path.is_empty() else "[%d]" % index
				changes += _diff_values(
					item_path,
					base_array[index],
					mod_array[index],
					samples
				)
			return changes
		_:
			_append_sample(samples, _sample_path(path), _value_text(base_value), _value_text(mod_value))
			return 1


static func _append_sample(
		samples: Array[String],
		path: String,
		base_text: String,
		mod_text: String
) -> void:
	if samples.size() >= SAMPLE_LIMIT:
		return
	samples.append("%s: %s -> %s" % [path, base_text, mod_text])


static func _sample_path(path: String) -> String:
	return path if not path.is_empty() else "root"


static func _union_keys(base_value: Dictionary, mod_value: Dictionary) -> Array:
	var keys: Array = []
	for key in base_value.keys():
		if not keys.has(key):
			keys.append(key)
	for key in mod_value.keys():
		if not keys.has(key):
			keys.append(key)
	return keys


static func _is_locstring(value: Dictionary) -> bool:
	return value.has("strref") or value.has("strings")


static func _locstring_equal(base_value: Dictionary, mod_value: Dictionary) -> bool:
	return _locstring_text(base_value) == _locstring_text(mod_value)


static func _locstring_text(locstring: Dictionary) -> String:
	var strref := int(locstring.get("strref", 0xFFFFFFFF))
	var strings = locstring.get("strings", {})
	var local := ""
	if strings is Dictionary and strings.has(0):
		local = String(strings[0]).strip_edges()
	elif strings is Dictionary:
		for language in strings.keys():
			var text := String(strings[language]).strip_edges()
			if not text.is_empty():
				local = text
				break
	if not local.is_empty():
		return "\"%s\"" % local
	if strref >= 0 and strref != 0xFFFFFFFF:
		return "StrRef %d" % strref
	return "(empty locstring)"


static func _value_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "<missing>"
		TYPE_STRING:
			return "\"%s\"" % value
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_INT, TYPE_FLOAT:
			return str(value)
		TYPE_DICTIONARY:
			if _is_locstring(value):
				return _locstring_text(value)
			return "{...}"
		TYPE_ARRAY:
			return "list(%d)" % (value as Array).size()
		_:
			return str(value)
