---
title: "feat: Q85 MDL workspace 3D preview"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q84-auto-selected
phase: Q85
track: Texture/Media + Model Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-016-feat-q84-mdl-workspace-editor-plan.md
  - docs/plans/2026-05-29-023-feat-q18-module-designer-mdl-placement-plan.md
---

# Q85: MDL Workspace 3D Preview

## Summary

Add a **read-only 3D trimesh preview** to `KotorMDLWorkspaceEditor`, reusing `MDLParser` and the Module Designer mesh-surface pattern so modders can visually inspect models opened from the workspace.

---

## Problem Frame

Q84 shipped metadata and export/install for MDL workspace opens, but deferred 3D preview. Holocron model surfaces include visual inspection; without preview, modders must leave Godot to judge mesh shape.

---

## Scope Boundaries

### In scope

- `MdlMeshSurfaceBuilder` — shared ArrayMesh builder from parsed MDL dict
- `MdlPreviewViewport` — SubViewport panel with orbit camera + flat-shaded mesh
- Wire preview refresh into `KotorMDLWorkspaceEditor.open_mdl_bytes`
- Headless tests for mesh build + viewport wiring
- Execution queue + parity matrix Q85 entry

### Deferred

- Texture/material slots from MDL
- Animation / skinned mesh preview
- MDL editor mutation or mesh editing

### Out of scope

- MDL parser extensions beyond existing K1 trimesh path
- Module Designer viewport changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Valid MDL bytes produce non-empty ArrayMesh via `MdlMeshSurfaceBuilder` | Unit test |
| R2 | Invalid/empty MDL clears preview without crash | Unit test |
| R3 | MDL workspace editor shows preview viewport below metadata | Unit test |
| R4 | Preview camera fits parsed mesh bounds | Unit test (camera distance > 0) |
| R5 | Docs mark Q85 shipped | Doc diff |

---

## Implementation Units

### U1 — Mesh surface builder

- **Files:** `editor/tools/mdl_mesh_surface_builder.gd`

### U2 — Preview viewport panel

- **Files:** `ui/workspace/panels/mdl_preview_viewport.gd`

### U3 — Workspace editor wiring

- **Files:** `ui/workspace/editors/mdl_workspace_editor.gd`

### U4 — Tests + docs

- **Files:** `tests/editor/test_mdl_mesh_surface_builder.gd`, `tests/editor/test_mdl_workspace_editor.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_mesh_surface_builder.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```
