---
title: "feat: Q89 GameFS batch DXT TPC import"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q88-auto-selected
phase: Q89
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-020-feat-q88-tpc-batch-dxt-convert-plan.md
  - docs/plans/2026-06-10-014-feat-q82-gamefs-tpc-batch-import-plan.md
  - formats/tpc_gamefs_batch_importer.gd
---

# Q89: GameFS Batch Install DXT TPC Import

## Summary

Extend `TpcGamefsBatchImporter` and the TPC workspace editor so install-scoped override batch import can write **DXT1 or DXT5** compressed `.tpc` files instead of RGBA only.

---

## Problem Frame

Q82 batch-imports override `.tga`/`.png` as uncompressed RGBA TPC. Q88 added folder-level DXT batch encode, but modders dropping images into override still get bulky RGBA when using **Batch Import Install TGA/PNG→TPC...**.

---

## Scope Boundaries

### In scope

- `TpcGamefsBatchImporter.batch_install_to_override` `encoding` option (`rgba` default, `dxt1`, `dxt5`)
- TPC editor **Batch Import Install DXT1...** and **Batch Import Install DXT5...** toolbar actions
- Headless tests for DXT install batch import + toolbar wiring
- Execution queue + parity matrix Q89 entry

### Deferred

- DXT3 install batch import
- TXI sidecar pairing in batch
- Import single image as DXT from file dialog

### Out of scope

- PyKotor CLI texture encode
- Recursive subfolder scan

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install_to_override` with `encoding: dxt1` writes valid DXT1 TPC to override | Unit test |
| R2 | `encoding: dxt5` produces `ENC_DXT5` metadata | Unit test |
| R3 | Default encoding remains RGBA for existing callers | Existing tests pass |
| R4 | TPC editor exposes DXT1/DXT5 install batch import buttons | Wiring test |
| R5 | Docs mark Q89 shipped | Doc diff |

---

## Implementation Units

### U1 — GameFS batch importer encoding

- **Files:** `formats/tpc_gamefs_batch_importer.gd`
- **Pattern:** Pass `encoding` through to `TpcBatchConverter.convert_from_image_file`

### U2 — TPC editor install batch DXT actions

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`
- **Pattern:** Mirror Q88 batch DXT toolbar split; reuse `_run_batch_install_import(gamefs, encoding)`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_gamefs_batch_importer.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_importer.gd
```
