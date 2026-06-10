---
title: "feat: Q83 batch TPC to TGA export"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q82-auto-selected
phase: Q83
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-014-feat-q82-texture-batch-converter-plan.md
  - docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md
---

# Q83: Batch TPC → TGA Export

## Summary

Add folder-level **batch TPC export** for modders converting texture packs. Scan a flat directory of `.tpc` files and export matching `.tga` files via the PyKotor `texture-convert` CLI bridge.

---

## Problem Frame

Q30/Q27 ship single-file TPC export via `texture-convert`. Holocron/PyKotor texture utilities batch-convert many `.tpc` files at once. The Godot plugin lacks a folder-level batch export path on `main`.

---

## Scope Boundaries

### In scope

- `TpcBatchExporter.batch_directory()` with per-file `texture-convert`, `skip_existing`, and `dry_run`
- TPC workspace editor **Batch Export TGA...** toolbar action
- Headless `tests/editor/test_tpc_batch_exporter.gd`
- Execution queue + parity matrix Q83 entry

### Deferred

- Install-scoped batch export from GameFS (Q81 separate PR)
- Native TPC→TGA decode without PyKotor CLI
- Recursive subfolder scan

### Out of scope

- DXT encode improvements
- TXI sidecar batch pairing

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_directory` discovers `.tpc` files in flat folder | Unit test |
| R2 | Each file builds valid `texture-convert` command in `dry_run` | Unit test |
| R3 | `skip_existing` skips present `.tga` outputs | Unit test |
| R4 | TPC editor exposes batch export button | Wiring test |
| R5 | Docs mark Q83 shipped | Doc diff |

---

## Implementation Units

### U1 — TpcBatchExporter

- **Files:** `formats/tpc_batch_exporter.gd`

### U2 — TPC editor batch action

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_batch_exporter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_batch_exporter.gd
```
