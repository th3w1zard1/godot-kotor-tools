## Typed savegame (.sav) container document — SAV ERF with member mutation.
extends "./kotor_erf_document.gd"
class_name KotorSavegameDocument

const KotorErfDocumentScript := preload("./kotor_erf_document.gd")
const EXPECTED_FILE_TYPE := "SAV "
const _SCRIPT := "res://resources/documents/kotor_savegame_document.gd"


static func open_savegame(source_path: String, bytes: PackedByteArray) -> KotorErfDocument:
	var parsed := ERFParser.parse_bytes(bytes)
	if parsed.is_empty() or str(parsed.get("file_type", "")) != EXPECTED_FILE_TYPE:
		return null
	return KotorErfDocumentScript.from_bytes(source_path, bytes, load(_SCRIPT))
