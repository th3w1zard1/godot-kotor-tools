---
title: "feat: Q118 LIP/TPC export recursive batch directory scan"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q117-auto-selected
phase: Q118
track: Texture/Media Tools
parent: docs/plans/2026-06-10-049-feat-q117-bwm-mdl-recursive-batch-scan-plan.md
related:
  - formats/batch_directory_scanner.gd
  - formats/lip_batch_generator.gd
  - formats/tpc_batch_exporter.gd
  - ui/workspace/editors/lip_workspace_editor.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q118: LIP/TPC Export Recursive Batch Directory Scan

## Summary

Complete the recursive batch scan wave by wiring `BatchDirectoryScanner` through `LipBatchGenerator` and `TpcBatchExporter`, matching Q115–Q117.

---

## Problem Frame

Q115–Q117 added recursive scan for TPC convert, WAV, WOK/BWM, and MDL batch tools. LIP batch generation and TPC→TGA folder export still only scan the top level.

---

## Scope Boundaries

### In scope

- `LipBatchGenerator.batch_directory` honors `recursive` (writes `.lip` beside each nested `.wav`)
- `TpcBatchExporter.batch_directory` honors `recursive` (writes `.tga` beside each nested `.tpc`)
- LIP + TPC editor folder batch actions pass `recursive: true`
- Headless tests in `test_lip_batch_generator.gd`, `test_tpc_batch_exporter.gd`
- Execution queue + parity matrix Q118 entry

### Deferred

- Module/area designer parity wave
- Mirror nested output folder structure for flatten exports

### Out of scope

- GameFS install-indexed batch scan changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Recursive LIP batch writes `.lip` beside nested WAV sources | `test_lip_batch_generator.gd` |
| R2 | Recursive TPC export writes `.tga` beside nested TPC sources | `test_tpc_batch_exporter.gd` |
| R3 | Editors pass `recursive: true` for folder batch actions | Source wiring |
| R4 | Docs mark Q118 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_lip_batch_generator.gd
godot --headless --path . --script tests/editor/test_tpc_batch_exporter.gd
```
