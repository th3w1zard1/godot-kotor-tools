---
title: "feat: Q79 batch TPC to TGA export"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q78-auto-selected
phase: Q79
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-010-feat-q78-modulekit-loader-plan.md
  - docs/plans/2026-05-29-032-feat-q27-media-tooling-plan.md
---

# Q79: Batch TPC → TGA Export

## Summary

Ship folder-level **batch TPC export** via the existing PyKotor `texture-convert` CLI bridge, and expose **Batch Export TGA...** in the TPC workspace editor.

---

## Problem Frame

Q27 ships single-file TPC→TGA export. Holocron/PyKotor texture batch utilities help modders convert many `.tpc` files without repetitive per-file export. The Godot plugin has no folder-level TPC export path.

---

## Scope Boundaries

### In scope

- `TpcBatchExporter.batch_directory()` — flat `.tpc` scan, per-file `texture-convert` via `KotorMediaToolBridge`
- TPC editor **Batch Export TGA...** toolbar action with summary status
- Headless `tests/editor/test_tpc_batch_exporter.gd` using `dry_run` command building
- Execution queue + parity matrix Q79 entry

### Deferred

- Install-scoped batch export from GameFS index
- Native TPC→TGA decode without PyKotor CLI
- Recursive subfolder scan

### Out of scope

- Batch image→TPC import (Q77 on separate branch)
- DXT batch encode

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_directory` discovers `.tpc` files in flat folder | Unit test |
| R2 | Each file builds valid `texture-convert` command | `dry_run` test |
| R3 | `skip_existing` skips present `.tga` outputs | Unit test |
| R4 | TPC editor exposes batch export button | Wiring test |
| R5 | Docs mark Q79 shipped | Doc diff |

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
