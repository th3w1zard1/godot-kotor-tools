## formats/erf_writer.gd
## ERF / RIM / MOD container writer.
##
## Produces V1.0 archives compatible with KotOR and TSL.
## Write layout (little-endian):
##   160-byte header
##   Key list    : EntryCount × 24 bytes
##   Resource list: EntryCount × 8 bytes
##   Resource data: concatenated entry payloads
@tool
class_name ERFWriter

const ERFParser := preload("./erf_parser.gd")

## Reverse map: file extension → resource type code.
const EXT_TO_RES_TYPE: Dictionary = {
	"bmp": 0x0001, "tga": 0x0003, "wav": 0x0004, "plt": 0x0005,
	"ini": 0x0006, "txt": 0x0007, "mdl": 0x000A, "nss": 0x000B,
	"ncs": 0x000C, "mod": 0x000D, "are": 0x000E, "set": 0x000F,
	"ifo": 0x0010, "bic": 0x0011, "wok": 0x0012, "2da": 0x0018,
	"ssf": 0x001A, "tlk": 0x001C, "txi": 0x001F, "utc": 0x0020,
	"dlg": 0x0022, "itp": 0x0023, "utp": 0x0025, "dft": 0x0026,
	"git": 0x0027, "uti": 0x0028, "uta": 0x0029, "jrl": 0x002A,
	"uts": 0x002B, "utt": 0x002C, "utm": 0x002D, "ute": 0x002E,
	"utd": 0x002F, "utw": 0x0030, "uto": 0x0031, "lyt": 0x07E6,
	"vis": 0x07E7, "mp3": 0x07EA, "tpc": 0x07EE, "mdx": 0x07EF,
	"wlk": 0x07F0, "xml": 0x07F1, "scc": 0x07F2, "pth": 0x07FA,
	"lip": 0x07FB,
}

## Write serialized ERF bytes to a file.
static func save_bytes(bytes: PackedByteArray, path: String) -> Error:
	if bytes.is_empty():
		return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	var err := file.get_error()
	file.close()
	return OK if err == OK or err == ERR_FILE_EOF else err


## Build ERF bytes from a file_type string and an array of entry dicts.
##
## file_type : "ERF " | "RIM " | "MOD " | "SAV "  (4 chars, space-padded)
## entries   : Array[Dictionary], each with keys:
##               "resref"    : String  (≤16 chars, no extension)
##               "extension" : String  (e.g. "utc")
##               "bytes"     : PackedByteArray
##
## Returns empty PackedByteArray on error.
static func build(file_type: String, entries: Array) -> PackedByteArray:
	if file_type.length() != 4:
		push_error("ERFWriter: file_type must be exactly 4 characters (e.g. 'ERF ')")
		return PackedByteArray()

	var entry_count := entries.size()
	var offset_to_keys     := 160                        # right after 160-byte header
	var offset_to_resources := offset_to_keys + entry_count * 24
	var data_start          := offset_to_resources + entry_count * 8

	# Compute resource offsets
	var resource_offsets: Array[int] = []
	var cursor := data_start
	for entry in entries:
		resource_offsets.append(cursor)
		cursor += (entry.get("bytes", PackedByteArray()) as PackedByteArray).size()

	var buf := PackedByteArray()

	# --- 160-byte header ---
	_write_fixed_text(buf, file_type, 4)          # 0x00 FileType
	_write_fixed_text(buf, "V1.0", 4)             # 0x04 Version
	_write_u32(buf, 0)                             # 0x08 LanguageCount
	_write_u32(buf, 0)                             # 0x0C LocalizedStringSize
	_write_u32(buf, entry_count)                   # 0x10 EntryCount
	_write_u32(buf, offset_to_keys)                # 0x14 OffsetToLocalizedString (0 strings, points to key list)
	_write_u32(buf, offset_to_keys)                # 0x18 OffsetToKeyList
	_write_u32(buf, offset_to_resources)           # 0x1C OffsetToResourceList
	_write_u32(buf, 0)                             # 0x20 BuildYear
	_write_u32(buf, 0)                             # 0x24 BuildDay
	_write_u32(buf, 0xFFFFFFFF)                    # 0x28 DescriptionStrRef (none)
	buf.resize(buf.size() + 116)                   # 0x2C Reserved[116] — zero-fill

	# --- Key list (24 bytes × entries) ---
	for i in entry_count:
		var entry: Dictionary = entries[i]
		var resref := str(entry.get("resref", "")).to_lower().left(16)
		var ext    := str(entry.get("extension", "")).to_lower()
		var res_type := int(EXT_TO_RES_TYPE.get(ext, 0x0007))  # default to txt
		_write_fixed_text(buf, resref, 16)         # ResRef[16]
		_write_u32(buf, i)                         # ResourceID
		_write_u16(buf, res_type)                  # ResourceType
		_write_u16(buf, 0)                         # Unused

	# --- Resource list (8 bytes × entries) ---
	for i in entry_count:
		var payload: PackedByteArray = entries[i].get("bytes", PackedByteArray())
		_write_u32(buf, resource_offsets[i])       # OffsetToResource
		_write_u32(buf, payload.size())            # ResourceSize

	# --- Resource data ---
	for entry in entries:
		var payload: PackedByteArray = entry.get("bytes", PackedByteArray())
		buf.append_array(payload)

	return buf


## Round-trip helper: re-pack an existing parsed ERF result (from ERFParser.parse_file)
## with a modified entries array.  Accepts Array[ERFEntry] with read_data() support,
## or Array[Dictionary] with {resref, extension, bytes}.
static func repack(file_type: String, erf_entries: Array) -> PackedByteArray:
	var dicts: Array = []
	for e in erf_entries:
		if e is ERFParser.ERFEntry:
			dicts.append({
				"resref":    e.resref,
				"extension": e.extension,
				"bytes":     e.read_data(),
			})
		elif e is Dictionary:
			dicts.append(e)
	return build(file_type, dicts)


# ---- binary helpers --------------------------------------------------------

static func _write_u32(buf: PackedByteArray, value: int) -> void:
	buf.append(value & 0xFF)
	buf.append((value >> 8) & 0xFF)
	buf.append((value >> 16) & 0xFF)
	buf.append((value >> 24) & 0xFF)


static func _write_u16(buf: PackedByteArray, value: int) -> void:
	buf.append(value & 0xFF)
	buf.append((value >> 8) & 0xFF)


static func _write_fixed_text(buf: PackedByteArray, text: String, length: int) -> void:
	var bytes := text.to_ascii_buffer()
	for i in length:
		buf.append(bytes[i] if i < bytes.size() else 0)
