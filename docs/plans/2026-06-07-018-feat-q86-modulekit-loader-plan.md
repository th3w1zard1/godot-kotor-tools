---
title: "feat: Q86 ModuleKit loader for Indoor Builder"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q85-auto-selected
phase: Q86
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-017-feat-q85-gamefs-tpc-batch-export-plan.md
  - docs/plans/2026-05-29-028-feat-q23-indoor-kit-library-plan.md
---

# Q86: ModuleKit Loader for Indoor Builder

## Summary

Expose PyKotor/Holocron-style **ModuleKit** support in the Godot Indoor Builder: discover install modules with LYT data, synthesize kit-compatible room components from module bundles, and let modders place module rooms into `.indoor` layouts.

---

## Problem Frame

Q23 shipped on-disk indoor kit libraries. PyKotor `ModuleKit` dynamically builds kit components from game module LYT rooms. Indoor Builder cannot reuse existing module rooms without manually recreating kits.

---

## Scope Boundaries

### In scope

- `KotorModuleKitLoader.discover_module_roots()` + `load_module_kit()`
- LYT room → component records with model-based ids, WOK footprint, MDL/MDX presence
- `KotorIndoorKitLibrary.register_module_kits_from_gamefs()`
- Indoor Builder module-kit refresh + kit picker integration
- Headless `tests/editor/test_module_kit_loader.gd`

### Deferred

- BWM doorhook extraction for module component hooks
- Walkmesh local-space translation for export round-trip
- PyKotor CLI modulekit bridge

### Out of scope

- Full `IndoorMap.build()` native port changes
- Module Designer utility panels

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Loader discovers module roots with indexed LYT | Unit test |
| R2 | Loader builds kit with one component per LYT room | Unit test |
| R3 | Component footprint derives from room WOK when present | Unit test |
| R4 | Kit library registers module kits and `has_component` works | Unit test |
| R5 | Indoor Builder refresh surfaces module kits in picker | Wiring test |
| R6 | Docs mark Q86 shipped | Doc diff |

---

## Implementation Units

### U1 — ModuleKit loader

- **Files:** `resources/indoor/kotor_module_kit_loader.gd`

### U2 — Kit library + Indoor Builder wiring

- **Files:** `resources/indoor/kotor_indoor_kit_library.gd`, `ui/workspace/editors/indoor_builder_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_module_kit_loader.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_kit_loader.gd
```
