---
title: "feat: Q81 install-scoped TPC batch export"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q80-auto-selected
phase: Q81
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-012-feat-q80-resref-references-finder-plan.md
  - docs/plans/2026-06-07-011-feat-q79-batch-tpc-export-plan.md
---

# Q81: Install-Scoped TPC Batch Export

## Summary

Add **GameFS-indexed batch TPC→TGA export** so modders can dump install textures (override-first or filtered source) to a folder via the existing PyKotor `texture-convert` CLI bridge — complementing Q79's flat-directory batch export.

---

## Problem Frame

Holocron/PyKotor texture utilities can batch-convert textures from an installation. Q79 covers folder-based `.tpc` scan; modders browsing the indexed install still need a one-click path to export many indexed `.tpc` resources without manually locating files on disk.

---

## Scope Boundaries

### In scope

- `TpcGamefsBatchExporter.batch_install()` — enumerate `.tpc` via `KotorGameFS.list_core_resources`, load bytes, export to output folder
- Source filter (`override` default, empty = all indexed sources)
- `skip_existing`, `dry_run`, `limit`, optional resref query
- TPC workspace editor **Batch Export Install TGA...** toolbar action
- Headless `tests/editor/test_tpc_gamefs_batch_exporter.gd`
- Execution queue + parity matrix Q81 entry

### Deferred

- Native TPC→TGA decode without PyKotor CLI
- Batch import (TGA/PNG→TPC) from GameFS — covered by Q77 on separate PR
- Recursive module archive extraction outside GameFS index

### Out of scope

- DXT encode improvements
- Resource browser bulk actions (TPC editor only this slice)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install` discovers indexed `.tpc` entries | Unit test with seeded override |
| R2 | Each entry builds valid `texture-convert` command in `dry_run` | Unit test |
| R3 | `skip_existing` skips present output `.tga` files | Unit test |
| R4 | TPC editor exposes install batch export button | Wiring test |
| R5 | Docs mark Q81 shipped | Doc diff |

---

## Implementation Units

### U1 — GameFS batch exporter

- **Files:** `formats/tpc_gamefs_batch_exporter.gd`
- **Pattern:** Follow `formats/tpc_batch_exporter.gd` (Q79) command building via `KotorMediaToolBridge`; input from `gamefs.load_resource_entry_bytes` written to temp when no direct path

### U2 — TPC editor action

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`
- **Pattern:** Q79 `_batch_export_tga` folder picker flow; use `_editor_state.gamefs` + output dir picker

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_gamefs_batch_exporter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_exporter.gd
```
