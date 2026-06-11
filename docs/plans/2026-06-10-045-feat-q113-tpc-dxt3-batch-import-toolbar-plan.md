---
title: "feat: Q113 TPC DXT3 batch/import toolbar parity"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q112-auto-selected
phase: Q113
track: Texture/Media Tools
parent: docs/plans/2026-06-10-044-feat-q112-tpc-dxt3-encode-plan.md
related:
  - formats/tpc_batch_converter.gd
  - formats/tpc_gamefs_batch_importer.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q113: TPC DXT3 Batch/Import Toolbar Parity

## Summary

Wire **DXT3** through `TpcBatchConverter` and mirror Q88/Q89/Q90/Q105 toolbar actions in the TPC workspace editor now that Q112 ships native DXT3 encode.

---

## Problem Frame

Q112 added `serialize_dxt3` and **Re-encode DXT3...** only. Batch convert, single-file import, install-indexed import, and folder→override import still accept `dxt1`/`dxt5` but not `dxt3`.

---

## Scope Boundaries

### In scope

- `TpcBatchConverter` `dxt3` encoding in `_serialize_image` / `_expected_encoding_value`
- TPC editor toolbar parity:
  - **Import TGA/PNG as DXT3...**
  - **Batch Convert DXT3...**
  - **Batch Import Install DXT3...**
  - **Batch Import Folder DXT3 to Override...**
- `load_image_as_dxt3()` + `_load_image_as_tpc` DXT3 branch
- Headless tests in `test_tpc_batch_converter.gd`, `test_tpc_gamefs_batch_importer.gd`, `test_tpc_dxt_reencode.gd`
- Execution queue + parity matrix Q113 entry

### Deferred

- Recursive subfolder scan

### Out of scope

- New batch APIs (encoding passthrough only)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `convert_from_image_file` with `encoding: dxt3` writes DXT3 TPC | `test_tpc_batch_converter.gd` |
| R2 | `batch_directory` with `encoding: dxt3` | `test_tpc_batch_converter.gd` |
| R3 | `batch_install_to_override` with `encoding: dxt3` | `test_tpc_gamefs_batch_importer.gd` |
| R4 | `batch_folder_to_override` with `encoding: dxt3` | `test_tpc_gamefs_batch_importer.gd` |
| R5 | Editor import/batch toolbar buttons for DXT3 | `test_tpc_dxt_reencode.gd` |
| R6 | Docs mark Q113 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_importer.gd
godot --headless --path . --script tests/editor/test_tpc_dxt_reencode.gd
```
