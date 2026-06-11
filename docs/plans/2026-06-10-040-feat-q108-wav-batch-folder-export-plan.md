---
title: "feat: Q108 flat-folder WAV batch export"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q107-auto-selected
phase: Q108
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-039-feat-q107-gamefs-wav-batch-export-plan.md
related:
  - formats/wav_gamefs_batch_exporter.gd
  - formats/bwm_batch_exporter.gd
  - ui/workspace/editors/wav_workspace_editor.gd
---

# Q108: Flat-Folder WAV Batch Export

## Summary

Add `WavBatchExporter` to copy `.wav` files from a flat source folder to an output folder with `WavMetadata` summaries — complementing Q107 install-indexed export and completing the WAV batch export symmetry with Q97 WOK folder copy.

---

## Problem Frame

Q107 exports WAVs from the GameFS install index. Modders working with extracted filesystem folders need the same batch byte copy + metadata summary without indexing — mirroring `BwmBatchExporter` (Q97).

---

## Scope Boundaries

### In scope

- `WavBatchExporter.batch_directory(source_dir, output_dir)` with `skip_existing`, `dry_run`, `include_metadata`
- WAV workspace editor **Batch Copy WAV Folder...** (source + output directory pickers)
- Headless `tests/editor/test_wav_batch_exporter.gd`
- Execution queue + parity matrix Q108 entry

### Deferred

- Recursive subfolder scan
- Skip/filter `_clean.wav` naming policy (copy all `.wav` in flat folder)

### Out of scope

- PyKotor sound-convert (Q102/Q104/Q106 paths)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Copies each `.wav` in flat source folder | Unit test |
| R2 | `skip_existing` skips destination files | Unit test |
| R3 | `include_metadata` adds channels/rate/duration summary | Unit test |
| R4 | WAV editor exposes batch copy button | Wiring test |
| R5 | Docs mark Q108 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_batch_exporter.gd
```
