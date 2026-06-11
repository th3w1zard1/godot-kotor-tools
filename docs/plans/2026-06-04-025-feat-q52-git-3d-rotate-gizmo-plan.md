---
title: "feat: Q52 GIT 3D rotate gizmo"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q51-next-3d-rotate-slice
phase: Q52
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-026-feat-q21-git-instance-bearing-rotate-plan.md
  - docs/plans/2026-05-29-025-feat-q20-git-instance-drag-move-plan.md
---

# Q52: GIT 3D Rotate Gizmo

## Summary

Add a visible bearing ring gizmo and Shift+right-drag rotation in `ModuleDesignerViewport3D`, wired to existing GIT bearing undo, completing the Q21-deferred 3D rotate path.

---

## Problem Frame

Q21 shipped 2D map right-drag bearing rotate. The 3D viewport still only orbits on right-drag. Modders editing orientation in 3D need a gizmo and rotation interaction without leaving the viewport.

---

## Scope Boundaries

### In scope

- Shared bearing helpers on `KotorWorldCoordinates`
- 3D viewport bearing ring gizmo for selected instance
- Shift+right-drag rotate with live preview + `instance_rotate_finished` signal
- Editor wiring to existing `_apply_instance_bearing_with_undo`
- Headless `tests/editor/test_git_viewport_bearing.gd`
- Execution queue + parity matrix Q52 entry

### Deferred

- Dedicated rotate toolbar tool
- Quaternion field write-back
- Left-drag gizmo handle picking

### Out of scope

- Indoor builder rotation
- BWM write-back

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Bearing from Kotor XY offset matches map semantics | Unit test |
| R2 | Godot ray → Kotor XY plane intersection helper | Unit test |
| R3 | Viewport emits rotate finished with old/new bearing | Wiring |
| R4 | Selected instance shows bearing ring gizmo | Viewport code |
| R5 | Docs mark Q52 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_git_viewport_bearing.gd
godot --headless --path . --script tests/editor/test_git_instance_bearing.gd
```
