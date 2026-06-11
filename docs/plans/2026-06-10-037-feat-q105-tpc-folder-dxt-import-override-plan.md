---
title: "feat: Q105 TPC folder DXT import to override"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q104-auto-selected
phase: Q105
track: Texture/Media Tools
parent: docs/plans/2026-06-10-032-feat-q100-tpc-batch-folder-import-override-plan.md
related:
  - formats/tpc_gamefs_batch_importer.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q105: TPC Folder DXT1/DXT5 Import to Override

## Summary

Expose dedicated **Batch Import Folder DXT1/DXT5 to Override...** toolbar actions in the TPC editor, passing `encoding` through the existing `batch_folder_to_override` API deferred from Q100.

---

## Problem Frame

Q100 ships RGBA folder→override import. Q88/Q89 added DXT encoding for in-place batch convert and install-indexed import, but external texture folders destined for compressed override TPC still require manual encoding selection or RGBA-only import.

---

## Scope Boundaries

### In scope

- TPC editor **Batch Import Folder DXT1 to Override...** and **Batch Import Folder DXT5 to Override...** buttons
- Shared folder-picker handler with `encoding` passthrough to `TpcGamefsBatchImporter.batch_folder_to_override`
- Headless tests for DXT1/DXT5 folder override import + button wiring
- Execution queue + parity matrix Q105 entry

### Deferred

- Recursive subfolder scan
- DXT3 encode/import

### Out of scope

- New converter APIs (encoding option already exists)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_folder_to_override` with `encoding: dxt1` writes DXT1 TPC to override | Unit test |
| R2 | `batch_folder_to_override` with `encoding: dxt5` writes DXT5 TPC to override | Unit test |
| R3 | TPC editor exposes both DXT folder import buttons | Wiring test |
| R4 | Docs mark Q105 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_importer.gd
```
