---
title: "feat: Q84 MDL workspace editor (read-only inspector)"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q83-auto-selected
phase: Q84
track: Texture/Media + Model Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-015-feat-q83-gamefs-mdl-batch-export-plan.md
  - docs/plans/2026-05-29-023-feat-q18-module-designer-mdl-placement-plan.md
---

# Q84: MDL Workspace Editor (Read-Only Inspector)

## Summary

Ship a **read-only MDL workspace editor** with trimesh metadata, MDX sidecar awareness, filesystem export, and override install — and route indexed `.mdl` opens from the resource browser and Module Designer.

---

## Problem Frame

Q83 added batch MDL export and metadata helpers, but opening a model still falls through to the legacy shell. Holocron exposes model inspection surfaces; modders need in-workspace MDL context without leaving Godot.

---

## Scope Boundaries

### In scope

- `KotorMDLWorkspaceEditor` — metadata panel via `MdlModelMetadataHelper`, MDX byte summary, passthrough export/install
- Workspace routing for `.mdl` entries (load paired MDX from GameFS when indexed)
- Resource browser detail enrichment for selected `.mdl` rows
- Headless `tests/editor/test_mdl_workspace_editor.gd`
- Execution queue + parity matrix Q84 entry

### Deferred

- 3D mesh preview viewport tab
- MDL mutation / writer round-trip
- MDX workspace tab

### Out of scope

- MDL parser extensions
- PyKotor model-convert CLI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `open_mdl_bytes` renders metadata for valid K1 trimesh MDL | Unit test |
| R2 | Invalid MDL shows actionable error status | Unit test |
| R3 | Export/install use passthrough bytes via mutation service | Unit test or wiring |
| R4 | Resource browser `.mdl` open routes to MDL editor tab | Routing test |
| R5 | Resource browser detail shows metadata for selected MDL | Unit test |
| R6 | Docs mark Q84 shipped | Doc diff |

---

## Implementation Units

### U1 — MDL workspace editor

- **Files:** `ui/workspace/editors/mdl_workspace_editor.gd`

### U2 — Workspace shell routing + tab

- **Files:** `ui/workspace/kotor_workspace_shell.gd`

### U3 — Resource browser MDL detail

- **Files:** `ui/workspace/panels/resource_browser_panel.gd`, `editor/navigation/kotor_resource_locator.gd`

### U4 — Tests + docs

- **Files:** `tests/editor/test_mdl_workspace_editor.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```
