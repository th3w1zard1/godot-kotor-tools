---
title: Q18 Module Designer MDL Room Mesh Placement
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q18
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q18: Module Designer MDL Room Mesh Placement

## Summary

Add a **read-only K1 MDL trimesh parser** and render **LYT room models** in the Module Designer 3D viewport as flat-shaded triangle meshes at each room's layout position. Fall back to blue box markers when a model cannot be loaded or parsed.

## Problem frame

Q17 added area walkmesh overlay. Holocron's module designer visualizes room geometry from MDL assets referenced by LYT. Without MDL placement, modders only see placeholder boxes and cannot judge spatial layout against real room meshes.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `MDLParser.parse_bytes` extracts merged trimesh vertices/faces from K1 MDL (+ optional MDX) | Unit test with synthetic MDL |
| R2 | `MDLParser.compute_bounds` returns KotOR-space AABB for camera fit | Unit test |
| R3 | `KotorModuleContext.load_parsed_model_mesh` resolves `mdl`/`mdx` via GameFS | Integration test with override files |
| R4 | `ModuleDesignerViewport3D.set_room_meshes` renders meshes at room positions with KotOR→Godot coords | Viewport test |
| R5 | Module Designer loads room meshes from LYT `model` names when MDL indexed | Editor wiring |
| R6 | Camera fit includes room mesh bounds; blue box fallback when mesh missing | Viewport behavior |
| R7 | Parity matrix + execution queue mark Q18 shipped | Doc sync |

## Implementation units

### U1 — `formats/mdl_parser.gd`

K1-focused reader aligned with PyKotor `io_mdl._GeometryHeader`, `_NodeHeader`, `_TrimeshHeader`, `_Face`. Traverse node tree, apply node transforms, merge trimesh geometry. Skip skin/dangly/AABB trees beyond required header skips.

### U2 — `kotor_module_context.gd`

- `load_parsed_model_mesh(gamefs, model_resref)` loads MDL+MDX pair.

### U3 — `module_designer_viewport_3d.gd`

- `_room_mesh_root`, `set_room_meshes(entries: Dictionary)`.
- Flat-shaded `SurfaceTool` meshes; fallback boxes for missing meshes.

### U4 — `module_designer_workspace_editor.gd`

- Build room mesh map in `_refresh_module_bundle`, pass to viewport in `_refresh_viewport_3d`.

### U5 — Tests + docs

- `tests/editor/test_mdl_parser.gd` with synthetic MDL builder
- Extend `test_module_designer_viewport_3d.gd`
- Update parity matrix + execution queue.

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_parser.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
```

## Explicit non-goals (Q18)

- Full MDL authoring/write-back (master plan Q21).
- GIT instance template → appearance → model resolution.
- Textures/materials on meshes (flat shading only).
- K2-specific trimesh tail, skin rigging, saber meshes.
- Indoor builder (later queue item).

## Success criteria

- [x] Verification commands pass
- [x] Module Designer 3D shows room MDL meshes when `.mdl` indexed for LYT room names
- [x] Docs reflect Q18 shipped
