---
title: feat: GFF workspace tree scalar editing
type: feat
status: complete
date: 2026-05-23
---

# feat: GFF workspace tree scalar editing

## Summary

Enable inline editing of scalar leaf fields in the GFF workspace field tree (strings, integers, floats, booleans, resrefs as strings). Paths are tracked on tree items so nested struct members can be edited without a full tree rebuild framework.

## Problem Frame

Plans 004–006 added GFF workspace routing, Tag, and display-name editing. The field tree remains read-only except for dedicated rows. Parity doc defers "nested field-tree inline editing" — this plan delivers a minimal v1 for scalar leaves only.

## Requirements

- R1. Scalar leaf values in the GFF tree column 1 are editable (not structs, arrays, or locstring blobs).
- R2. Edits update the active document and mark dirty; tree/summary refresh after edit.
- R3. `KotorGFFDocument` supports get/set by field path (array of keys, string or int segments).
- R4. Headless test: UTC `TemplateResRef` edited via editor helper, save, reload verifies value.
- R5. Update `docs/solutions/parity-foundation.md` — scalar tree edit on contract; complex types still deferred.

## Scope Boundaries

- In scope: path metadata in populator, document path helpers, tree `item_edited`, UTC test.
- Out of scope: array element edit, locstring inline edit, schema-aware type pickers, legacy dock.

## Implementation Units

### U1. Document path helpers

**Files:** `resources/kotor_gff_document.gd`

- `get_field_at_path(path: Array) -> Variant`
- `set_field_at_path(path: Array, value: Variant) -> bool`

### U2. Tree metadata and editing

**Files:** `ui/workspace/gff_tree_populator.gd`, `ui/workspace/editors/gff_workspace_editor.gd`

- Populator stores path metadata and marks scalar leaves editable in column 1.
- Editor handles `item_edited`; `apply_tree_field_edit(path, text)` for tests.

### U3. Tests and docs

**Files:** `tests/editor/test_gff_workspace_editor.gd`, `docs/solutions/parity-foundation.md`

## Success Metrics

- User can double-click a scalar tree cell and commit a new value.
- UTC headless test passes with TemplateResRef round-trip.
- All `tests/editor/test_*.gd` pass.
