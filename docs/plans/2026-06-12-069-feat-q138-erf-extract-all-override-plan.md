---
title: "feat: Q138 ERF extract all members to override"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q138
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-068-feat-q137-erf-install-archive-to-modules-plan.md
related:
  - ui/kotor_dock.gd
---

# Q138: Extract All Members to Override

## Summary

Add **Extract All to Override** in Archive Browser to install every archive member into the game Override in one action — workspace parity with the legacy dock batch extract/install path.

## Problem Frame

Q127 shipped single-member extract with preflight. Modders unpacking whole `.mod` archives still repeat per-row extract for each member.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `extract_all_members_to_override` installs all valid members | `test_erf_workspace_editor.gd` |
| R2 | Invalid/empty resref members skipped with summary | Workspace editor test |
| R3 | Single-member **Extract to Override** behavior unchanged | Existing tests still pass |
| R4 | Queue marks Q138 shipped | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Preflight | Apply each member with mutation apply (no per-row dialog) | Explicit batch action; mirrors dock install-all intent |
| Invalid members | Skip and report count | Non-destructive partial success |

## Implementation Units

### U1. Batch extract API + toolbar

- `ui/workspace/editors/erf_workspace_editor.gd`

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
