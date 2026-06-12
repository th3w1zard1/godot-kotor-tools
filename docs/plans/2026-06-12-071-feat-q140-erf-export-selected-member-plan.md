---
title: "feat: Q140 ERF export selected member to file"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q140
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-070-feat-q139-erf-extract-all-folder-plan.md
related:
  - ui/kotor_dock.gd
---

# Q140: Export Selected Member to File

## Summary

Add **Export Selected...** in Archive Browser to save the selected archive member to a user-chosen file path — workspace parity with the legacy dock `_export_selected_erf_entry` mutation export path.

## Problem Frame

Q139 shipped batch folder extract with fixed `{resref}.{ext}` names. Modders still need single-member export with a custom destination path and preflight — the dock already supports this; the workspace editor does not.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `export_member_to_path(index, path)` writes member bytes via mutation export | `test_erf_workspace_editor.gd` |
| R2 | `export_selected_member_to_path(path)` requires selection | Workspace editor test |
| R3 | Toolbar **Export Selected...** opens save dialog with default `{resref}.{ext}` | Manual; API covered by test |
| R4 | Q139 batch folder extract unchanged | Existing tests still pass |
| R5 | Queue marks Q140 shipped | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Export path | `preview_export_to_path` / `apply_export_to_path` on member bytes | Matches dock single-entry export |
| Preflight | Reuse existing preflight dialog with `export_member` kind | Consistent with save/install flows |
| Invalid member | Reject empty resref before dialog apply | Matches override install guard |

## Implementation Units

### U1. Export API + toolbar + preflight

- `ui/workspace/editors/erf_workspace_editor.gd`

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
