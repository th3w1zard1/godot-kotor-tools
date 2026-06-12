---
title: "feat: Q122 Module/MDL compare with override toolbar parity"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q121-auto-selected
phase: Q122
track: Module/Model Tools
parent: docs/plans/2026-06-10-026-feat-q94-bwm-semantic-compare-plan.md
related:
  - editor/modding/kotor_modding_pipeline.gd
  - ui/workspace/editors/module_designer_workspace_editor.gd
  - ui/workspace/editors/mdl_workspace_editor.gd
---

# Q122: Module/MDL Compare with Override Toolbar Parity

## Summary

Expose **Compare Walkmesh with Override...** in Module Designer and **Compare MDL with Override...** in Model Editor using existing `KotorModdingPipeline.compare_gamefs_resource` semantic diff (Q91/Q94).

---

## Problem Frame

GameFS dock and resource browser already compare overrides with semantic WOK/MDL reports. Module Designer and Model Editor modders must leave those surfaces to see whether their loaded area walkmesh or model differs from the indexed override copy.

---

## Scope Boundaries

### In scope

- Module Designer compare action for module bundle `.wok` entry
- Model Editor compare action for current model resref
- Status text via `KotorModdingPipeline.format_compare_result_text`
- Headless toolbar wiring tests
- Execution queue + parity matrix Q122 entry

### Deferred

- Compare loaded bytes vs override without GameFS index
- Compare report export from editors

### Out of scope

- New compare implementations

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer exposes walkmesh compare button | `test_bwm_gamefs_batch_exporter.gd` |
| R2 | Model Editor exposes MDL compare button | `test_mdl_workspace_editor.gd` |
| R3 | Handlers call `compare_gamefs_resource` | Source wiring |
| R4 | Docs mark Q122 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_exporter.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```
