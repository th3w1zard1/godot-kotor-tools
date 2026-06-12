---
title: "feat: Q136 ERF member compare with override"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q136
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-066-feat-q135-erf-member-remove-replace-plan.md
related:
  - docs/plans/2026-06-10-054-feat-q122-module-mdl-compare-override-toolbar-plan.md
---

# Q136: ERF Member Compare With Override

## Summary

Add Archive Browser toolbar parity for install-aware compare: selected member vs GameFS override/core, plus compare report export — matching Q122/Q123 MDL and walkmesh patterns.

## Problem Frame

Q127–Q135 shipped archive browse/mutate/save, but modders cannot diff an archive member against their live override copy without leaving the workspace.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | **Compare Member with Override...** uses `compare_gamefs_resource` for selected resref+extension | `test_erf_workspace_editor.gd` |
| R2 | **Export Compare Report...** writes last compare via `export_compare_result_to_path` | Workspace editor test |
| R3 | Status panel shows `format_compare_result_text` output | Workspace editor test |
| R4 | Queue marks Q136 shipped; active slice advances | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Compare target | GameFS override vs core for member resref | Matches MDL/WOK Q122 semantics |
| Scope | Selected member only | Bounded slice; batch archive compare deferred |

## Implementation Units

### U1. Workspace editor compare UX

- `ui/workspace/editors/erf_workspace_editor.gd`

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
