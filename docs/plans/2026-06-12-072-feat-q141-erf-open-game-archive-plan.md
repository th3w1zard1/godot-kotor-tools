---
title: "feat: Q141 ERF open game archive dialog"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q141
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-071-feat-q140-erf-export-selected-member-plan.md
related:
  - ui/kotor_dock.gd
  - editor/core/kotor_editor_state.gd
---

# Q141: Open Game Archive Dialog

## Summary

Add **Open Game Archive...** in Archive Browser to open MOD/ERF/RIM/SAV files from the configured game install, with the file dialog rooted at `modules/`, `lips/`, `rims/`, or the install root — workspace parity with dock `_open_game_erf`.

## Problem Frame

Q140 completed single-member filesystem export. Modders opening archives from their KotOR install still use the generic **Open Archive...** picker; the dock provides a game-install-aware shortcut the workspace lacks.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `resolve_game_archive_dialog_dir()` prefers modules/lips/rims under valid game path | `test_erf_workspace_editor.gd` |
| R2 | Missing/invalid game path blocks dialog with status message | Workspace editor test |
| R3 | Toolbar **Open Game Archive...** loads selected file via `open_archive_file` | Manual; dir resolution tested |
| R4 | Q140 export behavior unchanged | Existing tests still pass |
| R5 | Queue marks Q141 shipped | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Start dir | `KotorEditorState.find_first_existing_dir` candidate list | Matches dock `_open_game_erf` |
| Load path | Reuse `open_archive_file` | No duplicate parse/load logic |

## Implementation Units

### U1. Game archive dialog API + toolbar

- `ui/workspace/editors/erf_workspace_editor.gd`

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
