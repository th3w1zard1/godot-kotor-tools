---
title: "feat: Q149 savegame extract all members to override"
type: feat
status: completed
date: 2026-06-13
origin: lfg-next-after-q148-auto-selected
phase: Q149
track: OpenKotOR Parity
parent: docs/plans/2026-06-13-083-feat-q147-savegame-member-extract-plan.md
related:
  - docs/plans/2026-06-12-069-feat-q138-erf-extract-all-override-plan.md
  - ui/workspace/editors/savegame_workspace_editor.gd
  - tests/editor/test_savegame_workspace_editor.gd
---

# Q149: Savegame Extract All Members to Override

## Summary

Add **Extract All to Override** on the Savegame Inspector, mirroring ERF Archive Browser Q138 batch install. Second bounded savegame write-back slice after Q147 single-member extract.

## Problem Frame

Q147 shipped per-member extract with preflight. Modders unpacking save embedded resources still repeat row-by-row extract for each SAV member.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | `extract_all_members_to_override()` installs all valid members via mutation apply | U1 |
| R2 | Toolbar **Extract All to Override** wired to batch path | U1 |
| R3 | Invalid/empty resref members skipped with applied/unchanged/skipped/failed summary | U1, U2 |
| R4 | GameFS refresh once when any member applied | U1 |
| R5 | Headless tests for batch extract + skip invalid | U2 |
| R6 | Execution queue + gap audit update | U3 |

## Implementation Units

### U1. Batch extract API + toolbar

**Files:** `ui/workspace/editors/savegame_workspace_editor.gd`

Mirror `erf_workspace_editor.gd` `extract_all_members_to_override` using `_apply_member_install_to_override(index, true)` loop.

### U2. Tests

**Files:** `tests/editor/test_savegame_workspace_editor.gd`

Add `_test_extract_all_members_to_override` and `_test_extract_all_skips_invalid_members`.

### U3. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_savegame_workspace_editor.gd
```

## Out of Scope

- Extract all to folder
- Full `.sav` write-back / repack
- Per-member preflight dialogs in batch path
