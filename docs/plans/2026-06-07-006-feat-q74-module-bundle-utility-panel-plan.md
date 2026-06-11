---
title: "feat: Q74 Module Designer bundle resources utility panel"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q73-auto-selected
phase: Q74
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-020-feat-q15-module-designer-foundations-plan.md
  - docs/plans/2026-06-07-005-feat-q73-pth-connection-remove-plan.md
---

# Q74: Module Designer Bundle Resources Utility Panel

## Summary

Add a **Module Resources** utility tree to Module Designer that lists indexed bundle files (GIT/ARE/IFO/LYT/VIS/PTH/WOK) with source status and opens the selected resource in the appropriate workspace editor.

---

## Problem Frame

Q15–Q73 built deep GIT/PTH editing inside Module Designer, but modders still jump to the legacy Area Tools dock or resource browser to open sibling module files. Holocron's module designer surfaces related area resources inline; the next bounded utility slice mirrors the dock's related-resource tree inside the Module Designer left panel.

---

## Scope Boundaries

### In scope

- `KotorModuleContext.get_bundle_resource_entries(bundle) -> Array[Dictionary]`
- Module Designer **Module Resources** tree with availability/source labels
- `bundle_resource_open_requested` signal wired to workspace shell `_open_workspace_entry`
- Headless `tests/editor/test_module_designer_bundle_utility_panel.gd`
- Execution queue + parity matrix Q74 entry

### Deferred

- Inline preview/summary for each bundle resource type
- Open-from-panel for room model MDL entries
- SET tileset resources (dock-only today)

### Out of scope

- GIT/PTH mutation changes
- New parsers or install flows

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `get_bundle_resource_entries` lists all module extensions with availability | Unit test |
| R2 | Module Designer tree shows bundle resources after GIT open | Headless editor test |
| R3 | Activating an indexed entry emits `bundle_resource_open_requested` | Headless editor test |
| R4 | Workspace shell routes signal to `_open_workspace_entry` | Wiring |
| R5 | Docs mark Q74 shipped | Doc diff |

---

## Implementation Units

### U1 — Bundle entry helper

- **Files:** `editor/module/kotor_module_context.gd`
- **Approach:** Return ordered records with extension, label, description, entry dict, available flag.

### U2 — Utility panel UI + signal

- **Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`
- **Approach:** Tree under left panel header; refresh on bundle reload; item_activated emits open signal when entry available.

### U3 — Shell wiring + tests + docs

- **Files:** `ui/workspace/kotor_workspace_shell.gd`, test, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_bundle_utility_panel.gd
godot --headless --path . --script tests/editor/test_module_designer_foundations.gd
```
