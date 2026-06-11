---
title: "feat: Q71 Module Designer PTH point remove"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q70-auto-selected
phase: Q71
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-002-feat-q70-pth-point-add-plan.md
  - docs/plans/2026-06-05-041-feat-q68-pth-point-drag-undo-plan.md
---

# Q71: Module Designer PTH Point Remove

## Summary

Make loaded area path graphs shrink safely in Module Designer by supporting **remove path point** for the selected waypoint, with topology-aware connection cleanup, undo via graph snapshot restore, synchronized overlay/detail refresh, and install-ready persistence.

---

## Problem Frame

Q70 added append-only point insertion, but `remove_point` was only used for add-undo and performed naive array removal without fixing the adjacency list. Modders cannot delete stray waypoints while keeping `Destination`, `Conections`, and `First_Conection` coherent.

---

## Scope Boundaries

### In scope

- Topology-safe `KotorPTHDocument.remove_point(index)` that drops incident edges and remaps surviving `Destination` indices
- `capture_topology_snapshot()` / `restore_topology_snapshot()` for undo of destructive edits
- Toolbar **Remove Path Point** for the currently selected path point
- Undo-safe remove with snapshot restore
- `_pth_dirty` tracking and install round-trip coverage
- Headless `tests/editor/test_module_designer_pth_point_remove.gd`
- Execution queue + parity matrix Q71 entry

### Deferred

- Add/remove path connections as standalone operations
- Delete key binding
- 3D point removal

### Out of scope

- GIT instance editing changes
- LYT/VIS/walkmesh editing changes
- Indoor Builder changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Removing a point drops incident connections and remaps surviving destination indices | Headless editor test |
| R2 | Toolbar remove deletes the selected path point and refreshes tree/map/3D | Headless editor test |
| R3 | Remove edits mark workspace dirty until installed | Headless editor test |
| R4 | Installed graph persists topology-safe removal | Headless editor test |
| R5 | Docs mark Q71 shipped | Doc diff |

---

## Key Technical Decisions

1. **Rebuild flat connection list** after filtering/remapping edges, preserving per-point `Conections`/`First_Conection` invariants.
2. **Snapshot undo** — capture points + connections arrays before remove; restore on undo (handles complex topology).
3. **Toolbar UX** — remove operates on current path-point selection from map/tree/3D sync.

---

## Implementation Units

### U1 — Topology-safe remove + snapshot helpers

- **Files:** `resources/documents/kotor_pth_document.gd`, `resources/typed/pth_resource.gd`
- **Approach:** Filter `get_connection_records()`, remap indices, remove point, rebuild `Path_Conections` and per-point metadata.

### U2 — Toolbar remove + orchestration

- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`
- **Approach:** `Remove Path Point` button; `_apply_path_point_remove_with_undo` using snapshot restore for undo.

### U3 — Regression coverage + docs

- **Files:** `tests/editor/test_module_designer_pth_point_remove.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_point_remove.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_add.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_retarget.gd
```
