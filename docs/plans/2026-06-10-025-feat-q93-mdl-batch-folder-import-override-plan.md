---
title: "feat: Q93 flat-folder MDL batch import to override"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q92-auto-selected
phase: Q93
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-024-feat-q92-mdl-batch-folder-export-plan.md
  - docs/plans/2026-06-10-015-feat-q83-gamefs-mdl-batch-export-plan.md
---

# Q93: Flat-Folder MDL Batch Import to Override

## Summary

Add **folder→override batch MDL import** so modders can copy a flat folder of `.mdl` files (with optional `.mdx` sidecars) directly into the install override directory — complementing Q92's folder→folder export and Q83's install-indexed export.

---

## Problem Frame

Q92 copies models between arbitrary folders. Modders finishing external model work need a one-click path to land many models in override without picking override manually. Single-file **Install MDL to Override** exists but does not scale to workshop folders.

---

## Scope Boundaries

### In scope

- `MdlGamefsBatchImporter.batch_folder_to_override()` — resolve override via GameFS, delegate copy to `MdlBatchExporter.batch_directory`
- `skip_existing`, `dry_run`, `include_metadata` passthrough
- Model Editor **Batch Import MDL Folder to Override...** (single source-folder picker)
- GameFS refresh after successful non-dry-run import
- Headless `tests/editor/test_mdl_gamefs_batch_importer.gd`
- Execution queue + parity matrix Q93 entry

### Deferred

- Recursive subfolder scan
- Indexed GameFS discovery import (MDL already in override needs no import)
- Mutation preflight per file
- Resource browser bulk import action

### Out of scope

- MDL writer / geometry editing
- PyKotor model-convert CLI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_folder_to_override` writes MDL/MDX to override path | Unit test |
| R2 | `skip_existing` skips when override `{resref}.mdl` exists | Unit test |
| R3 | `dry_run` reports planned imports without writing | Unit test |
| R4 | Model editor exposes batch import button | Wiring test |
| R5 | Docs mark Q93 shipped | Doc diff |

---

## Implementation Units

### U1 — GameFS batch importer

- **Files:** `formats/mdl_gamefs_batch_importer.gd`
- **Pattern:** Thin wrapper over `MdlBatchExporter`; override summary label "Install batch MDL import"

### U2 — Model editor action

- **Files:** `ui/workspace/editors/mdl_workspace_editor.gd`
- **Pattern:** Q92 batch copy flow with one folder picker; `_refresh_gamefs()` after apply

### U3 — Tests + docs

- **Files:** `tests/editor/test_mdl_gamefs_batch_importer.gd`, `tests/editor/test_mdl_workspace_editor.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_gamefs_batch_importer.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```
