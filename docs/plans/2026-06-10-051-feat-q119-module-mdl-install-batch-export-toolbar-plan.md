---
title: "feat: Q119 Module/MDL install batch export toolbar parity"
type: feat
status: active
date: 2026-06-10
origin: lfg-next-after-q118-auto-selected
phase: Q119
track: Module/Model Tools
parent: docs/plans/2026-06-10-028-feat-q96-gamefs-wok-batch-export-plan.md
related:
  - formats/bwm_gamefs_batch_exporter.gd
  - formats/mdl_gamefs_batch_exporter.gd
  - ui/workspace/editors/module_designer_workspace_editor.gd
  - ui/workspace/editors/mdl_workspace_editor.gd
---

# Q119: Module/MDL Install Batch Export Toolbar Parity

## Summary

Expose **Batch Export Install WOK...** in Module Designer and **Batch Export Install MDL...** in Model Editor, matching resource browser and WAV editor install-export patterns.

---

## Problem Frame

Q96/Q83 shipped GameFS batch export in the resource browser. Module Designer and Model Editor only expose folder copy/import batch actions — modders working in those editors must switch surfaces to dump indexed override assets.

---

## Scope Boundaries

### In scope

- Module Designer **Batch Export Install WOK...** via `BwmGamefsBatchExporter.batch_install`
- Model Editor **Batch Export Install MDL...** via `MdlGamefsBatchExporter.batch_install`
- Headless toolbar wiring tests
- Execution queue + parity matrix Q119 entry

### Deferred

- Module Designer MDL batch export (Model Editor owns MDL)
- Install-scoped batch import additions beyond existing actions

### Out of scope

- New GameFS exporter logic

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer exposes install WOK batch export button | `test_bwm_gamefs_batch_exporter.gd` |
| R2 | Model Editor exposes install MDL batch export button | `test_mdl_workspace_editor.gd` |
| R3 | Export handlers call existing `batch_install` with override filter | Source wiring |
| R4 | Docs mark Q119 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_exporter.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```
