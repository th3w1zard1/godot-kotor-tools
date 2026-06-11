---
title: "feat: Q106 install-scoped GameFS WAV batch convert"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q105-auto-selected
phase: Q106
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-036-feat-q104-wav-batch-import-override-plan.md
related:
  - formats/wav_gamefs_batch_importer.gd
  - formats/wav_batch_converter.gd
  - ui/workspace/editors/wav_workspace_editor.gd
---

# Q106: Install-Scoped GameFS WAV Batch Convert

## Summary

Scan indexed override `.wav` resources (plus flat override folder fallbacks), run PyKotor `sound-convert` to `{resref}_clean.wav` in override, and expose **Batch Convert Install WAV...** in the WAV workspace editor.

---

## Problem Frame

Q104 lands external-folder WAV batches into override. Modders who already dropped raw `.wav` files into override still need indexed batch convert without manual per-file or external-folder workflows — mirroring Q82 install-indexed TPC import.

---

## Scope Boundaries

### In scope

- `WavGamefsBatchImporter.batch_install_to_override()` — scan override WAV candidates, convert via bridge
- Skip `*_clean.wav` sources; `skip_existing` for `{resref}_clean.wav` outputs
- `WavBatchConverter.convert_file()` public wrapper for single-file convert reuse
- WAV editor **Batch Convert Install WAV...** toolbar action
- Headless tests + docs Q106 entry

### Deferred

- GameFS WAV batch export to filesystem folder
- Recursive subfolder scan

### Out of scope

- Native WAV encode (CLI-only path)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install_to_override` dry-run lists override WAV candidates | Unit test |
| R2 | Skips when `{resref}_clean.wav` already exists | Unit test |
| R3 | Skips `*_clean.wav` indexed sources | Unit test |
| R4 | WAV editor exposes install batch convert button | Wiring test |
| R5 | Docs mark Q106 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_gamefs_batch_importer.gd
```
