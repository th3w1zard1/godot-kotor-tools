---
title: "feat: Holocron parity Wave E/F — BWM depth + MDL geometry"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q158-Q161
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - ui/workspace/editors/module_designer_workspace_editor.gd
  - formats/bwm_parser.gd
  - formats/mdl_writer.gd
  - ui/workspace/editors/mdl_workspace_editor.gd
---

# Wave E/F: Spatial Authoring — BWM + MDL (Q158–Q161)

## Summary

Beyond Q126 BWM paint foundations and Q133 MDL passthrough write-back, deliver Holocron `bwm.py` and `mdl.py` functional depth for K1 modding.

## Wave E — BWM walkmesh (Q158–Q159)

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | Triangle add/remove, edge operations | Q158 |
| R2 | Material/face-type painting beyond walkable toggle | Q158 |
| R3 | 2D map interactive walkmesh edit parity | Q158 |
| R4 | Walkmesh validation before install (holes, islands) | Q159 |
| R5 | Tests extending `test_module_designer_bwm_paint.gd` | Both |

**Files:**
- `module_designer_workspace_editor.gd` — BWM edit toolbar
- `formats/bwm_parser.gd` / `bwm_writer.gd` — mutation + serialize
- `tests/editor/test_module_designer_bwm_paint.gd`

## Wave F — MDL geometry (Q160–Q161)

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | Trimesh mutation API (vertex/face ops) | Q160 |
| R2 | Rebuild MDL/MDX from edited mesh (not byte passthrough) | Q161 |
| R3 | Workspace toolbar for geometry ops + validation | Q160 |
| R4 | Round-trip: edit → serialize → parse → compare | Q161 |

**Files:**
- `formats/mdl_parser.gd` — editable mesh intermediate
- `formats/mdl_writer.gd` — geometry rebuild path
- `mdl_workspace_editor.gd` — geometry toolbar
- `tests/editor/test_mdl_workspace_editor.gd`

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_bwm_paint.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```

## Out of scope

- Blender bridge (separate program track)
- Full Holocron MDL UI clone
