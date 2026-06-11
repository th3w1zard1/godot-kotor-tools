---
title: "feat: Q104 batch WAV import to override"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q103-auto-selected
phase: Q104
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-034-feat-q102-wav-batch-sound-convert-plan.md
related:
  - formats/wav_batch_converter.gd
  - ui/workspace/editors/wav_workspace_editor.gd
---

# Q104: Batch WAV Sound-Convert to Override

## Summary

Ship flat-folder PyKotor `sound-convert` batch import into install override: scan a source `.wav` folder, emit `{resref}_clean.wav` files under override, and expose **Batch Import WAV Folder to Override...** in the WAV workspace editor.

---

## Problem Frame

Q102 ships in-place folder batch convert. Q93/Q98/Q100 established flat-folder → override import for MDL/WOK/TPC. Modders cleaning voice/SFX batches for override need the same landing workflow without manual copy after convert.

---

## Scope Boundaries

### In scope

- `WavBatchConverter.batch_directory_to_output(source_dir, output_dir, options)`
- Refactor `batch_directory` to delegate to shared output path logic
- `WavGamefsBatchImporter.batch_folder_to_override` via converter + override path
- WAV editor **Batch Import WAV Folder to Override...** toolbar action
- Headless `tests/editor/test_wav_gamefs_batch_importer.gd` + extend `test_wav_batch_converter.gd`
- Execution queue + parity matrix Q104 entry

### Deferred

- Install-indexed GameFS WAV scan (override only has flat folder sources)
- Recursive subfolder scan

### Out of scope

- Native WAV encode (CLI-only path)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_directory_to_output` dry-run targets override paths | Unit test |
| R2 | `skip_existing` skips when override `{resref}_clean.wav` exists | Unit test |
| R3 | `batch_folder_to_override` writes converted WAVs to override | Unit test |
| R4 | WAV editor exposes batch import-to-override button | Wiring test |
| R5 | Docs mark Q104 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_batch_converter.gd
godot --headless --path . --script tests/editor/test_wav_gamefs_batch_importer.gd
```
