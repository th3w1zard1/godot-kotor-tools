---
title: Q19 GIT Instance Template Model Resolution
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q19
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q19: GIT Instance Template → MDL Resolution

## Summary

Resolve **Creatures**, **Placeables**, and **Doors** GIT instances to **MDL meshes** in the Module Designer 3D viewport by loading blueprint GFF (`utc`/`utp`/`utd`), looking up appearance rows in game **2DA** tables, and rendering meshes at instance position and bearing. Fall back to colored cube markers when resolution or load fails.

## Problem frame

Q18 placed **LYT room** MDL meshes. GIT instances still render as generic markers. Holocron's module designer resolves creature/placeable/door templates through `appearance.2da`, `placeables.2da`, and `genericdoors.2da` before drawing model geometry.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorTemplateModelResolver.resolve_model_resref` maps category + template resref → model resref | Unit test with synthetic UTC/UTP/UTD + 2DA |
| R2 | Creature: `Appearance_Type` → `appearance.2da` (`modeltype` B → `modela`, else `race`) | Unit test |
| R3 | Placeable: `Appearance_Type` → `placeables.2da` → `modelname` | Unit test |
| R4 | Door: `GenericType` / `Appearance_Type` → `genericdoors.2da` → `modelname` | Unit test |
| R5 | `ModuleDesignerViewport3D.set_instance_meshes` renders MDL at instance transform | Viewport test |
| R6 | Module Designer loads instance meshes on refresh; marker fallback when missing | Editor wiring |
| R7 | Camera fit includes instance mesh bounds | Viewport behavior |
| R8 | Parity matrix + execution queue mark Q19 shipped | Doc sync |

## Implementation units

### U1 — `editor/module/kotor_template_model_resolver.gd`

- Category → extension map (`Creatures`→`utc`, `Placeables`→`utp`, `Doors`→`utd`).
- Load blueprint via GameFS + `GFFParser` + `GFFResourceFactory`.
- Cached 2DA parse per game path (`appearance`, `placeables`, `genericdoors`).
- Normalize invalid model tokens (`""`, `****`, `*`).

### U2 — `module_designer_workspace_editor.gd`

- `_load_instance_meshes(gamefs, records)` with template and mesh caches.
- Call from `_refresh_viewport_3d`.

### U3 — `module_designer_viewport_3d.gd`

- `set_instance_meshes`, `_instance_mesh_by_key`.
- MDL surface on pickable markers; expanded collision radius from bounds.
- `_fit_camera_to_content` includes instance meshes.

### U4 — Tests + docs

- `tests/editor/test_template_model_resolver.gd`
- Extend `test_module_designer_viewport_3d.gd`
- Update parity matrix and execution queue.

## Explicit non-goals (Q19)

- Creature armor/head/weapon model variants.
- Sounds, triggers, waypoints, encounters, stores as meshes.
- GIT drag/undo or write-back.
- Indoor builder (later slice).

## Verification

```bash
godot --headless --path . --script tests/editor/test_template_model_resolver.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
```

## Acceptance

- [x] Resolver + viewport + editor wired
- [x] Tests pass
- [x] Docs reflect Q19 shipped
