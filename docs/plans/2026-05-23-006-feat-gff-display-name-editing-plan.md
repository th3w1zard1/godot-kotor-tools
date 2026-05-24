---
title: feat: GFF workspace display name editing
type: feat
status: complete
date: 2026-05-23
---

# feat: GFF workspace display name editing

## Summary

Add locstring display-name editing to the GFF workspace editor so module and entity blueprints (especially ARE with `Name`) can edit human-readable titles on the workspace contract, not only `Tag`.

## Problem Frame

Plan 004–005 routed entity and module GFF through `gff_workspace_editor.gd` with Tag editing and a read-only field tree. `KotorGFFDocument` already supports `set_locstring_text()`. ARE fixtures expose `Name` as a locstring; users still cannot edit display names in the workspace UI.

## Requirements

- R1. GFF workspace editor shows a **Display name** row when the document has `LocName` or `Name` (prefer `LocName` when both exist).
- R2. Editing the row calls `set_locstring_text` on the resolved field (language id 0) and marks the document dirty.
- R3. Summary and tree refresh after locstring edits (same as Tag).
- R4. Headless test: ARE open → set display name via editor helper → save → install → verify bytes contain edited string.
- R5. Update `docs/solutions/parity-foundation.md` to note display-name editing (field-tree still deferred).

## Scope Boundaries

- In scope: UI row, document wiring, ARE test, docs.
- Out of scope: nested tree inline edit, strref picker, multi-language locstring UI, legacy dock changes.

## Implementation Units

### U1. Display name row in GFF workspace editor

**Files:** `ui/workspace/editors/gff_workspace_editor.gd`

- `_display_name_field()` resolves `LocName` vs `Name`.
- LineEdit row with submit/focus-exit handlers mirroring Tag.
- `apply_display_name_edit(text)` for headless tests.

### U2. Tests

**Files:** `tests/editor/test_gff_workspace_editor.gd`

- Extend ARE round-trip to edit display name and assert saved file contains new text.

### U3. Documentation

**Files:** `docs/solutions/parity-foundation.md`

- Note display-name locstring editing on workspace GFF contract.

## Success Metrics

- ARE opened from workspace shows editable display name.
- Headless ARE test passes with display name + Tag edits.
- All `tests/editor/test_*.gd` pass.
