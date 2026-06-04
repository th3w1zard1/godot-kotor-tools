---
title: Q15 Module Designer Foundations
type: feat
status: active
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q15
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q15: Module / Area Designer Foundations

## Summary

Introduce a dedicated **Module Designer** workspace tab for `.git` area-layout files: typed instance extraction, a 2D placement map, instance browser tree, module bundle context (ARE/IFO/GIT resrefs), and save/install on the existing GFF mutation path. This is the Godot-native foundation for Holocron `module_designer.py` parity (Q16 adds SubViewport 3D, LYT/BWM, indoor builder).

## Problem frame

`.git` files currently open in the generic GFF Entity Editor tree. Holocron treats GIT as a spatial authoring surface (instances by category with positions). Modders need at-a-glance layout before Q16 3D work.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `.git` from resource browser opens Module Designer tab (not GFF Entity Editor) | Shell routing test |
| R2 | `KotorGITDocument` exposes flat instance records with position + template + category | `test_module_designer_foundations.gd` |
| R3 | Module Designer shows 2D map + instance tree with selection sync | Manual + headless document tests |
| R4 | `KotorModuleContext` resolves related ARE/IFO/GIT entries by module resref | Context test |
| R5 | Save/install round-trip for GIT uses mutation service | Headless install test |
| R6 | Session restore supports `editor_kind == "module"` | Shell restore match arm |
| R7 | Parity matrix + execution queue mark Q15 shipped | Doc sync |

## Implementation units

### U1 — GIT instance model (`kotor_git_document.gd`)

- `get_instance_records()` → typed rows with category, path, X/Y/Z, TemplateResRef, Tag.
- `get_layout_bounds()` for map fit.
- Category colors for map rendering.

### U2 — Module context (`editor/module/kotor_module_context.gd`)

- `module_resref_from_file_name`, `find_module_bundle(gamefs, resref)`.

### U3 — Map view (`ui/workspace/panels/module_designer_map_view.gd`)

- `Control` drawing instances; click-to-select.

### U4 — Module Designer editor (`module_designer_workspace_editor.gd`)

- `open_git_bytes` / save / install; HSplit map + tree; toolbar.

### U5 — Routing (`kotor_workspace_shell.gd`, legacy dock delegation unchanged)

- Route `extension == "git"` before generic GFF branch.
- Session restore `"module"` arm.

### U6 — Tests + docs

- `tests/editor/test_module_designer_foundations.gd`
- Update parity matrix + execution queue

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
godot --headless --path . --script tests/editor/test_gff_workspace_editor.gd
```

## Explicit non-goals (Q15)

- SubViewport 3D rendering, MDL placement, walkmesh overlay (Q16).
- Indoor builder, drag-move instances, undo for transforms.
- Holocron module designer UI clone.

## Success criteria

- [x] Verification commands pass
- [x] `.git` opens Module Designer from browser
- [x] Docs reflect Q15 shipped
