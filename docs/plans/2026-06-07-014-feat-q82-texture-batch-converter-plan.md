---
title: "feat: Q82 batch TGA/PNG to TPC converter"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q81-auto-selected
phase: Q82
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-013-feat-q81-gamefs-tpc-batch-export-plan.md
  - docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md
---

# Q82: Batch TGA/PNG → TPC Converter

## Summary

Ship native **folder batch texture import**: scan a flat directory of `.tga` and `.png` images, encode each as uncompressed RGBA TPC via `TPCWriter`, and expose **Batch Convert TGA/PNG→TPC...** in the TPC workspace editor.

---

## Problem Frame

Q30 shipped single-image TPC import and Q81 shipped install-indexed batch export. Holocron/PyKotor texture batch utilities also help modders convert many source images into game-ready `.tpc` files. The Godot plugin still lacks a folder-level batch import path on `main`.

---

## Scope Boundaries

### In scope

- `TpcBatchConverter` — single image → TPC bytes + flat directory batch scan
- TPC editor **Batch Convert TGA/PNG→TPC...** toolbar action with folder picker and summary status
- Headless `tests/editor/test_tpc_batch_converter.gd`
- Execution queue + parity matrix Q82 entry

### Deferred

- DXT compression batch encode
- Recursive subfolder scan
- Auto-install batch output to override
- TXI sidecar pairing in batch

### Out of scope

- PyKotor CLI texture batch bridge
- GameFS-indexed batch import

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `convert_from_image_file` returns valid RGBA TPC bytes for PNG | Unit test |
| R2 | `batch_directory` writes `.tpc` beside each image; `skip_existing` works | Unit test |
| R3 | Invalid images reported as failed | Unit test |
| R4 | TPC editor exposes batch folder action | Wiring test |
| R5 | Docs mark Q82 shipped | Doc diff |

---

## Implementation Units

### U1 — TpcBatchConverter

- **Files:** `formats/tpc_batch_converter.gd`

### U2 — TPC editor batch action

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_batch_converter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
```
