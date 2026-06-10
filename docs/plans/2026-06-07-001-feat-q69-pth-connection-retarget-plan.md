---
title: "feat: Q69 Module Designer PTH connection retarget"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q68-auto-selected
phase: Q69
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-040-feat-q67-pth-connection-inspection-plan.md
  - docs/plans/2026-06-05-041-feat-q68-pth-point-drag-undo-plan.md
  - docs/plans/2026-06-05-039-feat-q66-pth-point-inspection-plan.md
---

# Q69: Module Designer PTH Connection Retarget

## Summary

Make loaded area path **connection destinations** editable in Module Designer by supporting retarget of an existing edge to a different path point, with undo-safe typed mutation, synchronized overlay/detail refresh, and install-ready persistence through the existing PTH write-back flow.

---

## Problem Frame

Q64–Q68 completed the PTH visibility, inspection, and first edit loop for **points** (drag-move). Q67 made connections inspectable across tree/map/3D, but topology is still immutable: modders can see which point an edge connects to, yet cannot change that destination without leaving Godot or editing raw GFF bytes. The next bounded topology edit is **retargeting** an existing connection's `Destination` field to another valid point index.

---

## Scope Boundaries

### In scope

- `KotorPTHDocument.set_connection_destination(connection_index, target_index) -> bool` with field-name variant tolerance
- Module Designer retarget flow: select a path connection, then click a target path point on the 2D map to retarget
- Undo-safe retarget execution matching existing GIT/PTH `_apply_*_with_undo` / `_exec_*` pattern
- Synchronized refresh of connection detail, tree labels, map/3D edge overlays after retarget
- `_pth_dirty` tracking so modified graphs are not treated as read-only
- Install round-trip coverage proving retargeted destinations persist through **Install PTH to Override**
- Headless `tests/editor/test_module_designer_pth_connection_retarget.gd`
- Execution queue + parity matrix Q69 entry

### Deferred

- Add/remove path connections (array surgery on `Path_Conections` + per-point `Conections`/`First_Conection`)
- Add/remove path points (index remapping cascade)
- 3D point or connection editing
- Generic GFF workspace PTH editing UX
- Self-loop or duplicate-edge validation beyond basic bounds checks

### Out of scope

- GIT instance editing changes
- LYT/VIS/walkmesh editing changes
- Indoor Builder changes
- Pathfinding validation or simulation

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer can mutate a loaded PTH connection's destination through a typed document API | Headless editor test |
| R2 | Retargeting a connection from map interaction updates connection detail and connected overlays in map and 3D | Headless editor test |
| R3 | PTH retarget edits mark the workspace dirty until the modified graph is installed | Headless editor test |
| R4 | Installing the retargeted PTH graph writes updated destination indices to override | Headless editor test |
| R5 | Docs mark Q69 shipped | Doc diff |

---

## Key Technical Decisions

1. **Scalar retarget only** — Q69 writes the existing connection struct's `Destination`/`Target`/`To` field via `set_field_at_path`. No array insert/remove; connection indices remain stable.
2. **Map-driven UX** — After selecting a connection, clicking a path point on the 2D map retargets the edge. This mirrors Q67 selection sync and avoids a detail-panel-only workflow.
3. **Index validation** — Reject retarget when `target_index` is out of bounds or equals `source_index` (no self-loops in this slice).
4. **Undo boundary** — One retarget gesture = one `EditorUndoRedoManager` action with `MERGE_DISABLE`, matching Q68 point drag semantics.

---

## Implementation Units

### U1 — Typed connection destination mutation

- **Goal:** Expose a stable API to change a connection's target point index.
- **Requirements:** R1
- **Files:** `resources/documents/kotor_pth_document.gd`, `resources/typed/pth_resource.gd`
- **Approach:** Resolve connection record by flat `connection_index`, build path `[connection_field, index, destination_field]`, write via `set_field_at_path`. Validate bounds and reject self-target.
- **Patterns to follow:** `set_point_position` field-alias resolution; `get_connection_records()` index semantics.
- **Test scenarios:**
  - Happy path: retarget connection 0 from point 1 to point 2; `get_connection_records()` reflects new `target_index` and derived coords.
  - Edge case: invalid connection index returns false without mutation.
  - Edge case: out-of-bounds target index returns false.
  - Edge case: self-target (source == target) returns false.
- **Verification:** Document API returns true only when field write succeeds; connection records update without requiring overlay rebuild hacks.

### U2 — Map retarget interaction

- **Goal:** Let modders retarget a selected connection by clicking a target point on the 2D map.
- **Requirements:** R2
- **Dependencies:** U1
- **Files:** `ui/workspace/panels/module_designer_map_view.gd`
- **Approach:** When `_selected_path_connection_index >= 0`, clicking a path point emits `path_connection_retarget_requested(connection_index, target_index)`. Preserve existing instance drag, point drag, and connection/point selection behaviors.
- **Patterns to follow:** `path_connection_selected` signal pattern; path-point picking from Q66/Q68.
- **Test scenarios:**
  - Happy path: with connection selected, point click emits retarget signal with correct indices.
  - Edge case: point click with no connection selected does not emit retarget signal.
  - Integration: instance drag and point drag still work when no connection is selected.
- **Verification:** Signal-driven headless test can drive retarget without real mouse input.

### U3 — Module Designer retarget orchestration

- **Goal:** Wire retarget into undo, dirty state, selection, and detail refresh.
- **Requirements:** R2, R3
- **Dependencies:** U1, U2
- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`
- **Approach:** Connect map retarget signal; implement `_apply_path_connection_retarget_with_undo` / `_exec_path_connection_retarget`; re-select connection; refresh tree labels, detail panel, map/3D overlays; set `_pth_dirty`.
- **Patterns to follow:** `_apply_path_point_position_with_undo` from Q68; `_select_path_connection` from Q67.
- **Test scenarios:**
  - Happy path: retarget updates detail label source/target summary and tree connection label.
  - Happy path: map and viewport `_selected_path_connection_index` stay aligned after retarget.
  - Integration: retarget after point drag still shows correct derived edge coordinates.
- **Verification:** Headless editor test drives signal and asserts dirty + detail + overlay coherence.

### U4 — Regression coverage + docs

- **Goal:** Ship Q69 with focused tests and planning doc sync.
- **Requirements:** R4, R5
- **Dependencies:** U1, U2, U3
- **Files:** `tests/editor/test_module_designer_pth_connection_retarget.gd`, `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`
- **Approach:** Clone Q68 test scaffold (temp install root, seeded `.pth`, editor setup, install round-trip). Add install persistence assertion for retargeted `Destination`.
- **Test scenarios:**
  - Install round-trip: retarget → install → parse override bytes → verify destination index persisted.
- **Verification:** Full PTH regression suite from Q60–Q68 still passes.

---

## Verification

```bash
godot --headless --quiet --check-only --script resources/documents/kotor_pth_document.gd
godot --headless --quiet --check-only --script ui/workspace/panels/module_designer_map_view.gd
godot --headless --quiet --check-only --script ui/workspace/editors/module_designer_workspace_editor.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_retarget.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_drag.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_install.gd
```
