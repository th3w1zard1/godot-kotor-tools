---
title: "feat: Q57 indoor MOD install to modules"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q56-next-indoor-mod-install-slice
phase: Q57
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-028-feat-q55-native-indoor-mod-export-default-plan.md
  - docs/plans/2026-06-04-021-feat-q48-indoor-mod-builder-plan.md
---

# Q57: Indoor MOD Install to Modules

## Summary

Add `KotorIndoorModuleInstaller` to build a native indoor `.mod` and write it into the configured game install's `modules/` folder, with **Install MOD to Modules** in Indoor Builder.

---

## Problem Frame

Q55 made native MOD export the default save-to-disk path. Holocron/PyKotor indoor-build also places playable modules in the game `modules/` directory. Modders still need a one-click install after layout validation without manually copying exported files.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_module_installer.gd`
- `KotorGameFS.ensure_modules_path()` helper
- Indoor Builder **Install MOD to Modules** toolbar action
- Headless `tests/editor/test_indoor_module_installer.gd`
- Execution queue + parity matrix Q57 entry

### Deferred

- Mutation-service preflight dialog for modules install (use pipeline backup via `export_payload_to_path`)
- Module Designer LYT install to override
- PyKotor CLI install path

### Out of scope

- Override folder MOD install (KotOR loads custom modules from `modules/`)
- In-editor module picker UI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Preflight requires valid layout, kits when needed, game path, and writable modules directory | Unit test |
| R2 | Install writes `{module_id}.mod` with core resources into `modules/` | Unit test |
| R3 | Existing module file gets `.bak` backup before overwrite | Unit test |
| R4 | Indoor Builder toolbar triggers install | Wiring |
| R5 | Docs mark Q57 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_module_installer.gd
godot --headless --path . --script tests/editor/test_indoor_native_exporter.gd
```
