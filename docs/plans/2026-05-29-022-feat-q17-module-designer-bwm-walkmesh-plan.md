---
title: Q17 Module Designer BWM Walkmesh Overlay
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q17
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q17: Module Designer BWM Walkmesh Overlay

## Summary

Parse KotOR **BWM/WOK** walkmesh binaries and render a **semi-transparent triangle overlay** in the Module Designer 3D viewport. Load the module's area `.wok` from GameFS (override-first), color faces by walkable vs non-walkable surface material, and fit the camera to walkmesh bounds alongside GIT/LYT content.

## Problem frame

Q16 added GIT markers and LYT room boxes but no collision geometry. Holocron `module_designer.py` imports `pykotor.resource.formats.bwm.BWM` for spatial authoring. Modders need walkable surfaces visible before MDL placement and indoor-builder work (Q18+).

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `BWMParser.parse_bytes` reads BWM V1.0 vertices, face indices, materials | Unit test with synthetic WOK |
| R2 | `is_walkable_material` matches KotOR walkable surface IDs | Unit test |
| R3 | `KotorModuleContext` resolves `wok` in module bundle and `load_parsed_walkmesh` | Integration test with override file |
| R4 | `ModuleDesignerViewport3D` builds mesh from parsed walkmesh with KotOR→Godot coords | Viewport test |
| R5 | Module Designer loads area walkmesh when `.wok` present in bundle | Editor smoke test |
| R6 | Camera fit includes walkmesh vertex bounds | Viewport behavior |
| R7 | Parity matrix + execution queue mark Q17 shipped | Doc sync |

## Implementation units

### U1 — `formats/bwm_parser.gd`

Binary reader aligned with PyKotor `io_bwm._load_bwm_legacy` header layout (136-byte header, vertex/index/material tables). Returns `{ walkmesh_type, position, vertices, faces }`.

### U2 — `kotor_module_context.gd`

- Add `wok` to `MODULE_EXTENSIONS`.
- `load_parsed_walkmesh(gamefs, bundle)`.

### U3 — `module_designer_viewport_3d.gd`

- `_walkmesh_root`, `set_walkmesh(parsed: Dictionary)`.
- `SurfaceTool` triangle mesh; walkable=green, unwalkable=red alpha.

### U4 — `module_designer_workspace_editor.gd`

- Load walkmesh in `_refresh_module_bundle` / `_refresh_viewport_3d`.

### U5 — Tests + docs

- `tests/editor/test_bwm_parser.gd`
- Extend `test_module_designer_viewport_3d.gd`
- Update parity matrix + execution queue.

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_parser.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
```

## Explicit non-goals (Q17)

- BWM write-back / editing.
- AABB, adjacency, edges, perimeters parsing.
- Room-component WOK merge (MDL placement is Q18+).
- Walkmesh picking or transform tools.
- ASCII BWM format.

## Success criteria

- [x] Verification commands pass
- [x] Module Designer 3D view shows walkmesh when `.wok` indexed
- [x] Docs reflect Q17 shipped
