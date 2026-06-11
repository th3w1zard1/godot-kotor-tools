---
title: "feat: Q98 flat-folder WOK batch import to override"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q97-auto-selected
phase: Q98
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-029-feat-q97-bwm-batch-folder-export-plan.md
related:
  - formats/mdl_gamefs_batch_importer.gd
  - formats/bwm_batch_exporter.gd
---

# Q98: Flat-Folder WOK Batch Import to Override

## Summary

Add **folder→override batch WOK import** so modders can copy a flat folder of `.wok` files directly into the install override directory — complementing Q97 folder export and Q96 install-indexed export.

---

## Problem Frame

Q97 copies walkmeshes between arbitrary folders. Modders finishing external walkmesh work need a one-click path to land many `.wok` files in override without manual per-file install.

---

## Scope Boundaries

### In scope

- `BwmGamefsBatchImporter.batch_folder_to_override()` — resolve override via GameFS, delegate to `BwmBatchExporter.batch_directory`
- `skip_existing`, `dry_run`, `include_metadata` passthrough
- Module Designer **Batch Import WOK Folder to Override...** (single source-folder picker)
- GameFS refresh after successful non-dry-run import
- Headless `tests/editor/test_bwm_gamefs_batch_importer.gd`
- Execution queue + parity matrix Q98 entry

### Deferred

- Recursive subfolder scan
- Mutation preflight per file
- `bwm` extension alias

### Out of scope

- BWM writer / walkmesh editing

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_folder_to_override` writes WOK to override path | Unit test |
| R2 | `skip_existing` skips when override `{resref}.wok` exists | Unit test |
| R3 | `dry_run` reports planned imports without writing | Unit test |
| R4 | Module Designer exposes batch import button | Wiring test |
| R5 | Docs mark Q98 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_importer.gd
```
