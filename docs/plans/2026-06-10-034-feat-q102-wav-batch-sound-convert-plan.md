---
title: "feat: Q102 batch WAV sound-convert"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q101-auto-selected
phase: Q102
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-032-feat-q27-media-tooling-plan.md
related:
  - formats/tpc_batch_exporter.gd
  - resources/scripts/kotor_media_tool_bridge.gd
  - ui/workspace/editors/wav_workspace_editor.gd
---

# Q102: Batch WAV Sound-Convert

## Summary

Ship folder-level PyKotor `sound-convert` batch processing: scan a flat `.wav` folder, emit `{resref}_clean.wav` files, and expose **Batch Convert WAV...** in the WAV workspace editor.

---

## Problem Frame

Q27 ships single-file WAV convert via `KotorMediaToolBridge`. Q79 established the batch CLI exporter pattern for textures. Modders cleaning many voice/SFX sources need the same folder workflow for WAV without repetitive per-file conversion.

---

## Scope Boundaries

### In scope

- `WavBatchConverter.batch_directory()` — flat `.wav` scan, `sound-convert` per file via bridge
- Skip `*_clean.wav` inputs and existing outputs when `skip_existing`
- `sound_type`, `to_clean`, `dry_run`, `pykotor_cli_path` options
- WAV editor **Batch Convert WAV...** toolbar action with folder picker
- Headless `tests/editor/test_wav_batch_converter.gd`
- Execution queue + parity matrix Q102 entry

### Deferred

- GameFS install batch WAV import
- Recursive subfolder scan

### Out of scope

- Native WAV encode (CLI-only path)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_directory` dry-run builds commands for each source WAV | Unit test |
| R2 | `skip_existing` skips when `{resref}_clean.wav` exists | Unit test |
| R3 | `*_clean.wav` sources are not re-processed | Unit test |
| R4 | WAV editor exposes batch convert button | Wiring test |
| R5 | Docs mark Q102 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_batch_converter.gd
```
