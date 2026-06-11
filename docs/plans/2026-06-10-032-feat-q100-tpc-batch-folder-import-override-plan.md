---
title: "feat: Q100 flat-folder TGA/PNG batch import to override"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q99-auto-selected
phase: Q100
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-031-feat-q99-tpc-txi-sidecar-pairing-plan.md
related:
  - formats/tpc_batch_converter.gd
  - formats/tpc_gamefs_batch_importer.gd
  - formats/mdl_gamefs_batch_importer.gd
---

# Q100: Flat-Folder TGA/PNG Batch Import to Override

## Summary

Add **folder→override batch image import** so modders can convert a flat folder of `.tga`/`.png` files (with optional sibling `.txi`) directly into install override `.tpc` resources — complementing Q77 in-place convert and Q82 install-indexed import.

---

## Problem Frame

Q77 converts images in-place; Q82 imports only override-indexed images. Modders finishing external texture work need the same one-click override landing path already shipped for MDL (Q93) and WOK (Q98).

---

## Scope Boundaries

### In scope

- `TpcBatchConverter.batch_directory_to_output()` — scan flat source, encode, write `{resref}.tpc` to output dir
- `TpcGamefsBatchImporter.batch_folder_to_override()` — resolve override via GameFS, delegate to converter
- `skip_existing`, `dry_run`, `encoding`, `alpha_test`, `include_txi_sidecar` passthrough
- TPC editor **Batch Import Image Folder to Override...** (single source-folder picker)
- GameFS refresh after successful non-dry-run import
- Headless `tests/editor/test_tpc_gamefs_batch_importer.gd`, `tests/editor/test_tpc_batch_converter.gd`
- Execution queue + parity matrix Q100 entry

### Deferred

- Recursive subfolder scan
- Separate DXT1/DXT5 folder-import toolbar buttons (encoding option sufficient)

### Out of scope

- TPCCompare TXI line-by-line diff
- DXT3 encode

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_directory_to_output` writes TPC to output path | Unit test |
| R2 | `batch_folder_to_override` writes to install override | Unit test |
| R3 | `skip_existing` skips when override `{resref}.tpc` exists | Unit test |
| R4 | `dry_run` reports planned imports without writing | Unit test |
| R5 | TXI sidecar attached when present beside source image | Unit test |
| R6 | TPC editor exposes batch folder import button | Wiring test |
| R7 | Docs mark Q100 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_importer.gd
```
