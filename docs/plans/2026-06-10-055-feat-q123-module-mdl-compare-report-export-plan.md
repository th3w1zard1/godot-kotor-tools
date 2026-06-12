---
title: "feat: Q123 Module/MDL compare report export toolbar parity"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q122-auto-selected
phase: Q123
track: Module/Model Tools
parent: docs/plans/2026-06-10-054-feat-q122-module-mdl-compare-override-toolbar-plan.md
related:
  - editor/modding/kotor_modding_pipeline.gd
  - ui/workspace/editors/module_designer_workspace_editor.gd
  - ui/workspace/editors/mdl_workspace_editor.gd
  - tests/editor/test_compare_report_export.gd
---

# Q123: Module/MDL Compare Report Export Toolbar Parity

## Summary

After Q122 compare actions, add **Export Compare Report...** to Module Designer and Model Editor toolbars. Persist the last compare result and write it via `KotorModdingPipeline.export_compare_result_to_path`.

---

## Problem Frame

GameFS dock already exports compare reports (Q41). Module Designer and Model Editor show compare output only in ephemeral status text — modders cannot save WOK/MDL semantic diff reports from those surfaces.

---

## Scope Boundaries

### In scope

- Store `_last_compare_result` when compare succeeds
- Export button + save dialog in both editors
- Status feedback on missing compare / export failure
- Headless toolbar button tests
- Execution queue + parity matrix Q123 entry

### Deferred

- Auto-export after every compare
- Batch compare from editors

### Out of scope

- New compare or export pipeline logic

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer exposes export compare report button | `test_bwm_gamefs_batch_exporter.gd` |
| R2 | Model Editor exposes export compare report button | `test_mdl_workspace_editor.gd` |
| R3 | Compare handlers cache result; export uses `export_compare_result_to_path` | Source wiring |
| R4 | Docs mark Q123 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_exporter.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```
