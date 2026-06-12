---
title: "feat: Q134 ERF member add foundations"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q134
track: OpenKotOR Parity
parent: docs/plans/2026-06-10-057-feat-q127-erf-workspace-ux-plan.md
related:
  - docs/50-execution/godot-capability-execution-queue.md
---

# Q134: ERF Member Add Foundations

## Summary

Enable Archive Browser to add new member files into an open ERF/RIM/MOD/SAV archive, repack via `ERFWriter`, mark the document dirty, and export the updated archive — foundations for Holocron `erf.py` member authoring.

## Problem Frame

Q127 shipped read-only archive browsing and extract-to-override. Modders cannot add missing resources into a `.mod` without external tools. There is no mutable member list on `KotorErfDocument` and no add-member UI in the workspace editor.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorErfDocument.add_member` validates resref/extension, rejects duplicates, repacks archive | `test_erf_document_add_member.gd` |
| R2 | `KotorErfDocument.serialize_for_pipeline` returns `{file_type, entries}` for `ERFWriter.repack` | Document test |
| R3 | Archive Browser **Add Member...** imports a file and refreshes member tree | `test_erf_workspace_editor.gd` |
| R4 | **Save Archive...** exports repacked bytes; dirty flag clears on successful save | Workspace editor test |
| R5 | Execution queue marks Q134 shipped; active slice → Q135 | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Mutation model | In-memory member dict list + `ERFWriter.repack` | Matches existing pipeline serialize arm |
| ResRef source | File basename (≤16 chars), extension from file | Minimal dialog-free foundations slice |
| Scope | Add + save only | Remove/replace members deferred |

## Implementation Units

### U1. Document mutations

- `resources/documents/kotor_erf_document.gd`

### U2. Workspace editor UX

- `ui/workspace/editors/erf_workspace_editor.gd`

### U3. Tests + docs

- `tests/editor/test_erf_document_add_member.gd`
- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_document_add_member.gd
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```

## Out of Scope (Q135+)

- Remove/replace archive members
- Nested archive editing inside running game without export
- SAV-specific save mutation
