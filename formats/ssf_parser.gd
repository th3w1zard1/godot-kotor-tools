## SSF (Sound Set File) parser — maps 28 creature sound slots to TLK StrRefs.
class_name SSFParser

const HEADER_SIZE := 12
const SLOT_COUNT := 28
const FILE_TYPE := "SSF "
const FILE_VERSION := "V1.1"

const SLOT_LABELS: PackedStringArray = [
	"BATTLE_CRY_1",
	"BATTLE_CRY_2",
	"BATTLE_CRY_3",
	"BATTLE_CRY_4",
	"BATTLE_CRY_5",
	"BATTLE_CRY_6",
	"SELECT_1",
	"SELECT_2",
	"SELECT_3",
	"ATTACK_GRUNT_1",
	"ATTACK_GRUNT_2",
	"ATTACK_GRUNT_3",
	"PAIN_GRUNT_1",
	"PAIN_GRUNT_2",
	"LOW_HEALTH",
	"DEAD",
	"CRITICAL_HIT",
	"TARGET_IMMUNE",
	"LAY_MINE",
	"DISARM_MINE",
	"BEGIN_STEALTH",
	"BEGIN_SEARCH",
	"BEGIN_UNLOCK",
	"UNLOCK_FAILED",
	"UNLOCK_SUCCESS",
	"SEPARATED_FROM_PARTY",
	"REJOINED_PARTY",
	"POISONED",
]


static func slot_label(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= SLOT_LABELS.size():
		return "SLOT_%d" % slot_index
	return SLOT_LABELS[slot_index]


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.size() < HEADER_SIZE + SLOT_COUNT * 4:
		return {}

	var file_type := data.slice(0, 4).get_string_from_ascii()
	var file_version := data.slice(4, 8).get_string_from_ascii()
	if file_type != FILE_TYPE or file_version != FILE_VERSION:
		return {}

	var table_offset := _read_u32(data, 8)
	if table_offset + SLOT_COUNT * 4 > data.size():
		return {}

	var strrefs: Array[int] = []
	strrefs.resize(SLOT_COUNT)
	for index in SLOT_COUNT:
		strrefs[index] = _read_i32(data, table_offset + index * 4)

	return {
		"strrefs": strrefs,
		"table_offset": table_offset,
	}


static func _read_u32(data: PackedByteArray, offset: int) -> int:
	return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24)


static func _read_i32(data: PackedByteArray, offset: int) -> int:
	var raw := _read_u32(data, offset)
	if raw == 0xFFFFFFFF:
		return -1
	if raw & 0x80000000:
		return raw - 0x100000000
	return raw
