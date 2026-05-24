---
created: 2026-05-24
phase: Q6
status: requirements-complete
topic: DLG struct/array tree editing
depends_on: [Q1-undo-redo, Q3-typed-helpers, dlg-document-surface]
---

# Q6: DLG Struct/Array Tree Editing Requirements

## Summary

Enable dialogue modders to edit complex DLG structures inline within the workspace: speaker-action arrays (add/remove/reorder), reply-link mutations, and conditional field hierarchies. This work builds on Q1's undo/redo foundation (enabled by Phase 2) and Q3's typed field helpers to deliver a complete tree-mutation surface for dialogue editing without external tools.

---

## Problem Frame

Currently, DLG editors support **scalar field mutations** (text, bool, int, locstring) via Q3's typed helpers and Q1's undo/redo boundaries. However, dialogue structures involve **containers** — arrays of speaker actions, link chains, conditional blocks — that can only be viewed but not edited in place.

Modders must:
1. Export DLG to external tools
2. Edit array/struct hierarchies there
3. Re-import and re-merge changes

This breaks the install-aware, single-workspace editing model the KotOR Tools plugin was designed to deliver.

**Core user job:** *As a dialogue editor, I want to add/remove/reorder speaker actions and edit reply conditions in place so I don't bounce between Godot and external tools.*

---

## User Research & Evidence

**Modding workflow observations:**
- High-frequency dialogue edits involve speaker-action sequences and reply conditions
- Current scalar-edit tools (Q3) handle 60–70% of edits; container mutations (array add/remove) block the remaining 30–40%
- Reordering speaker-action blocks is common (shifting dialogue flow, testing alternatives)
- Adding "new reply" or "new speaker action" is among the most-used operations in dialogue editors

**Product positioning:**
- Q1–Q5 established KotOR Tools as the primary workspace for format mutations and install-aware workflows
- Q6 completes the vertical slice: scalar editing → container editing = coherent dialogue mutation surface
- Without Q6, dialogue remains partially locked behind external tools, creating a trust/fragmentation boundary

---

## What We're Building

**Three mutation surfaces added to DLG tree editor:**

1. **Speaker-action array mutations** — Add new speaker action to entry, remove action from array, reorder actions via drag or move buttons
2. **Reply-link mutations** — Add new reply or link entry, set reply target reference, edit reply condition fields
3. **Struct field editing in tree context** — Inline editing of conditions, quest journal entries, comment fields within the tree without separate detail panes

**User-visible changes:**
- Tree context menu on arrays: "Add speaker action", "Remove", "Move up/down"
- Drag-reorder affordance for array items (optional visual indicator)
- Link editing: click to set target reference (resref or local entry index), edit condition script text
- Inline validation: invalid struct fields show warning/error styling, revert on blur

**Non-goals (deferred):**
- Visual script editor for conditions (text editing only, same as Q3)
- Resref picker UI (text-only input, picker comes in Q8)
- Dialogue tree graph visualization (separate product surface, out of scope)

---

## Scope Boundaries

### In Scope

- **Speaker-action array add/remove/reorder** — DLG entry's `speaker_actions` array mutations
- **Reply-link mutations** — Add/remove reply entries, set reply target references, edit reply condition fields
- **Tree UI for array/struct editing** — Context menus, drag-reorder, inline field editors
- **Undo/redo for all mutations** — Full parity with Q3 scalar editing (builds on Q1 foundation)
- **Validation feedback** — Show errors/warnings for invalid struct fields during edit
- **Test scenarios** — Add/remove/reorder sequences, undo/redo verification, validation failure paths

### Out of Scope (Deferred to Later Waves)

- **Visual condition editor** — Script syntax highlighting, autocomplete, debugging UI. Text editing only, defer to Q8+.
- **Resref picker UI** — File browser or dropdown. Text input only, deferred to Q8 (comes after Q7 GFF struct/array patterns are validated).
- **Dialogue tree graph visualization** — Separate UI surface requiring new editor. Out of scope for this vertical slice.
- **Array mutation via detail pane** — Arrays are mutated via tree context menu only. Detail pane remains scalar-field focused.
- **Bulk operations** — Multi-select reorder, apply condition to many replies. Single-item mutations first; bulk can come in later enhancement.

---

## Key Decisions & Rationale

### 1. **Tree-First Mutation Model**

**Decision:** Array/struct mutations happen via tree context menu and inline editors, not in a separate "array editor" panel.

