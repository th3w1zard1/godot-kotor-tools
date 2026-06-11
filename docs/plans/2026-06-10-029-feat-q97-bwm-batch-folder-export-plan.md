---
title: "feat: Q97 flat-folder WOK batch export"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q96-auto-selected
phase: Q97
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-028-feat-q96-gamefs-wok-batch-export-plan.md
related:
  - formats/bwm_gamefs_batch_exporter.gd
  - formats/mdl_batch_exporter.gd
---

# Q97: Flat-Folder WOK Batch Export

## Summary

Add `BwmBatchExporter` to copy `.wok` files from a flat source folder to an output folder, complementing Q96 install-indexed export.

---

## Problem Frame

Q96 exports walkmeshes from the GameFS install index. Modders working with extracted filesystem folders need the same batch copy + metadata summary without indexing.

---

## Scope Boundaries

### In scope

- `BwmBatchExporter.batch_directory(source_dir, output_dir)` with `skip_existing`, `dry_run`, `include_metadata`
- Module Designer **Batch Copy WOK Folder...** (source + output directory pickers)
- Headless `tests/editor/test_bwm_batch_exporter.gd`
- Execution queue + parity matrix Q97 entry

### Deferred

- WOK batch import to override
- Recursive subfolder scan
- `bwm` extension alias

### Out of scope

- BWM writer / walkmesh editing

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Copies each `.wok` in flat source folder | Unit test |
| R2 | `skip_existing` skips destination files | Unit test |
| R3 | `include_metadata` adds vertex/face/walkable summary | Unit test |
| R4 | Module Designer exposes batch copy button | Wiring test |
| R5 | Docs mark Q97 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_batch_exporter.gd
```
