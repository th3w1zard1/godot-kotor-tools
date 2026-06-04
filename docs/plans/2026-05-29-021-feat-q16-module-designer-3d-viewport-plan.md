---
title: Q16 Module Designer 3D Viewport
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q16
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q16: Module Designer 3D Viewport

## Summary

Add a **SubViewport-based 3D view** to the Module Designer workspace: GIT instance markers, optional LYT room layout overlay, camera orbit/pan, and three-way selection sync (tree ↔ 2D map ↔ 3D). Extend module bundle resolution for `lyt` and fix override-priority when multiple sources index the same module file.

## Problem frame

Q15 delivered 2D GIT authoring. Holocron `module_designer.py` uses a 3D scene for spatial reasoning (instances + LYT rooms + walkmeshes). Modders need height and room context before walkmesh/MDL work lands in later slices.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorWorldCoordinates` maps KotOR (X,Y horizontal, Z up) to Godot Y-up | Unit test |
| R2 | `ModuleDesignerViewport3D` renders GIT instances as pickable 3D markers | Headless scene test |
| R3 | LYT rooms drawn when module bundle includes `.lyt` and GameFS can load bytes | Context + viewport test |
| R4 | Selection sync: tree, map, 3D emit same category/index | Editor integration test |
| R5 | Camera orbit (drag) and zoom (wheel) on 3D viewport | Manual; smoke in test |
| R6 | `KotorModuleContext` includes `lyt`/`vis`/`pth` with override-first bundle pick | Context test |
| R7 | Parity matrix + execution queue mark Q16 shipped | Doc sync |

## Implementation units

### U1 — World coordinates (`editor/module/kotor_world_coordinates.gd`)

- `kotor_to_godot(Vector3)` / `godot_to_kotor(Vector3)`
- `kotor_bearing_to_yaw(float)` for marker orientation

### U2 — Module context extensions (`kotor_module_context.gd`)

- Add layout extensions to bundle; `_pick_best_entry` by source priority (override > modules > chitin).
- `load_parsed_layout(gamefs, bundle) -> Dictionary` via `LYTParser`.

### U3 — 3D viewport (`ui/workspace/panels/module_designer_viewport_3d.gd`)

- `SubViewportContainer` + `SubViewport`, `Camera3D`, lights.
- Rebuild markers from instance records; LYT room boxes from parsed layout.
- `instance_selected` signal; `set_selection` highlight.

### U4 — Workspace integration (`module_designer_workspace_editor.gd`)

- VSplit: map (top) + 3D (bottom) in right pane.
- Wire selection handlers both directions.

### U5 — Tests + docs

- `tests/editor/test_module_designer_viewport_3d.gd`
- Extend foundations context tests; update parity matrix + queue.

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
```

## Explicit non-goals (Q16)

- BWM walkmesh triangulation/rendering.
- MDL mesh loading in viewport.
- Indoor builder / kit placement.
- Instance drag-move and transform undo.
- Blender integration.

## Success criteria

- [x] Verification commands pass
- [x] Module Designer shows 3D view with GIT markers
- [x] LYT overlay when layout resource present
- [x] Docs reflect Q16 shipped
