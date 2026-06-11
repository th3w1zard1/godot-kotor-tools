---
title: "feat: Q88 batch TGA/PNG to DXT TPC"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q87-auto-selected
phase: Q88
track: Texture/Media Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-019-feat-q87-tpc-editor-dxt-reencode-plan.md
  - formats/tpc_batch_converter.gd
---

# Q88: Batch TGA/PNG → DXT TPC

## Summary

Extend `TpcBatchConverter` and the TPC workspace editor so folder batch workflows can emit **DXT1 or DXT5** TPC files instead of uncompressed RGBA only.

---

## Problem Frame

Q86–Q87 added native DXT encode and single-texture re-encode in the TPC editor, but **Batch Convert TGA/PNG→TPC...** still writes RGBA. Modders batching texture folders still produce oversized override files.

---

## Scope Boundaries

### In scope

- `TpcBatchConverter` `encoding` option: `rgba` (default), `dxt1`, `dxt5`
- TPC editor toolbar **Batch Convert DXT1...** and **Batch Convert DXT5...**
- Headless tests for DXT batch conversion
- Execution queue + parity matrix Q88 entry

### Deferred

- GameFS batch import DXT mode
- DXT3 batch encode
- Import-image-as-DXT from file dialog

### Out of scope

- Encoder algorithm changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `convert_from_image_file` with `encoding: dxt1` writes valid DXT1 TPC | Unit test |
| R2 | `batch_directory` with `encoding: dxt5` writes compressed TPC files | Unit test |
| R3 | Default encoding remains RGBA for existing callers | Unit test |
| R4 | TPC editor exposes DXT1/DXT5 batch toolbar buttons | Unit test |
| R5 | Docs mark Q88 shipped | Doc diff |

---

## Implementation Units

### U1 — Batch converter encoding option

- **Files:** `formats/tpc_batch_converter.gd`, `formats/tpc_gamefs_batch_importer.gd`

### U2 — TPC editor batch DXT actions

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_batch_converter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
```
