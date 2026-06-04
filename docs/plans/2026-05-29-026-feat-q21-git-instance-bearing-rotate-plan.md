---
title: Q21 GIT Instance Bearing Rotate and Undo
type: feat
status: completed
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q21
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q21: GIT Instance Bearing Rotate and Undo

## Summary

Enable **right-drag bearing rotation** for GIT instances on the Module Designer 2D map with **EditorUndoRedoManager** undo/redo, live preview, and synchronized refresh across map, detail panel, tree, and 3D viewport.

## Problem frame

Q20 shipped drag-move for GIT instances. Holocron's module designer exposes a **Rotate** tool with gizmo drag (`_begin_object_rotate_gizmo_drag`). Q20 explicitly deferred bearing rotation. Instances already render bearing arrows on the map and yaw in the 3D viewport; modders need to edit orientation without leaving the map.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Interaction | Right-drag on map instance | Left-drag is move (Q20); avoids new toolbar tool for this slice |
| Bearing semantics | `atan2(dy, dx)` from instance XY to cursor world XY | Matches "face cursor" authoring; consistent with visible bearing arrow |
| GFF write | `Bearing` float via `set_field_at_path` | Matches existing `_read_bearing` primary path and test fixtures |
| Quaternion-only instances | Out of scope | Rare in shipped GIT; add conversion in a later slice if needed |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorGITDocument.set_instance_bearing` updates `Bearing` via GFF path | Unit test |
| R2 | `ModuleDesignerMapView` right-drag rotates with live preview | Map interaction code |
| R3 | `instance_rotate_finished` wired to undoable `_exec_instance_bearing` | Editor wiring |
| R4 | `document.changed` refreshes map + 3D bearing | Existing dirty path |
| R5 | Parity matrix + execution queue mark Q21 shipped | Doc sync |

## Implementation units

### U1 — `resources/documents/kotor_git_document.gd`

- `set_instance_bearing(category, index, bearing: float) -> bool`

### U2 — `ui/workspace/panels/module_designer_map_view.gd`

- Signals: `instance_rotate_updated`, `instance_rotate_finished` (old/new bearing)
- Right-drag state, preview bearing in `_draw_instance`
- `_bearing_from_world_point(instance_xy, cursor_xy) -> float`

### U3 — `ui/workspace/editors/module_designer_workspace_editor.gd`

- Connect rotate signals
- `_apply_instance_bearing_with_undo`, `_exec_instance_bearing`

### U4 — Tests + docs

- `tests/editor/test_git_instance_bearing.gd`
- Update parity matrix and execution queue

## Explicit non-goals (Q21)

- Indoor builder (Holocron `indoor_builder/` — dedicated later slice)
- 3D viewport rotate gizmo
- Add/delete instances
- Quaternion field write-back
- BWM write-back

## Verification

```bash
godot --headless --path . --script tests/editor/test_git_instance_bearing.gd
godot --headless --path . --script tests/editor/test_git_instance_position.gd
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
```

## Acceptance

- [x] Document API + map rotate + editor undo wired
- [x] Tests pass
- [x] Docs reflect Q21 shipped
