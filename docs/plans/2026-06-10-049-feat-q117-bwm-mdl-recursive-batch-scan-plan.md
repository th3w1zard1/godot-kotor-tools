---
title: "feat: Q117 BWM/MDL recursive batch directory scan"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q116-auto-selected
phase: Q117
track: Module/Model Tools
parent: docs/plans/2026-06-10-048-feat-q116-wav-recursive-batch-scan-plan.md
related:
  - formats/batch_directory_scanner.gd
  - formats/bwm_batch_exporter.gd
  - formats/mdl_batch_exporter.gd
  - ui/workspace/editors/module_designer_workspace_editor.gd
  - ui/workspace/editors/mdl_workspace_editor.gd
---

# Q117: BWM/MDL Recursive Batch Directory Scan

## Summary

Propagate `BatchDirectoryScanner` and `recursive: true` through WOK/BWM and MDL batch copy/import paths, matching Q115–Q116 behavior.

---

## Problem Frame

Q116 added recursive scan for WAV batch tools. WOK/BWM and MDL folder batch copy and override import still skip nested files.

---

## Scope Boundaries

### In scope

- `BwmBatchExporter.batch_directory` honors `recursive` (flatten to output, duplicate resref fails)
- `MdlBatchExporter.batch_directory` honors `recursive` (flatten MDL/MDX to output)
- Module Designer + Model Editor folder batch actions pass `recursive: true`
- Headless tests in `test_bwm_batch_exporter.gd`, `test_bwm_gamefs_batch_importer.gd`, `test_mdl_batch_exporter.gd`, `test_mdl_gamefs_batch_importer.gd`
- Execution queue + parity matrix Q117 entry

### Deferred

- Mirror nested output folder structure in override import
- Install-indexed GameFS scan changes

### Out of scope

- Symlink following

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Recursive WOK/BWM export flattens nested files to output dir | `test_bwm_batch_exporter.gd` |
| R2 | Recursive MDL export flattens nested MDL/MDX to output dir | `test_mdl_batch_exporter.gd` |
| R3 | Duplicate resref across subfolders fails on recursive flatten | Exporter/importer tests |
| R4 | Editors pass `recursive: true` for folder batch actions | Source wiring |
| R5 | Docs mark Q117 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_batch_exporter.gd
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_importer.gd
godot --headless --path . --script tests/editor/test_mdl_batch_exporter.gd
godot --headless --path . --script tests/editor/test_mdl_gamefs_batch_importer.gd
```
