---
title: "feat: Q116 WAV recursive batch directory scan"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q115-auto-selected
phase: Q116
track: Texture/Media Tools
parent: docs/plans/2026-06-10-047-feat-q115-tpc-recursive-batch-scan-plan.md
related:
  - formats/batch_directory_scanner.gd
  - formats/wav_batch_exporter.gd
  - formats/wav_batch_converter.gd
  - ui/workspace/editors/wav_workspace_editor.gd
---

# Q116: WAV Recursive Batch Directory Scan

## Summary

Propagate `BatchDirectoryScanner` and `recursive: true` through WAV batch export/convert paths, matching Q115 TPC behavior.

---

## Problem Frame

Q115 added recursive scan for TPC batch tools. WAV folder batch convert, copy, and override import still skip nested `.wav` files.

---

## Scope Boundaries

### In scope

- `WavBatchExporter.batch_directory` honors `recursive` (flatten to output, duplicate resref fails)
- `WavBatchConverter.batch_directory` / `batch_directory_to_output` honor `recursive`
- WAV editor folder batch actions pass `recursive: true`
- Headless tests in `test_wav_batch_exporter.gd`, `test_wav_batch_converter.gd`, `test_wav_gamefs_batch_importer.gd`
- Execution queue + parity matrix Q116 entry

### Deferred

- BWM/MDL recursive batch scan
- Mirror nested output folder structure

### Out of scope

- Install-indexed GameFS scan changes (flat index only)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Recursive WAV export flattens nested files to output dir | `test_wav_batch_exporter.gd` |
| R2 | Recursive WAV convert writes `_clean.wav` beside nested sources (in-place) or to override (flatten) | `test_wav_batch_converter.gd` |
| R3 | Duplicate resref across subfolders fails on flatten paths | Exporter/importer tests |
| R4 | WAV editor passes `recursive: true` for folder batch actions | Source wiring |
| R5 | Docs mark Q116 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_batch_exporter.gd
godot --headless --path . --script tests/editor/test_wav_batch_converter.gd
godot --headless --path . --script tests/editor/test_wav_gamefs_batch_importer.gd
```
