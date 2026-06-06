---
title: "feat: Q65 Module Designer PTH connection overlay"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q64-auto-selected
phase: Q65
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-037-feat-q64-pth-point-overlay-plan.md
  - docs/plans/2026-06-05-033-feat-q60-pth-install-override-plan.md
  - docs/plans/2026-05-29-021-feat-q16-module-designer-3d-viewport-plan.md
---

# Q65: Module Designer PTH Connection Overlay

## Summary

Render loaded area path-graph connections in the Module Designer 2D map and 3D viewport so modders can inspect directed path edges instead of isolated points only.

---

## Problem Frame

Q64 added visible PTH point overlays, but the Module Designer still cannot show how those nodes connect. KotOR path graphs are meaningful as directed edges, and summary/point-only visualization still leaves path topology opaque.

---

## Scope Boundaries

### In scope

- Typed PTH connection extraction helpers for the loaded resource/document
- Module Designer map overlay for loaded PTH edges
- Module Designer 3D viewport overlay for loaded PTH edges
- Optional summary depth update for visible connection counts
- Headless `tests/editor/test_module_designer_pth_connection_overlay.gd`
- Execution queue + parity matrix Q65 entry

### Deferred

- PTH point/edge editing UI
- Pathfinding validation or simulation
- Generic GFF workspace PTH editing enhancements

### Out of scope

- Install/export behavior changes
- Walkmesh/layout editing changes
- Indoor Builder changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `PTHResource` exposes connection records from the loaded path graph with stable source/target coordinates | Unit test |
| R2 | Module Designer map renders loaded PTH edge overlays | Unit test |
| R3 | Module Designer 3D viewport renders loaded PTH edge overlays | Unit test |
| R4 | Path summary can report loaded connection depth when available | Unit test |
| R5 | Docs mark Q65 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_overlay.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_overlay.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
godot --headless --path . --script tests/editor/test_gff_resource_factory.gd
```
