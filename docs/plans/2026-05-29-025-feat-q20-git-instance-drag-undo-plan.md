---
title: Q20 GIT Instance Drag-Move and Undo
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q20
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q20: GIT Instance Drag-Move and Undo

## Summary

Enable **drag-moving GIT instances** on the Module Designer 2D map with **EditorUndoRedoManager** undo/redo, dirty tracking, and synchronized refresh across map, tree, detail panel, and 3D viewport.

## Problem frame

Q15–Q19 shipped read-only layout visualization (instances, walkmesh, room MDL, template meshes). Holocron's module designer allows repositioning placed objects on the area map. Q15 explicitly deferred drag-move and transform undo.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorGITDocument.set_instance_position` updates `XPosition`/`YPosition` (optional `ZPosition`) via GFF paths | Unit test |
| R2 | `ModuleDesignerMapView` supports left-drag on instances with `_screen_to_world` inverse mapping | Map interaction |
| R3 | Drag preview updates live; commit on mouse release when position changed | Manual / map code |
| R4 | `instance_drag_finished` wired to undoable `_exec_instance_position` in workspace editor | Editor wiring |
| R5 | `document.changed` marks dirty and refreshes views | Editor behavior |
| R6 | Parity matrix + execution queue mark Q20 shipped | Doc sync |

## Implementation units

### U1 — `resources/documents/kotor_git_document.gd`

- `set_instance_position(category, index, x, y, z = null) -> bool`
- Uses `set_field_at_path` on `[list_field, index, "XPosition"|"YPosition"|"ZPosition"]`

### U2 — `ui/workspace/panels/module_designer_map_view.gd`

- Signals: `instance_drag_updated`, `instance_drag_finished` (with old/new XY)
- Drag state + `_screen_to_world`
- Draw dragged instance at preview position

### U3 — `ui/workspace/editors/module_designer_workspace_editor.gd`

- Connect map drag signals and `document.changed`
- `_get_undo_redo`, `_exec_instance_position`, `_apply_instance_position_with_undo`

### U4 — Tests + docs

- `tests/editor/test_git_instance_position.gd`
- Update parity matrix and execution queue

## Explicit non-goals (Q20)

- Bearing rotation handles
- 3D viewport drag (map only)
- Add/delete instances
- Indoor builder
- BWM write-back

## Verification

```bash
godot --headless --path . --script tests/editor/test_git_instance_position.gd
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
```

## Acceptance

- [x] Document API + map drag + editor undo wired
- [x] Tests pass
- [x] Docs reflect Q20 shipped
