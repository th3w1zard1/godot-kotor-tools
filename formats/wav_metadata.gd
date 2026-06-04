class_name WavMetadata
extends RefCounted

## RIFF/WAVE metadata and PCM peak extraction for editor previews.


static func parse_bytes(data: PackedByteArray) -> Dictionary:
	if data.size() < 44:
		return {"ok": false, "message": "File too small for WAV header"}
	if data.slice(0, 4).get_string_from_ascii() != "RIFF" or data.slice(8, 12).get_string_from_ascii() != "WAVE":
		return {"ok": false, "message": "Missing RIFF/WAVE header"}

	var fmt_found := false
	var data_offset := -1
	var data_size := 0
	var channels := 0
	var sample_rate := 0
	var bits_per_sample := 0
	var audio_format := 0
	var block_align := 0

	var offset := 12
	while offset + 8 <= data.size():
		var chunk_id := data.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := data.decode_u32(offset + 4)
		offset += 8
		if offset + chunk_size > data.size():
			break
		if chunk_id == "fmt ":
			fmt_found = true
			audio_format = data.decode_u16(offset)
			channels = data.decode_u16(offset + 2)
			sample_rate = data.decode_u32(offset + 4)
			block_align = data.decode_u16(offset + 12)
			bits_per_sample = data.decode_u16(offset + 14)
		elif chunk_id == "data":
			data_offset = offset
			data_size = chunk_size
		offset += chunk_size + (chunk_size % 2)

	if not fmt_found:
		return {"ok": false, "message": "Missing fmt chunk"}
	if data_offset < 0 or data_size <= 0:
		return {"ok": false, "message": "Missing data chunk"}

	var bytes_per_sample := maxi(bits_per_sample / 8, 1)
	var duration := 0.0
	if channels > 0 and sample_rate > 0:
		duration = float(data_size) / float(channels * sample_rate * bytes_per_sample)

	var format_label := "PCM"
	var playable_pcm := audio_format == 1 and bits_per_sample == 16
	if audio_format == 17:
		format_label = "IMA ADPCM (KotOR)"
	elif audio_format != 1:
		format_label = "Format %d" % audio_format

	return {
		"ok": true,
		"format_label": format_label,
		"audio_format": audio_format,
		"channels": channels,
		"sample_rate": sample_rate,
		"bits_per_sample": bits_per_sample,
		"block_align": block_align,
		"data_offset": data_offset,
		"data_size": data_size,
		"duration_seconds": duration,
		"playable_pcm": playable_pcm,
	}


static func build_pcm_peaks(data: PackedByteArray, bucket_count: int = 512) -> Dictionary:
	var meta := parse_bytes(data)
	if not meta.get("ok", false):
		return {"ok": false, "message": meta.get("message", "Invalid WAV")}
	if not meta.get("playable_pcm", false):
		return {
			"ok": false,
			"message": "Waveform requires 16-bit PCM WAV (%s)." % meta.get("format_label", "?"),
		}

	bucket_count = clampi(bucket_count, 16, 4096)
	var channels := int(meta.get("channels", 1))
	var data_offset := int(meta.get("data_offset", 0))
	var data_size := int(meta.get("data_size", 0))
	var sample_count := data_size / (2 * channels)
	if sample_count <= 0:
		return {"ok": false, "message": "No PCM samples in data chunk"}

	var peaks := PackedFloat32Array()
	peaks.resize(bucket_count)
	for i in bucket_count:
		peaks[i] = 0.0

	var samples_per_bucket := maxi(sample_count / bucket_count, 1)
	var sample_index := 0
	var bucket_index := 0
	while sample_index < sample_count and bucket_index < bucket_count:
		var peak := 0.0
		var end_sample := mini(sample_index + samples_per_bucket, sample_count)
		while sample_index < end_sample:
			var byte_index := data_offset + sample_index * channels * 2
			var mixed := 0.0
			for ch in channels:
				var idx := byte_index + ch * 2
				if idx + 1 >= data.size():
					break
				var sample := data.decode_s16(idx)
				mixed = maxf(mixed, absf(float(sample) / 32768.0))
			peak = maxf(peak, mixed)
			sample_index += 1
		peaks[bucket_index] = peak
		bucket_index += 1

	return {
		"ok": true,
		"peaks": peaks,
		"duration_seconds": float(meta.get("duration_seconds", 0.0)),
	}


static func format_summary(meta: Dictionary) -> PackedStringArray:
	if not meta.get("ok", false):
		return PackedStringArray(["Invalid WAV: %s" % meta.get("message", "?")])
	return PackedStringArray([
		"Format: %s" % meta.get("format_label", "?"),
		"Channels: %d" % meta.get("channels", 0),
		"Sample rate: %d Hz" % meta.get("sample_rate", 0),
		"Bits per sample: %d" % meta.get("bits_per_sample", 0),
		"Data size: %d bytes" % meta.get("data_size", 0),
		"Duration: %.2f s" % meta.get("duration_seconds", 0.0),
	])
