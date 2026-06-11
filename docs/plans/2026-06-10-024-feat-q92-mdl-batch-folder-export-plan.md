---
title: "feat: Q92 flat-folder MDL batch export"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q91-auto-selected
phase: Q92
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-015-feat-q83-gamefs-mdl-batch-export-plan.md
  - formats/mdl_gamefs_batch_exporter.gd
---

# Q92: Flat-Folder MDL Batch Export

## Summary

Add `MdlBatchExporter` to copy `.mdl` files (and paired `.mdx` sidecars) from a flat source folder to an output folder, complementing Q83 install-indexed export.

---

## Problem Frame

Q83 exports MDL from the GameFS install index. Modders often work with filesystem folders of extracted models; they need the same batch copy + metadata summary without indexing.

---

## Scope Boundaries

### In scope

- `MdlBatchExporter.batch_directory(source_dir, output_dir)` with `skip_existing`, `dry_run`, `include_metadata`
- Model Editor **Batch Copy MDL Folder...** (source + output directory pickers)
- Headless `tests/editor/test_mdl_batch_exporter.gd`
- Execution queue + parity matrix Q92 entry

### Deferred

- Recursive subfolder scan
- MDL install batch import
- PyKotor model-convert CLI

### Out of scope

- MDL writer / geometry editing

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Copies `.mdl` and sidecar `.mdx` when present | Unit test |
| R2 | `skip_existing` skips destination files | Unit test |
| R3 | `include_metadata` adds vertex/face summary | Unit test |
| R4 | MDL editor exposes batch copy toolbar button | Wiring test |
| R5 | Docs mark Q92 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_batch_exporter.gd
```
