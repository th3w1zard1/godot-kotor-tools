---
title: "feat: Q137 Install archive to modules"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q137
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-067-feat-q136-erf-member-compare-override-plan.md
related:
  - resources/indoor/kotor_indoor_module_installer.gd
---

# Q137: Install Archive to Modules

## Summary

Let modders deploy the open ERF/RIM/MOD archive directly into the game `modules/` folder with mutation preflight — completing the archive authoring loop after Q134–Q136 add/save/compare.

## Problem Frame

Archive Browser can save and extract members, but cannot install a whole `.mod` into `modules/` like Indoor Builder’s module installer. Modders still copy files manually.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | **Install Archive to Modules** writes repacked archive bytes to `modules/{filename}` | `test_erf_workspace_editor.gd` |
| R2 | Preflight/rollback via `KotorMutationService` export path | Workspace editor test |
| R3 | `.sav` archives rejected for modules install | Workspace editor test |
| R4 | Queue marks Q137 shipped | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Target resolver | Reuse `KotorIndoorModuleInstaller.resolve_modules_path` | Existing modules path logic |
| Payload | `serialize_for_pipeline()` dictionary | Matches save/export serialize arm |
| Scope | MOD/ERF/RIM only | SAV is not a modules deployment target |

## Implementation Units

### U1. Workspace editor install UX

- `ui/workspace/editors/erf_workspace_editor.gd`

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
