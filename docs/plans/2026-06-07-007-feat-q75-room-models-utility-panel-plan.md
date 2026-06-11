---
title: "feat: Q75 Module Designer room models utility panel"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q74-auto-selected
phase: Q75
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-006-feat-q74-module-bundle-utility-panel-plan.md
  - docs/plans/2026-06-04-026-feat-q53-lyt-depth-overlay-plan.md
---

# Q75: Module Designer Room Models Utility Panel

## Summary

Add a **Room Models** utility tree to Module Designer that lists unique LYT room models with MDL/MDX/WOK presence, detail context, and open-on-activate routing to workspace editors.

---

## Problem Frame

Q74 surfaces bundle files but not per-room model assets. Holocron's area tools list room models with asset presence (MDL/MDX/WOK). Modders editing a module still cannot inspect or open room model assets from Module Designer without the legacy dock.

---

## Scope Boundaries

### In scope

- `KotorModuleContext.get_room_model_entries()` and `format_room_model_presence()`
- Module Designer **Room Models** tree with detail on selection and open on activate
- Reuse `bundle_resource_open_requested` for MDL open routing
- Headless `tests/editor/test_module_designer_room_models_utility_panel.gd`
- Execution queue + parity matrix Q75 entry

### Deferred

- Open MDX/WOK from room model row (MDL primary)
- Room model mesh preview thumbnails
- SET tileset utility

### Out of scope

- LYT mutation
- New MDL parser work

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `get_room_model_entries` dedupes LYT rooms and reports asset presence | Unit test |
| R2 | Module Designer shows room models when LYT loaded | Headless editor test |
| R3 | Selecting a room model shows position + presence in detail panel | Headless editor test |
| R4 | Activating indexed MDL emits `bundle_resource_open_requested` | Headless editor test |
| R5 | Docs mark Q75 shipped | Doc diff |

---

## Implementation Units

### U1 — Room model entry helper

- **Files:** `editor/module/kotor_module_context.gd`

### U2 — Utility panel UI

- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** test, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_room_models_utility_panel.gd
godot --headless --path . --script tests/editor/test_module_designer_bundle_utility_panel.gd
```
