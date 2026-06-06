---
title: "feat: Q64 Module Designer PTH point overlay"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q63-auto-selected
phase: Q64
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-033-feat-q60-pth-install-override-plan.md
  - docs/plans/2026-06-05-036-feat-q63-pth-preview-export-plan.md
  - docs/plans/2026-05-29-021-feat-q16-module-designer-3d-viewport-plan.md
---

# Q64: Module Designer PTH Point Overlay

## Summary

Render loaded area path-graph points in the Module Designer 2D map and 3D viewport so modders can spatially inspect `.pth` data already loaded by the module bundle.

---

## Problem Frame

Q60 and Q63 completed the PTH load/install/export loop, but the Module Designer still treats path-graph data as summary-only metadata. Modders can write the resource back out, yet cannot see where the loaded points live relative to the area layout and placed instances.

---

## Scope Boundaries

### In scope

- Typed point extraction helpers for `PTHResource` / `KotorPTHDocument`
- Module Designer map overlay for loaded PTH points
- Module Designer 3D viewport overlay for loaded PTH points
- Bounds/camera wiring so overlays remain visible when points extend beyond placed-instance bounds
- Headless `tests/editor/test_module_designer_pth_overlay.gd`
- Execution queue + parity matrix Q64 entry

### Deferred

- PTH edge/connection rendering
- PTH editing UI
- Generic GFF workspace PTH editing enhancements

### Out of scope

- Walkmesh/layout editing changes
- New serializer or install/export behavior changes
- Indoor Builder changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `PTHResource` exposes loaded point records with stable coordinate extraction | Unit test |
| R2 | Module Designer map renders loaded PTH point overlays | Unit test |
| R3 | Module Designer 3D viewport renders loaded PTH point overlays | Unit test |
| R4 | Overlay bounds/camera include PTH points so off-instance graphs remain visible | Unit test |
| R5 | Docs mark Q64 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_overlay.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
godot --headless --path . --script tests/editor/test_gff_resource_factory.gd
```
