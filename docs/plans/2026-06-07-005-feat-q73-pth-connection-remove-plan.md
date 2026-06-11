---
title: "feat: Q73 Module Designer PTH connection remove"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q72-auto-selected
phase: Q73
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-004-feat-q72-pth-connection-add-plan.md
  - docs/plans/2026-06-07-003-feat-q71-pth-point-remove-plan.md
---

# Q73: Module Designer PTH Connection Remove

## Summary

Make loaded area path graphs support **removing individual edges** in Module Designer via toolbar action on the selected connection, with topology rebuild, snapshot undo, and install-ready persistence.

---

## Problem Frame

Q72 adds connections and Q71 removes points (clearing incident edges), but modders cannot delete a single edge without removing a point or raw GFF editing. The next bounded topology edit is filter-one-edge removal using `_rebuild_connection_topology`.

---

## Scope Boundaries

### In scope

- `KotorPTHDocument.remove_connection(connection_index) -> bool`
- Toolbar **Remove Path Connection** when a connection is selected
- Snapshot undo via `capture_topology_snapshot()` / `restore_topology_snapshot()`
- `_pth_dirty` tracking and install round-trip coverage
- Headless `tests/editor/test_module_designer_pth_connection_remove.gd`
- Execution queue + parity matrix Q73 entry

### Deferred

- Bulk edge removal
- Connection property editing beyond destination
- 3D connection authoring

### Out of scope

- Point add/remove changes
- GIT/LYT/VIS/walkmesh changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `remove_connection` filters one edge and rebuilds adjacency metadata | Headless editor test |
| R2 | Toolbar removes selected connection and clears selection | Headless editor test |
| R3 | Remove marks workspace dirty until installed | Headless editor test |
| R4 | Installed graph persists removal | Headless editor test |
| R5 | Docs mark Q73 shipped | Doc diff |

---

## Implementation Units

### U1 — Typed `remove_connection` API

- **Files:** `resources/documents/kotor_pth_document.gd`, `resources/typed/pth_resource.gd`
- **Approach:** Collect surviving edges excluding `connection_index`, call `_rebuild_connection_topology`.

### U2 — Toolbar + orchestration

- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`
- **Approach:** Add toolbar button after Add Path Connection; `_remove_selected_path_connection()` with snapshot undo; clear selection overlays after remove.

### U3 — Tests + docs

- **Files:** `tests/editor/test_module_designer_pth_connection_remove.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_remove.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_add.gd
```
