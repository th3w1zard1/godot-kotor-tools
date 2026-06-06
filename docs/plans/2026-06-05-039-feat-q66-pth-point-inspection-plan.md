---
title: "feat: Q66 Module Designer PTH point inspection"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q65-auto-selected
phase: Q66
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-037-feat-q64-pth-point-overlay-plan.md
  - docs/plans/2026-06-05-038-feat-q65-pth-connection-overlay-plan.md
  - docs/plans/2026-05-29-021-feat-q16-module-designer-3d-viewport-plan.md
---

# Q66: Module Designer PTH Point Inspection

## Summary

Make loaded area path points first-class inspectable items in Module Designer by surfacing them in the tree, allowing selection from tree/map/3D, and showing point detail with outgoing connection context.

---

## Problem Frame

Q64 and Q65 made loaded `.pth` graphs visible, but the data is still overlay-only. Modders can see dots and edges, yet cannot inspect a specific point as structured data, select it from the existing workspace surfaces, or understand its outgoing connections without reading raw resource bytes elsewhere.

---

## Scope Boundaries

### In scope

- Read-only path-point entries in the Module Designer tree
- Selection sync for path points across tree, 2D map, and 3D viewport
- Detail-panel rendering for path point coordinates, point id, and outgoing connection targets/count
- Highlighting of the selected path point in map/3D overlays
- Headless `tests/editor/test_module_designer_pth_point_inspection.gd`
- Execution queue + parity matrix Q66 entry

### Deferred

- Path-point or edge editing UI
- 3D picking for path edges
- Generic GFF workspace PTH editing enhancements
- Pathfinding validation or simulation

### Out of scope

- Install/export behavior changes
- Walkmesh/layout editing changes
- Indoor Builder changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer tree includes a read-only path-point group when `.pth` data is loaded | Headless editor test |
| R2 | Selecting a path point from the tree updates the detail panel with point id, coordinates, and outgoing connection info | Headless editor test |
| R3 | 2D map can highlight and select loaded path points | Headless editor test |
| R4 | 3D viewport can highlight and select loaded path points | Headless editor test |
| R5 | Docs mark Q66 shipped | Doc diff |

---

## Implementation Units

### U1 — Path-point selection model

- Files: `ui/workspace/editors/module_designer_workspace_editor.gd`, `resources/documents/kotor_pth_document.gd`
- Add a stable read-only selection path for loaded point records and helper formatting for outgoing connection summaries.

### U2 — Tree + detail surface

- Files: `ui/workspace/editors/module_designer_workspace_editor.gd`
- Add `Path Points` tree entries and route selection into the existing detail panel without breaking GIT instance selection flows.

### U3 — Map + viewport point picking/highlight

- Files: `ui/workspace/panels/module_designer_map_view.gd`, `ui/workspace/panels/module_designer_viewport_3d.gd`
- Let path points act as pickable/selected overlay items, with highlight rendering distinct from GIT instances.

### U4 — Regression coverage + docs

- Files: `tests/editor/test_module_designer_pth_point_inspection.gd`, `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`
- Add focused headless coverage and refresh the queue/matrix to mark Q66 shipped.

---

## Verification

```bash
godot --headless --quiet --check-only --script ui/workspace/editors/module_designer_workspace_editor.gd
godot --headless --quiet --check-only --script ui/workspace/panels/module_designer_map_view.gd
godot --headless --quiet --check-only --script ui/workspace/panels/module_designer_viewport_3d.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_overlay.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
```
