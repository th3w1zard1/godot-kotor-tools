---
title: "feat: Q142 ERF compare all members with override"
type: feat
status: active
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q142
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-072-feat-q141-erf-open-game-archive-plan.md
related:
  - editor/modding/kotor_modding_pipeline.gd
---

# Q142: Compare All Members with Override

## Summary

Add **Compare All Members with Override** in Archive Browser to scan every archive member against the configured install override/core index and produce a batch summary report exportable via **Export Compare Report...**.

## Problem Frame

Q136 shipped single-member compare. Modders auditing whole `.mod` archives still repeat per-row compare for each member.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `compare_all_members_with_override` scans all valid members | `test_erf_workspace_editor.gd` |
| R2 | Invalid/empty resref members skipped with summary counts | Workspace editor test |
| R3 | Batch result stored for `export_compare_report_to_path` | Workspace editor test |
| R4 | Toolbar button wired | Toolbar button assertion |
| R5 | Q141 open behavior unchanged | Existing tests still pass |
| R6 | Queue marks Q142 shipped | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Compare engine | `KotorModdingPipeline.compare_member_batch_with_override` | Reuses `compare_gamefs_resource`; mirrors `compare_all_overrides` |
| Report export | Reuse `_last_compare_result.details` via existing export path | No duplicate export UI |

## Implementation Units

### U1. Pipeline batch compare helper

- `editor/modding/kotor_modding_pipeline.gd`

### U2. Workspace API + toolbar

- `ui/workspace/editors/erf_workspace_editor.gd`

### U3. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
