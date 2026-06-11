---
title: "feat: Q109 flat-folder WAV batch copy to override"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q108-auto-selected
phase: Q109
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-040-feat-q108-wav-batch-folder-export-plan.md
related:
  - formats/wav_batch_exporter.gd
  - formats/wav_gamefs_batch_importer.gd
  - formats/bwm_gamefs_batch_importer.gd
---

# Q109: Flat-Folder WAV Batch Copy to Override

## Summary

Add raw byte-copy import from a flat `.wav` source folder into install override via `WavBatchExporter`, complementing Q104 PyKotor sound-convert import — mirroring Q98 `BwmGamefsBatchImporter`.

---

## Problem Frame

Q104 converts external WAV folders to `{resref}_clean.wav` in override. Modders with already-valid WAV files need a raw copy path without CLI conversion, symmetric with Q98 WOK folder import and Q108 folder export.

---

## Scope Boundaries

### In scope

- `WavGamefsBatchImporter.batch_folder_copy_to_override()` — delegate to `WavBatchExporter.batch_directory(source, override)`
- WAV editor **Batch Copy WAV Folder to Override...** toolbar action
- Headless tests in `tests/editor/test_wav_gamefs_batch_importer.gd`
- Execution queue + parity matrix Q109 entry

### Deferred

- Recursive subfolder scan
- Install-indexed raw WAV copy (only flat folder for v1)

### Out of scope

- PyKotor sound-convert (Q104/Q106)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_folder_copy_to_override` dry-run lists source WAVs | Unit test |
| R2 | Non-dry-run writes `{resref}.wav` into override | Unit test |
| R3 | `skip_existing` skips override destinations | Unit test |
| R4 | WAV editor exposes copy-to-override button | Wiring test |
| R5 | Docs mark Q109 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_gamefs_batch_importer.gd
```
