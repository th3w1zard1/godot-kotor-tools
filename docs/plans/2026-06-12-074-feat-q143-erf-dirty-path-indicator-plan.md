---
title: "feat: Q143 ERF dirty path label indicator"
type: feat
status: active
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q143
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-073-feat-q142-erf-compare-all-members-plan.md
related:
  - ui/workspace/editors/module_designer_workspace_editor.gd
---

# Q143: ERF Dirty Path Label Indicator

## Summary

Show an unsaved `*` suffix on the Archive Browser path label when `KotorErfDocument` is dirty — matching Module Designer path label conventions.

## Problem Frame

Q134–Q142 shipped full archive authoring and compare flows. Dirty state already propagates via `is_document_dirty()` and controller updates, but the toolbar path label does not surface unsaved edits visually.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Path label appends ` *` when document is dirty | `test_erf_workspace_editor.gd` |
| R2 | Asterisk clears after successful save | Workspace editor test |
| R3 | Clean open archive shows no asterisk | Existing add/save test assertions |
| R4 | Queue marks Q143 shipped; ERF wave capped | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Indicator | Suffix ` *` on filename portion | Matches `module_designer_workspace_editor._refresh_path_label` |
| Placement | Before status suffix (`file * — status`) | Keeps status message readable |

## Implementation Units

### U1. Path label refresh

- `ui/workspace/editors/erf_workspace_editor.gd` — `_refresh_status`

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
