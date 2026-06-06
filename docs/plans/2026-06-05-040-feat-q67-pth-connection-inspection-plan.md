---
title: "feat: Q67 Module Designer PTH connection inspection"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q66-auto-selected
phase: Q67
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-038-feat-q65-pth-connection-overlay-plan.md
  - docs/plans/2026-06-05-039-feat-q66-pth-point-inspection-plan.md
  - docs/plans/2026-05-29-021-feat-q16-module-designer-3d-viewport-plan.md
---

# Q67: Module Designer PTH Connection Inspection

## Summary

Make loaded area path connections first-class inspectable items in Module Designer by surfacing them in the tree, allowing selection from tree/map/3D, and showing connection detail with source and target point context.

---

## Problem Frame

Q65 made `.pth` edges visible and Q66 made points inspectable, but connections are still overlay-only. Modders can see topology lines, yet cannot inspect a specific edge as structured data, select it from existing workspace surfaces, or confirm which source and target nodes a highlighted segment represents without reading raw resource bytes.

---

## Scope Boundaries

### In scope

- Read-only path-connection entries in the Module Designer tree
- Selection sync for path connections across tree, 2D map, and 3D viewport
- Detail-panel rendering for connection index, source/target point ids, source/target coordinates, and adjacency summary
- Highlighting of the selected path connection in map/3D overlays
- 3D connection picking for the rendered path-edge overlay
- Headless `tests/editor/test_module_designer_pth_connection_inspection.gd`
- Execution queue + parity matrix Q67 entry

### Deferred

- Path-point or edge editing UI
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
| R1 | Module Designer tree includes a read-only path-connection group when `.pth` data is loaded | Headless editor test |
| R2 | Selecting a connection updates the detail panel with source/target ids and coordinates | Headless editor test |
| R3 | 2D map can highlight and select loaded path connections | Headless editor test |
| R4 | 3D viewport can highlight and select loaded path connections | Headless editor test |
| R5 | Docs mark Q67 shipped | Doc diff |

---

## Implementation Units

### U1 — Path-connection selection model

- Files: `ui/workspace/editors/module_designer_workspace_editor.gd`
- Add a stable read-only selection path for loaded connection records and helper formatting for source/target summaries.

### U2 — Tree + detail surface

- Files: `ui/workspace/editors/module_designer_workspace_editor.gd`
- Add `Path Connections` tree entries and route selection into the existing detail panel without breaking GIT instance or path-point selection flows.

### U3 — Map + viewport connection picking/highlight

- Files: `ui/workspace/panels/module_designer_map_view.gd`, `ui/workspace/panels/module_designer_viewport_3d.gd`
- Let path connections act as pickable/selected overlay items, with highlight rendering distinct from point and GIT selection.

### U4 — Regression coverage + docs

- Files: `tests/editor/test_module_designer_pth_connection_inspection.gd`, `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`
- Add focused headless coverage and refresh the queue/matrix to mark Q67 shipped.

---

## Verification

```bash
godot --headless --quiet --check-only --script ui/workspace/editors/module_designer_workspace_editor.gd
godot --headless --quiet --check-only --script ui/workspace/panels/module_designer_map_view.gd
godot --headless --quiet --check-only --script ui/workspace/panels/module_designer_viewport_3d.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_overlay.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
```