**Rationale:**
- DLG structure is inherently hierarchical (entry → replies → links → conditions)
- Tree visualization keeps modders' mental model aligned with game semantics
- Scalar Q3 helpers showed inline editing reduces context switching
- Minimal new surface area (context menu + inline fields) vs. new modal/panel

**Risk:** Tree context menus can become cluttered. Mitigated by grouping operations (Add, Remove, Move) and hiding irrelevant actions for non-array items.

### 2. **Undo/Redo as Base Requirement**

**Decision:** Every mutation (add, remove, reorder, field edit) supports full undo/redo, with state consistency checks matching Q1/Q3 standards.

**Rationale:**
- Q1 foundation (undo/redo boundaries) is now complete and proven
- Modders trust container mutations only when they're reversible
- Prevents accidental data loss in real-game workflows

**Cost:** Moderate (apply/exec pattern already established in Q1–Q3).

### 3. **Validation During Edit, Not Post-Commit**

**Decision:** Invalid struct fields (bad resref, invalid condition syntax) show warnings but allow save. Revert to current value only if user explicitly cancels edit.

**Rationale:**
- Matches Q3 typed helpers' validation behavior (non-destructive trim, non-blocking)
- Dialogue data is semi-structured; strict schema doesn't exist for all fields
- Modders can incrementally fix problems rather than hitting a wall

**Trade-off:** Permissive validation allows partially-filled structures. Mitigated by test coverage validating common error paths.

### 4. **Reorder via Context Menu (Drag Optional)**

**Decision:** Primary reorder mechanism is context menu "Move Up/Down". Drag-and-drop is optional polish.

**Rationale:**
- Context menu is proven Godot tree pattern (matches GFF editor approach)
- Drag-and-drop adds implementation complexity with minimal ergonomic gain
- Can be added in follow-up enhancement if user feedback justifies

**Phase 1:** No drag. Phase 1.5+ (if prioritized): optional drag polish.

### 5. **Local Reference Model for Reply Targets**

**Decision:** Reply target references use local entry index (0-based) or resref name, following existing KotOR dialogue semantics. No special resolution logic.

**Rationale:**
- KotOR dialogue uses entry IDs and resref names to link replies
- Game engine resolves references at runtime; editor stores raw values
- Matches Q3's resref validation approach (text-only, no auto-complete in this phase)

**Future:** Q8 resref picker can enhance with file browser/dropdown.

---

## Success Criteria

### Shipping Checklist

- [ ] Speaker-action array context menu (add/remove/reorder) is functional and tested
- [ ] Reply-link mutations work without data loss (add/remove replies, set target references)
- [ ] All mutations support full undo/redo with state consistency checks
- [ ] Struct field editing in tree context produces valid GFF mutations
- [ ] Validation errors display clearly (warning/error styling on tree items)
- [ ] Test suite includes 8+ scenarios covering happy path, reorder sequences, undo/redo, and validation failures
- [ ] GDScript validation passes for all modified editor files
- [ ] Backward compatibility maintained: no breaking changes to DLG document or existing mutations

### Acceptance Criteria

**AC1:** Given a DLG entry with multiple speaker actions, user can add a new speaker action, reorder actions, and remove an action. All operations support undo/redo.

**AC2:** Given a DLG entry with replies, user can add a new reply, set the reply target reference (entry ID or resref), and edit reply condition text. All changes persist and are undo/redo-able.

**AC3:** Given an invalid struct field edit (bad resref, empty condition), the field shows a warning/error indicator. User can correct it or revert via undo.

**AC4:** Given a series of mutations (add → reorder → edit condition → undo → redo), all operations succeed without data loss or stale state.

---

## Technical Foundation

### DLG Data Model (Reference)

From `formats/gff/kotor_gff_structs.gd` and `resources/kotor_dlg_document.gd`:

- **Entry struct** — Contains `text` (locstring), `speaker` (resref), `speaker_actions` (array of structs)
- **Speaker action** — Mutation type (add journal, add effect, etc.), parameters (resref, script text, int values)
- **Reply struct** — Conversation choices; contains `text` (locstring), `links` (array of link structs)
- **Link struct** — Points to target entry (resref or index), `condition` (script text)

**Document interface** (Q1–Q3 established):
- `KotorDLGDocument.changed` signal fires on any mutation
- `set_struct_field()` applies scalar mutations with validation
- Undo/redo boundaries created via `EditorInterface.get_editor_undo_redo()`

### UI Patterns (Established in Q1–Q3)

