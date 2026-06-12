---
title: "feat: Q135 ERF member remove/replace"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q135
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-065-feat-q134-erf-member-add-plan.md
related:
  - docs/50-execution/godot-capability-execution-queue.md
---

# Q135: ERF Member Remove/Replace

## Summary

Extend Archive Browser mutations so modders can remove or replace selected archive members, with undo-safe editor integration and save/export parity on the Q134 repack path.

## Problem Frame

Q134 added member import and save, but archives cannot be edited in-place when a member is wrong or obsolete. Holocron archive authoring expects remove/replace workflows before full nested editing.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorErfDocument.remove_member_at` removes by index and repacks | `test_erf_document_remove_replace.gd` |
| R2 | `KotorErfDocument.replace_member_at` swaps payload bytes for existing resref+ext | Document test |
| R3 | `KotorErfDocument.restore_members` supports undo snapshots | Document test |
| R4 | Archive Browser **Remove Member** / **Replace Member...** with `EditorUndoRedoManager` undo | `test_erf_workspace_editor.gd` |
| R5 | Dirty tracking + existing **Save Archive...** still works after mutations | Workspace editor test |
| R6 | Queue marks Q135 shipped; active slice advances | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Remove model | Index-based removal on `_members` | Tree selection already index-keyed |
| Replace model | Keep resref/extension; replace `bytes` only | Matches Holocron replace-resource semantics |
| Undo | Member-array snapshot restore via `restore_members` | RefCounted document; matches indoor/GFF undo style |
| Scope | Remove + replace only | Rename/resref change deferred |

## Implementation Units

### U1. Document API

- `resources/documents/kotor_erf_document.gd`

### U2. Workspace editor UX + undo

- `ui/workspace/editors/erf_workspace_editor.gd`

### U3. Tests + docs

- `tests/editor/test_erf_document_remove_replace.gd`
- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_document_remove_replace.gd
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```

## Out of Scope

- ResRef rename / extension change
- Multi-select bulk remove
- In-archive nested editor write-back
