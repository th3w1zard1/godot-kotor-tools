---
title: "feat: Q115 TPC recursive batch directory scan"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q114-auto-selected
phase: Q115
track: Texture/Media Tools
parent: docs/plans/2026-06-07-009-feat-q77-texture-batch-converter-plan.md
related:
  - formats/batch_directory_scanner.gd
  - formats/tpc_batch_converter.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q115: TPC Recursive Batch Directory Scan

## Summary

Add shared `BatchDirectoryScanner` and wire `recursive: true` through `TpcBatchConverter` so nested TGA/PNG folders convert without manual flattening.

---

## Problem Frame

Batch convert and folder→override import only scan the top level of a directory. Texture trees organized in subfolders are skipped — deferred across Q77–Q114.

---

## Scope Boundaries

### In scope

- `BatchDirectoryScanner.list_files(root, extensions, recursive)` utility
- `TpcBatchConverter.batch_directory` + `batch_directory_to_output` honor `recursive` option (default `false`)
- Recursive `batch_directory` writes `.tpc` beside each source image
- Recursive `batch_directory_to_output` flattens by resref; duplicate basenames across subfolders → `failed`
- TPC editor batch convert + folder override import pass `recursive: true`
- Headless `test_batch_directory_scanner.gd` + `test_tpc_batch_converter.gd` extensions
- Execution queue + parity matrix Q115 entry

### Deferred

- Recursive scan for WAV/BWM/MDL batch exporters
- Mirror output subfolder structure in override import

### Out of scope

- Symlink following

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Scanner lists nested files when `recursive: true` | `test_batch_directory_scanner.gd` |
| R2 | Flat scan unchanged when `recursive: false` | Unit test |
| R3 | Recursive `batch_directory` writes co-located `.tpc` | `test_tpc_batch_converter.gd` |
| R4 | Recursive `batch_directory_to_output` flattens to output dir | `test_tpc_batch_converter.gd` |
| R5 | Duplicate resref across subfolders reported as failed | `test_tpc_batch_converter.gd` |
| R6 | Editor passes `recursive: true` for batch convert + folder import | Source wiring |
| R7 | Docs mark Q115 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_batch_directory_scanner.gd
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
```
