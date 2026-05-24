---
title: feat: GFF array scalar tree editing
type: feat
status: complete
date: 2026-05-23
---

# feat: GFF array scalar tree editing

## Summary

Plan 007 made scalar GFF tree leaves editable and stored field paths on tree items, including array elements. `set_field_at_path` only writes when the parent container is a struct dictionary, so edits to `[n]` array elements are silently ignored. This plan fixes path-based writes for array parents and adds a headless round-trip test.

## Problem Frame

Users can edit scalar struct fields and see dirty state, but scalar values inside lists (e.g. string list entries) do not persist because the document helper rejects non-dictionary parents.

## Requirements

- R1. `set_field_at_path` updates scalar values when the parent is an `Array` and the final segment is a valid index.
- R2. Existing dictionary-parent path writes behave unchanged.
- R3. GFF workspace tree edits on array scalar leaves mark the document dirty and refresh the view.
- R4. Headless test: edit `TestList[0]` via `apply_tree_field_edit`, save, reload verifies value.
- R5. Update `docs/solutions/parity-foundation.md` — array scalar tree edit on contract; struct/locstring tree editing still deferred.

## Scope Boundaries

- In scope: `set_field_at_path` array parent branch, one test, parity doc note.
- Out of scope: adding/removing array elements, editing struct array elements, locstring-in-tree, legacy dock routing.

## Implementation Units

### U1. Array-aware path writes

**Files:** `resources/kotor_gff_document.gd`

- When parent is `Array` and key is `int`, assign `list[index]` if in range.
- Preserve no-op detection and `_notify_changed()`.

### U2. Test and docs

**Files:** `tests/editor/test_gff_workspace_editor.gd`, `docs/solutions/parity-foundation.md`

- UTC fixture with `TestList: ["alpha", "beta"]`; edit index 0; save/reload assert.
- Validation copy may mention array scalars if needed.

## Success Metrics

- `apply_tree_field_edit(["TestList", 0], "gamma")` persists on document and after save/reload.
- All `tests/editor/test_*.gd` pass.
