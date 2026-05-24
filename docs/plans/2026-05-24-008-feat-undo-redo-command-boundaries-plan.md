---
title: "feat: Add undo/redo command boundaries for document mutations"
status: "active"
created: "2026-05-24"
owner: "copilot"
queue: "Q1"
---

# feat: Add undo/redo command boundaries for document mutations

## Summary

Wire Godot's `EditorUndoRedoManager` into the GFF, 2DA, and TLK workspace editors so all in-editor mutations are undoable and redoable via Ctrl+Z / Ctrl+Shift+Z without losing dirty/validation state.

---

## Problem Frame

Every field edit, cell change, and string update in the workspace editors currently mutates the document and emits `changed`, but nothing records these changes in Godot's undo stack. Users who accidentally overwrite a value have no recovery path short of closing without saving and reopening the file.

---

## Scope Boundaries

### In scope

- GFF editor: `_apply_tag_edit`, `_apply_display_name_edit`, `_apply_tree_field_edit`
- 2DA editor: `_on_tree_item_edited`
- TLK editor: `_apply_text`
- Helper `_get_undo_redo() -> EditorUndoRedoManager` added to each editor

### Deferred for later

- DLG editor struct field mutations (require lambda refactor to named methods)
- Undo clearing dirty state when all edits are undone (complex dirty tracking)

### Out of scope

- New format support or storage format changes

---

## Requirements

- **R1:** GFF tag, display name, and scalar field edits are reversible with Ctrl+Z.
- **R2:** 2DA cell edits are reversible with Ctrl+Z.
- **R3:** TLK string text edits are reversible with Ctrl+Z.
- **R4:** Undo/redo operations refresh the editor UI to reflect the restored value.
- **R5:** Undo/redo integration is guarded with `Engine.is_editor_hint()` so validation runs remain safe.

---

## Key Technical Decisions

- Use `EditorInterface.get_editor_undo_redo()` (available in Godot 4.3+) rather than threading the plugin's undo/redo manager through the controller hierarchy.
- Use `commit_action()` (execute=true) with dedicated `_exec_*` methods so the undo/redo stack records and immediately executes mutations uniformly for do and undo.
- The `_exec_*` methods do NOT call `create_action` themselves, preventing undo recording during undo replay.
- For 2DA, call `_refresh_tree()` on exec to ensure the tree reflects the correct value (full rebuild is acceptable for typical 2DA sizes).

---

## Implementation Units

### U1. GFF editor undo/redo wiring

**Files:** `ui/workspace/editors/gff_workspace_editor.gd`

**Mutations covered:**
- `_apply_tag_edit` → `_exec_tag_edit(value: String)`
- `_apply_display_name_edit` → `_exec_display_name_edit(field: String, value: String)`
- `_apply_tree_field_edit` → `_exec_tree_field_edit(path: Array, value: Variant)`

### U2. 2DA editor undo/redo wiring

**Files:** `ui/workspace/editors/twoda_workspace_editor.gd`

**Mutations covered:**
- `_on_tree_item_edited` → `_exec_cell_edit(row: int, col: String, value: Variant)`

### U3. TLK editor undo/redo wiring

**Files:** `ui/workspace/editors/tlk_workspace_editor.gd`

**Mutations covered:**
- `_apply_text` → `_exec_entry_text_edit(strref: int, value: String)`

---

## Deferred Implementation Notes

- DLG editor uses lambda closures for field mutations; needs a refactor to named methods before undo/redo can be wired cleanly.
- Dirty-state collapse on full undo (marking document clean after undoing all edits) is intentionally deferred.
