---
title: "feat: Q70 Module Designer PTH point add"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q69-auto-selected
phase: Q70
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-001-feat-q69-pth-connection-retarget-plan.md
  - docs/plans/2026-06-05-041-feat-q68-pth-point-drag-undo-plan.md
---

# Q70: Module Designer PTH Point Add

## Summary

Make loaded area path graphs grow in Module Designer by supporting **add path point** via toolbar-armed map placement, with undo-safe typed mutation, synchronized overlay/detail refresh, and install-ready persistence through the existing PTH write-back flow.

---

## Problem Frame

Q64–Q69 completed PTH visibility, inspection, point drag-move, and connection retarget, but the graph cannot grow: modders still cannot add new waypoints without editing raw GFF bytes. The next bounded topology edit is append-only point insertion at a chosen map coordinate.

---

## Scope Boundaries

### In scope

- `KotorPTHDocument.add_point(x, y, z?) -> int` with field-name variant tolerance and sane defaults (`ID`, `Conections: 0`, `First_Conection` at next connection slot)
- Toolbar **Add Path Point** button that arms single-shot map placement mode
- Map click on empty space (no instance/point/connection hit) places a new point and disarms
- Undo-safe add execution using `remove_struct_from_array` on undo
- Synchronized refresh of tree, detail panel, map/3D overlays after add
- `_pth_dirty` tracking and install round-trip coverage
- Headless `tests/editor/test_module_designer_pth_point_add.gd`
- Execution queue + parity matrix Q70 entry

### Deferred

- Remove path point (index remapping cascade)
- Add/remove path connections
- 3D point placement
- Generic GFF workspace PTH editing UX

### Out of scope

- GIT instance editing changes
- LYT/VIS/walkmesh editing changes
- Indoor Builder changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module Designer can append a loaded PTH point through a typed document API | Headless editor test |
| R2 | Toolbar-armed map placement adds a point at clicked world coordinates and selects it | Headless editor test |
| R3 | PTH add edits mark the workspace dirty until the modified graph is installed | Headless editor test |
| R4 | Installing the expanded PTH graph writes the new point to override | Headless editor test |
| R5 | Docs mark Q70 shipped | Doc diff |

---

## Key Technical Decisions

1. **Append-only** — new points insert at `get_point_count()` with `Conections: 0` and no new connection structs.
2. **Field alias mirroring** — probe an existing point (or canonical KotOR names) so new structs match the loaded file's spelling variants.
3. **ID assignment** — `max(existing IDs) + 1`, falling back to `index + 1` when no IDs exist.
4. **Armed placement UX** — toolbar toggles single-shot mode; successful placement or explicit cancel disarms.

---

## Implementation Units

### U1 — Typed point add mutation

- **Goal:** Expose stable append API for path points.
- **Requirements:** R1
- **Files:** `resources/documents/kotor_pth_document.gd`, `resources/typed/pth_resource.gd`
- **Approach:** Build default struct, `insert_struct_at_array` at end, return new index or -1 on failure.
- **Test scenarios:** Happy path append; empty graph first point; field variant preservation from existing points.

### U2 — Map placement interaction

- **Goal:** Place points from armed map clicks on empty space.
- **Requirements:** R2
- **Dependencies:** U1
- **Files:** `ui/workspace/panels/module_designer_map_view.gd`
- **Approach:** `set_add_path_point_armed(bool)`, `path_point_add_requested(x, y)` signal; when armed and no pick hit, emit world coords and disarm.
- **Test scenarios:** Armed empty click emits signal; disarmed click does not; picks still work when not armed.

### U3 — Toolbar + orchestration

- **Goal:** Wire add flow with undo and dirty state.
- **Requirements:** R2, R3
- **Dependencies:** U1, U2
- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`
- **Approach:** Add toolbar button; `_apply_path_point_add_with_undo` / `_exec_path_point_add`; undo removes inserted index via `remove_struct_from_array`.
- **Test scenarios:** Point count increases; new point selected; detail shows coordinates; tree updates.

### U4 — Regression coverage + docs

- **Goal:** Ship Q70 with tests and planning doc sync.
- **Requirements:** R4, R5
- **Dependencies:** U1, U2, U3
- **Files:** `tests/editor/test_module_designer_pth_point_add.gd`, `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_point_add.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_retarget.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_drag.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_install.gd
```
