---
title: "feat: Q120 WOK/MDL install batch copy to override"
type: feat
status: active
date: 2026-06-10
origin: lfg-next-after-q119-auto-selected
phase: Q120
track: Module/Model Tools
parent: docs/plans/2026-06-10-051-feat-q119-module-mdl-install-batch-export-toolbar-plan.md
related:
  - formats/bwm_gamefs_batch_exporter.gd
  - formats/bwm_gamefs_batch_importer.gd
  - formats/mdl_gamefs_batch_exporter.gd
  - formats/mdl_gamefs_batch_importer.gd
  - ui/workspace/editors/module_designer_workspace_editor.gd
  - ui/workspace/editors/mdl_workspace_editor.gd
---

# Q120: WOK/MDL Install Batch Copy to Override

## Summary

Add indexed install→override batch copy for walkmeshes and models, complementing Q119 install export and existing folder import actions.

---

## Problem Frame

Q119 added install-indexed **export** from Module Designer and Model Editor. Modders still cannot bulk-copy indexed `.wok`/`.mdl` resources into override without picking an external folder first. WAV already exposes one-click install actions (`batch_install_to_override`); WOK/MDL need the symmetric raw-byte copy path.

---

## Scope Boundaries

### In scope

- `BwmGamefsBatchImporter.batch_install_to_override()` — delegate to `BwmGamefsBatchExporter.batch_install` with override destination
- `MdlGamefsBatchImporter.batch_install_to_override()` — same for MDL/MDX pairs
- Module Designer **Batch Copy Install WOK to Override...**
- Model Editor **Batch Copy Install MDL to Override...**
- Headless importer + toolbar tests
- Execution queue + parity matrix Q120 entry

### Deferred

- Resource browser bulk install-copy actions
- Source-filter picker UI (default all indexed sources)
- Mutation preflight per file

### Out of scope

- New GameFS indexing logic
- Geometry conversion or rewriting

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | WOK `batch_install_to_override` dry-run lists indexed candidates | `test_bwm_gamefs_batch_importer.gd` |
| R2 | MDL `batch_install_to_override` writes MDL/MDX to override | `test_mdl_gamefs_batch_importer.gd` |
| R3 | Module Designer exposes install-copy button | Importer test |
| R4 | Model Editor exposes install-copy button | Importer test |
| R5 | Docs mark Q120 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_importer.gd
godot --headless --path . --script tests/editor/test_mdl_gamefs_batch_importer.gd
```
