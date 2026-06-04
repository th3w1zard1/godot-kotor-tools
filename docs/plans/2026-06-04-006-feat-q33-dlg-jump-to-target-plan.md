---
title: "feat: Q33 DLG jump-to-target link navigation"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q32-next-parity-slice
phase: Q33
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-24-010-feat-q6-dlg-struct-array-editing-plan.md
---

# Q33: DLG Jump-to-Target Link Navigation

## Summary

Add dialogue link navigation so modders can jump from a link to its target entry/reply node in the DLG tree — outgoing link summaries, link detail panel, and tree activation on link items.

---

## Problem Frame

Q6 shipped DLG struct/array editing and link inspection, but navigating branched dialogue requires manually finding target nodes in a large tree. Holocron-style editors treat outgoing links as navigation affordances; our outgoing link buttons only re-select the link row.

---

## Scope Boundaries

### In scope

- `KotorDLGDocument.get_link_target_metadata()` resolver
- DLG editor: Jump to Target on link detail panel
- Outgoing link summary buttons jump to target node
- Tree item activated on link rows jumps to target
- Headless document resolver test

### Deferred

- Full graph view / minimap
- Back-navigation stack
- Broken-link auto-repair

### Out of scope

- New DLG mutation APIs
- Undo changes to navigation-only actions

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Document resolves valid link to `{kind, index}` target metadata | `test_dlg_workspace_editor.gd` |
| R2 | Invalid/out-of-range link returns empty metadata | Unit test |
| R3 | Link detail panel exposes Jump to Target | Editor wiring |
| R4 | Outgoing link summary buttons select target node | Manual / editor behavior |
| R5 | Docs note Q33 shipped in execution queue | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Navigation API | Document returns metadata; editor calls existing `_select_dlg_metadata` | Reuses tree selection infra |
| Outgoing links | Jump to target (not re-select link) | Matches modder expectation |
| Invalid targets | No-op with status message | Avoid selecting bogus indices |

---

## Implementation Units

### U1. Document resolver

**Files:** `resources/documents/kotor_dlg_document.gd`

### U2. Editor navigation

**Files:** `ui/workspace/editors/dlg_workspace_editor.gd`

### U3. Tests + docs

**Files:** `tests/editor/test_dlg_workspace_editor.gd`, execution queue

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_dlg_workspace_editor.gd
```
