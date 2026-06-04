---
title: Q22 Indoor Builder Foundations
type: feat
status: complete
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q22
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q22: Indoor Builder Foundations

## Summary

Add a dedicated **Indoor Builder** workspace tab that opens, edits, and saves Holocron/PyKotor-compatible **`.indoor` JSON** maps with a 2D room layout view, room tree selection, drag-move and right-drag rotation with undo, and session restore.

## Problem frame

Holocron's indoor builder (`HolocronToolset/src/toolset/gui/windows/indoor_builder/`) authors `.indoor` files consumed by PyKotor `IndoorMap.write()` / `load()`. The Godot plugin has Module Designer for `.git` but no path for indoor kit-based module authoring. Q22 establishes the document model, I/O parity, and map editing shell so later slices can add kit libraries, hooks, and `.mod` export.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| File format | UTF-8 JSON matching PyKotor `IndoorMapDataDict` | Holocron interchange; round-trip with embedded components |
| Document model | `KotorIndoorDocument` on raw dict + embedded index | Avoid premature Kit/KitComponent port; preserve unknown JSON keys |
| Footprint | BWM bounds from embedded `bwm` base64 when parseable | Reuses `BWMParser`; 2 m default half-extents fallback |
| UX shell | Mirror Module Designer: tree + 2D map + toolbar Open/Save | Established workspace patterns |
| Persistence | Direct filesystem write (not GameFS mutation) | `.indoor` is external project file in Holocron workflows |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorIndoorMapIO` parses/serializes `.indoor` JSON | Unit test round-trip |
| R2 | `KotorIndoorDocument` exposes room records, bounds, position/rotation mutations | Unit tests |
| R3 | `IndoorBuilderMapView` draws rooms, drag-move, right-drag rotate | Map view + editor wiring |
| R4 | `IndoorBuilderWorkspaceEditor` Open/Save, undo, dirty refresh | Editor + headless tests |
| R5 | Workspace shell tab + session restore `editor_kind == "indoor"` | Shell wiring |
| R6 | Parity matrix + execution queue mark Q22 shipped | Doc sync |

## Implementation units

### U1 — `resources/indoor/kotor_indoor_map_io.gd`

- Constants: `EMBEDDED_KIT_ID = "__embedded__"`
- `parse_bytes`, `write_bytes` (pretty JSON)

### U2 — `resources/documents/kotor_indoor_document.gd`

- Load/save from dict; `get_room_records`, `get_layout_bounds`
- `set_room_position`, `set_room_rotation`
- Footprint from embedded BWM or defaults

### U3 — `ui/workspace/panels/indoor_builder_map_view.gd`

- Room polygons, selection, drag/rotate signals (GIT map pattern)

### U4 — `ui/workspace/editors/indoor_builder_workspace_editor.gd`

- Toolbar Open/Save, room tree, map wiring, `EditorUndoRedoManager`

### U5 — `ui/workspace/kotor_workspace_shell.gd`

- Indoor Builder tab, session restore

### U6 — Tests + docs

- `tests/editor/test_indoor_builder_foundations.gd`
- Update parity matrix and execution queue

## Explicit non-goals (Q22)

- Kit downloader / on-disk kit library loading
- Hook connection UI and door insertion
- `IndoorMap.build()` module `.mod` export
- 3D tile preview / Blender integration
- ModuleKit (`module_root`) resolution

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_builder_foundations.gd
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
```

## Acceptance

- [x] Document API + map interactions + editor undo wired
- [x] Tests pass
- [x] Docs reflect Q22 shipped
