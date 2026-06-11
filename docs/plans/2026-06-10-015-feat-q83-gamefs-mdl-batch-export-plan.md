---
title: "feat: Q83 install-scoped GameFS MDL batch export"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q82-auto-selected
phase: Q83
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-014-feat-q82-gamefs-tpc-batch-import-plan.md
  - docs/plans/2026-05-29-023-feat-q18-module-designer-mdl-placement-plan.md
---

# Q83: Install-Scoped GameFS MDL Batch Export

## Summary

Add **GameFS-indexed batch MDL export** (with optional MDX sidecar) and a **model metadata helper** so modders can dump install models to a folder and see trimesh summaries — the first bounded **model helper** slice in the advanced utility tools track.

---

## Problem Frame

Texture batch utilities (Q79/Q81/Q82) cover install export/import loops. Model assets remain manual one-file exports. Holocron/PyKotor model utilities support batch extraction workflows; Godot needs a native install-indexed MDL dump without leaving the workspace.

---

## Scope Boundaries

### In scope

- `MdlGamefsBatchExporter.batch_install()` — enumerate indexed `.mdl` via `list_core_resources`, copy bytes to output folder, export paired `.mdx` when indexed
- `MdlModelMetadataHelper.summarize_bytes()` — vertex/face/bounds summary via `MDLParser`
- Resource browser **Batch Export Install MDL...** action with summary in detail panel
- Headless `tests/editor/test_mdl_gamefs_batch_exporter.gd`
- Execution queue + parity matrix Q83 entry

### Deferred

- MDL workspace editor / mesh preview tab
- Batch export from loaded LYT room list only
- MDL install-to-override batch import
- PyKotor model-convert CLI bridge

### Out of scope

- MDL writer / round-trip editing
- Module archive recursive extraction outside GameFS index

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install` discovers indexed `.mdl` entries | Unit test with seeded override |
| R2 | Each entry writes `.mdl` bytes; paired `.mdx` when present | Unit test |
| R3 | `skip_existing` skips present output `.mdl` | Unit test |
| R4 | `dry_run` reports planned exports without writing | Unit test |
| R5 | `MdlModelMetadataHelper` returns vertex/face counts for valid MDL | Unit test |
| R6 | Resource browser exposes batch export button | Wiring test |
| R7 | Docs mark Q83 shipped | Doc diff |

---

## Implementation Units

### U1 — GameFS MDL batch exporter

- **Files:** `formats/mdl_gamefs_batch_exporter.gd`
- **Pattern:** `formats/tpc_gamefs_batch_exporter.gd` (GameFS scan, result shape)

### U2 — Model metadata helper

- **Files:** `editor/tools/mdl_model_metadata_helper.gd`

### U3 — Resource browser action

- **Files:** `ui/workspace/panels/resource_browser_panel.gd`

### U4 — Tests + docs

- **Files:** `tests/editor/test_mdl_gamefs_batch_exporter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_gamefs_batch_exporter.gd
```
