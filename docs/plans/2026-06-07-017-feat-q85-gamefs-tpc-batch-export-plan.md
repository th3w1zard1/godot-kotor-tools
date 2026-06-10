---
title: "feat: Q85 install-scoped TPC batch export"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q84-auto-selected
phase: Q85
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-016-feat-q84-resref-references-finder-plan.md
  - docs/plans/2026-06-07-015-feat-q83-batch-tpc-export-plan.md
---

# Q85: Install-Scoped TPC Batch Export

## Summary

Add **GameFS-indexed batch TPC→TGA export** so modders can dump install textures (override-indexed) to a folder via the PyKotor `texture-convert` CLI bridge.

---

## Problem Frame

Q83 covers folder-based batch export; modders browsing the indexed install still need a one-click path to export many indexed `.tpc` resources without manually locating files on disk.

---

## Scope Boundaries

### In scope

- `TpcGamefsBatchExporter.batch_install()` — enumerate `.tpc` via GameFS, load bytes, export to output folder
- Source filter (`override` default)
- `skip_existing`, `dry_run`, `limit`, optional resref query
- TPC workspace editor **Batch Export Install TGA...** toolbar action
- Headless `tests/editor/test_tpc_gamefs_batch_exporter.gd`
- Execution queue + parity matrix Q85 entry

### Deferred

- Native TPC→TGA decode without PyKotor CLI
- Full-install source filters (modules/chitin)
- Recursive module archive extraction outside GameFS index

### Out of scope

- Folder batch import (Q82 separate PR)
- DXT encode improvements

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install` discovers indexed `.tpc` entries | Unit test with seeded override |
| R2 | Each entry builds valid `texture-convert` command in `dry_run` | Unit test |
| R3 | `skip_existing` skips present output `.tga` files | Unit test |
| R4 | TPC editor exposes install batch export button | Wiring test |
| R5 | Docs mark Q85 shipped | Doc diff |

---

## Implementation Units

### U1 — GameFS batch exporter

- **Files:** `formats/tpc_gamefs_batch_exporter.gd`

### U2 — TPC editor action

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_gamefs_batch_exporter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_exporter.gd
```
