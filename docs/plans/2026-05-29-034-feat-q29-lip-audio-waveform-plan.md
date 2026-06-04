---
title: Q29 LIP Audio Playback and Waveform
type: feat
status: completed
date: 2026-05-29
origin: docs/brainstorms/2026-05-29-q29-lip-audio-waveform-requirements.md
phase: Q29
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q29: LIP Audio Playback and Waveform

## Summary

Add paired WAV loading, PCM waveform visualization, playback/scrub, and live viseme preview to the LIP Sync workspace editor — the Holocron lip-sync loop deferred from Q28.

## Problem frame

Q28 ships keyframe editing only. Holocron's LIP editor expects a paired voice line for timing and preview. Without audio, modders cannot author lip sync efficiently inside Godot.

## Key decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| WAV parsing | Shared `formats/wav_metadata.gd` | Same RIFF walk as WAV editor; single source for duration/peaks |
| Playback | `AudioStreamWAV.load_from_file` for PCM | Godot-native; no Qt multimedia in editor plugin |
| IMA ADPCM | Metadata only; no auto-play | KotOR VO often ADPCM; convert via existing WAV tool first |
| Waveform UI | `lip_waveform_view.gd` Control | Peaks + keyframe ticks + playhead; click to seek |
| Duration sync | Prompt on WAV load when longer/shorter | Matches Holocron setting duration from WAV |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `WavMetadata.parse_bytes` returns duration/channels/rate/format | `tests/editor/test_wav_metadata.gd` |
| R2 | `WavMetadata.build_pcm_peaks` for 16-bit PCM mono/stereo | Same test |
| R3 | LIP editor: Load WAV, Play, Stop, waveform panel | Manual + editor wiring |
| R4 | Scrub: waveform click + keyframe select seeks audio | Editor behavior |
| R5 | Viseme label updates during playback | Editor `_process` |
| R6 | Docs: parity matrix + execution queue Q29 shipped | Doc update |

## Implementation units

### U1 — `formats/wav_metadata.gd`

- Extract RIFF/fmt/data parsing from `wav_workspace_editor.gd`
- Add `build_pcm_peaks(data, bucket_count)` returning normalized peaks
- Refactor WAV editor to call static helpers (behavior unchanged)

### U2 — `ui/workspace/widgets/lip_waveform_view.gd`

- Draw peaks, vertical keyframe markers, playhead line
- Emit `seek_requested(time_seconds)` on click
- API: `set_peaks`, `set_duration`, `set_playhead`, `set_keyframe_times`

### U3 — Extend `lip_workspace_editor.gd`

- Toolbar: Load WAV, Play, Stop; labels for audio path + current viseme
- `AudioStreamPlayer` child; load PCM via `AudioStreamWAV`
- Wire waveform; sync playhead; seek on select/scrub
- On WAV load: set peaks; if playable, optionally sync LIP length

### U4 — Tests and docs

- `tests/editor/test_wav_metadata.gd`
- Update `openkotor-parity-matrix.md`, `godot-capability-execution-queue.md`
- Mark Q29 plan completed when done

## Test scenarios

1. Minimal valid PCM WAV bytes → metadata ok, duration > 0
2. Invalid bytes → `ok: false`
3. Synthetic sine PCM → peak array length equals bucket count, values in 0..1
4. Dock routing still includes `lip` (existing test)

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_metadata.gd
godot --headless --path . --script tests/editor/test_lip_parser.gd
godot --headless --path . --script tests/editor/test_dock_workspace_routing.gd
```

## Non-goals

- Batch LIP processor
- LIP undo/redo stack
- In-editor ADPCM decode

## Acceptance

- [x] All verification commands pass
- [x] LIP editor plays PCM WAV with waveform + viseme preview
- [x] Docs updated for Q29
