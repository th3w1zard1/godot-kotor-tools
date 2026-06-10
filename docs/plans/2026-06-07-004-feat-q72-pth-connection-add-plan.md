---
title: "feat: Q72 Module Designer PTH connection add"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q71-auto-selected
phase: Q72
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-003-feat-q71-pth-point-remove-plan.md
  - docs/plans/2026-06-07-001-feat-q69-pth-connection-retarget-plan.md
---

# Q72: Module Designer PTH Connection Add

## Summary

Make loaded area path graphs support **new edges** in Module Designer by appending connections from a selected source point to a clicked target point, with topology rebuild, snapshot undo, and install-ready persistence.

---

## Problem Frame

Q69 retargets existing edges and Q71 removes points safely, but modders still cannot create new connections between path points without raw GFF editing. The next bounded topology edit is append-only connection insertion using the existing `_rebuild_connection_topology` machinery.

---

## Scope Boundaries

### In scope

- `KotorPTHDocument.add_connection(source_index, target_index) -> int`
- Toolbar **Add Path Connection** armed flow: selected source point + click target point
- Snapshot undo via `capture_topology_snapshot()` / `restore_topology_snapshot()`
- `_pth_dirty` tracking and install round-trip coverage
- Headless `tests/editor/test_module_designer_pth_connection_add.gd`
- Execution queue + parity matrix Q72 entry

### Deferred

- Remove path connection as standalone operation (Q73)
- Duplicate-edge policy beyond simple reject
- 3D connection authoring

### Out of scope

- Point add/remove changes
- GIT/LYT/VIS/walkmesh changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `add_connection` appends an edge and rebuilds adjacency metadata | Headless editor test |
| R2 | Toolbar-armed map flow adds connection from selected source to clicked target | Headless editor test |
| R3 | Add marks workspace dirty until installed | Headless editor test |
| R4 | Installed graph persists new connection | Headless editor test |
| R5 | Docs mark Q72 shipped | Doc diff |

---

## Implementation Units

### U1 — Typed `add_connection` API

- **Files:** `resources/documents/kotor_pth_document.gd`, `resources/typed/pth_resource.gd`
- **Approach:** Collect existing edges, append new edge, call `_rebuild_connection_topology`; reject self-loops and duplicates.

### U2 — Map armed add interaction

- **Files:** `ui/workspace/panels/module_designer_map_view.gd`
- **Approach:** When add-connection armed and source point selected, clicking a different point emits `path_connection_add_requested`.

### U3 — Toolbar + orchestration

- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`
- **Approach:** Add toolbar button, snapshot undo, select new connection after add.

### U4 — Tests + docs

- **Files:** `tests/editor/test_module_designer_pth_connection_add.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_add.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_remove.gd
```
