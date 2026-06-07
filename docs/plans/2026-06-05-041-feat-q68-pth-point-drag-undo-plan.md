---
title: "feat: Q68 Module Designer PTH point drag-move and undo"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q67-auto-selected
phase: Q68
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-037-feat-q64-pth-point-overlay-plan.md
  - docs/plans/2026-06-05-039-feat-q66-pth-point-inspection-plan.md
  - docs/plans/2026-05-29-025-feat-q20-git-instance-drag-undo-plan.md
---

# Q68: Module Designer PTH Point Drag-Move and Undo

## Summary

Make loaded area path points editable on the Module Designer 2D map by supporting drag-move with undo-safe document mutation, synchronized detail/overlay refresh, and install-ready persistence through the existing PTH write-back flow.

---

## Problem Frame

Q64-Q67 completed the PTH visibility and inspection loop, but the graph is still read-only once loaded into Module Designer. Modders can now see and inspect specific points and edges, yet still have to leave Godot or edit raw GFF data to reposition a waypoint. The next useful parity step is the first bounded edit path: move a path point on the 2D map and keep the changed `.pth` resource installable.

---

## Scope Boundaries

### In scope

- `KotorPTHDocument` point-position mutation helpers for loaded path points
- 2D map drag-move for selected path points
- Undo-safe point move execution in Module Designer, matching existing GIT drag semantics when editor undo is available
- Synchronized refresh of point detail, path-edge overlays, and 3D viewport after point moves
- Dirty-state handling for PTH edits so modified graphs are not treated as read-only
- Install round-trip coverage proving moved points persist through **Install PTH to Override**
- Headless `tests/editor/test_module_designer_pth_point_drag.gd`
- Execution queue + parity matrix Q68 entry

### Deferred

- 3D point dragging
- Path connection editing or re-wiring
- Creating/removing path points
- Generic GFF workspace PTH editing UX

### Out of scope

- GIT instance editing changes
- LYT/VIS/walkmesh editing changes
- Indoor Builder changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer can mutate a loaded PTH point's X/Y position through a typed document API | Headless editor test |
| R2 | Dragging a path point on the 2D map updates point detail and connected overlays in map and 3D | Headless editor test |
| R3 | PTH edits mark the workspace dirty until the modified graph is installed | Headless editor test |
| R4 | Installing the moved PTH graph writes updated point coordinates to override | Headless editor test |
| R5 | Docs mark Q68 shipped | Doc diff |

---

## Implementation Units

### U1 — Typed point mutation support

- Files: `resources/documents/kotor_pth_document.gd`, `resources/typed/pth_resource.gd`
- Add stable point-position mutation helpers that preserve existing field-name variants and mutate the loaded resource in-place.

### U2 — Map drag interaction

- Files: `ui/workspace/panels/module_designer_map_view.gd`
- Let path points participate in left-drag interactions with live preview, while keeping current instance drag and connection selection behavior intact.

### U3 — Module Designer edit orchestration

- Files: `ui/workspace/editors/module_designer_workspace_editor.gd`
- Wire path-point drag completion into undo-safe execution, refresh selection/detail state, and track PTH-specific dirty/install lifecycle.

### U4 — Regression coverage + docs

- Files: `tests/editor/test_module_designer_pth_point_drag.gd`, `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`
- Add focused headless coverage and refresh planning docs to mark Q68 shipped.

---

## Verification

```bash
godot --headless --quiet --check-only --script resources/documents/kotor_pth_document.gd
godot --headless --quiet --check-only --script ui/workspace/panels/module_designer_map_view.gd
godot --headless --quiet --check-only --script ui/workspace/editors/module_designer_workspace_editor.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_drag.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_install.gd
```