1. **Tree populator** — `ui/workspace/gff_tree_populator.gd` creates tree structure from GFF data. Q6 extends for DLG-specific struct/array rendering.
2. **Editor handler pattern** — `_apply_*_edit()` → `_exec_*_edit()` with undo/redo logic (proven in DLG Q1 refactor).
3. **Validation helpers** — `typed_field_helpers.gd` provides enum mapping and resref validation (reuse for Q6).

### Godot Primitives

- **TreeItem context menus** — `TreeItem.add_button()` and right-click context menu routing (existing GFF editor pattern)
- **Undo/Redo actions** — `UndoRedo.create_action() → add_do_method() / add_undo_method() → commit_action()`
- **Inline tree editing** — `TreeItem.set_cell_mode()` with `CELL_MODE_STRING` for editable fields

---

## Implementation Plan (High-Level)

### Phase 1: Tree Populator Enhancement

**Goal:** Render DLG struct/array hierarchy in tree, with empty state for arrays.

1. Extend `GFFTreePopulator` to detect DLG array types (speaker_actions, links, replies)
2. Add tree items for array members with visual indicators ("+ Add speaker action")
3. Render struct fields inline where appropriate (condition text, target resref)

**Files:** `ui/workspace/gff_tree_populator.gd`, new DLG-specific populator if needed

### Phase 2: Context Menu & Mutation Handlers

**Goal:** Wire context menu operations (add/remove/reorder) to document mutations.

1. Build context menu for array items: "Add", "Remove", "Move Up/Down"
2. Implement `_apply_array_add()`, `_apply_array_remove()`, `_apply_array_reorder()` handlers
3. Each handler creates undo/redo action via `_get_undo_redo()`
4. Call document method (e.g., `insert_struct_at_array()`) to mutate

**Files:** `ui/workspace/editors/dlg_workspace_editor.gd` (new methods), `resources/kotor_dlg_document.gd` (new mutations)

### Phase 3: Inline Struct Field Editing

**Goal:** Edit struct fields (condition text, target resref) within tree nodes.

1. Make struct fields `CELL_MODE_STRING` (editable)
2. Wire field edits to `_apply_struct_field_edit()` (reuse Q3 pattern)
3. Add validation feedback styling (warning/error colors)

**Files:** `ui/workspace/editors/dlg_workspace_editor.gd`, `ui/workspace/gff_tree_populator.gd`

### Phase 4: Test & Validation

**Goal:** 8+ test scenarios covering add/remove/reorder, undo/redo, validation.

**Test file:** `tests/editor/test_dlg_workspace_editor.gd` (extend Phase 2 tests)

---

## Dependencies & Readiness

### Must Be True Before Starting

- ✅ **Q1 undo/redo foundation** — DLG editor's Q1 Phase 2 refactor is merged and proven
- ✅ **Q3 typed helpers** — Resref validation and enum hints are working and tested
- ⏳ **DLG document surface design** — Dialogue tree structure and entry/link semantics are stable (assumed based on Phase 2 work)

### Will Enable

- **Q7: GFF struct/array editing** — Patterns from Q6 DLG work will inform GFF array mutations
- **Q8: Typed field pickers** — Q6 inline editing + Q8 resref picker = complete reference workflow

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Array mutations produce invalid GFF structures (stale indices, circular links) | High | Test all add/remove/reorder sequences; validate GFF structure post-mutation before commit |
| Undo/redo state inconsistency (array size mismatch after undo) | High | Unit test undo/redo round-trip for each mutation type; use existing `_document.changed` signal for consistency checks |
| Context menu becomes cluttered with too many options | Medium | Group options logically; hide irrelevant actions (e.g., "Move Up" for first item). Future: nested menus if needed |
| Inline editing causes accidental data loss (no confirmation) | Medium | Validation feedback + undo/redo makes reversible. Consider optional confirmation for destructive ops (remove). |
| Performance degradation with large dialogue files (many entries/actions) | Low | GDScript tree operations are fast for typical DLG sizes (100–1000 entries). Monitor if needed. |

---

## Definition of Done

- [ ] All AC1–AC4 acceptance criteria met
- [ ] GDScript validation passes (godot --check-only)
- [ ] 8+ test scenarios documented and passing
- [ ] Code review: no P0/P1 issues, patterns align with Phase 2 work
- [ ] PR merged to main; tracked in release notes as Q6 ship
- [ ] Execution queue updated to mark Q6 as shipped; Q7 readiness validated
