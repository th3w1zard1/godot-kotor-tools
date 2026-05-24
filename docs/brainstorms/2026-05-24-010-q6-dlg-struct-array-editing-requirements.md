---
created: 2026-05-24
updated: 2026-05-24
phase: Q6
status: requirements-complete
topic: DLG struct/array tree editing
depends_on: [Q1-undo-redo, Q3-typed-helpers, Q7-gff-array-patterns, dlg-document-surface]
---

# Q6: DLG Struct/Array Tree Editing Requirements

## Summary

Enable dialogue modders to edit complex DLG structures inline within the workspace: reply arrays to entries (add/remove/reorder RepliesList), entry-link mutations within replies (EntriesList), and conditional field hierarchies. This work builds on Q1's undo/redo foundation (enabled by Phase 2) and Q3's typed field helpers, and follows the struct/array mutation patterns established in Q7 (GFF struct/array editing).

---

## Problem Frame

Currently, DLG editors support **scalar field mutations** (text, bool, int, locstring) via Q3's typed helpers and Q1's undo/redo boundaries. However, dialogue structures involve **containers** — arrays of replies to entries (RepliesList), entry-link chains within replies (EntriesList), and conditional blocks — that can only be viewed but not edited in place.

Modders must:
1. Export DLG to external tools
2. Edit array/struct hierarchies there
3. Re-import and re-merge changes

This breaks the install-aware, single-workspace editing model the KotOR Tools plugin was designed to deliver.

**Core user job:** *As a dialogue editor, I want to add/remove/reorder replies to entries and edit reply conditions in place so I don't bounce between Godot and external tools.*

---

## User Research & Evidence

**Modding workflow observations:**
- High-frequency dialogue edits involve reply sequences (RepliesList within entries) and entry-link conditions
- Current scalar-edit tools (Q3) handle approximately 60–70% of common edits; container mutations (array add/remove/reorder) block the remaining 30–40% of typical workflows
- Reordering replies to an entry is common (shifting dialogue branches, testing alternatives)
- Adding "new reply" is among the most-used operations in dialogue editors

**Product positioning:**
- Q1–Q5 established KotOR Tools as the primary workspace for format mutations and install-aware workflows
- Q6 completes the vertical slice: scalar editing → container editing = coherent dialogue mutation surface
- Without Q6, dialogue remains partially locked behind external tools, creating a trust/fragmentation boundary

---

## What We're Building

**Three mutation surfaces added to DLG tree editor:**

1. **Reply array mutations (RepliesList)** — Add new reply to entry, remove reply from array, reorder replies via context menu Move Up/Down
2. **Entry-link mutations (EntriesList)** — Add new entry link within a reply, set link target reference (entry index or resref), edit link condition fields
3. **Struct field editing in tree context** — Inline editing of conditions, quest journal entries, comment fields within the tree without separate detail panes

**User-visible changes:**
- Tree context menu on reply arrays: "Add reply", "Remove", "Move up/down"
- Tree context menu on entry-link arrays: "Add entry link", "Remove", "Move up/down"
- Link editing: click to set target entry reference (entry index or resref), edit condition script text
- Inline validation: invalid struct fields show warning/error styling

**Non-goals (deferred):**
- Visual script editor for conditions (text editing only, same as Q3)
- Resref picker UI (text-only input, picker comes in Q8 as enhancement)
- Dialogue tree graph visualization (separate product surface, out of scope)

---

## Scope Boundaries

### In Scope

- **Reply array add/remove/reorder (RepliesList)** — DLG entry's RepliesList array mutations
- **Entry-link array add/remove/reorder (EntriesList)** — DLG reply's EntriesList array mutations  
- **Tree UI for array/struct editing** — Context menus for array operations, inline field editors
- **Undo/redo for all mutations** — Full parity with Q3 scalar editing (builds on Q1 foundation)
- **Validation feedback** — Show errors/warnings for invalid struct fields during edit
- **Hybrid validation model** — Required fields (e.g., entry link Index) block save; optional fields (comments) warn only
- **Test scenarios** — Add/remove/reorder sequences, undo/redo verification, validation failure paths (8+ scenarios enumerated)

### Out of Scope (Deferred to Later Waves)

- **Drag-reorder affordance** — Phase 1 uses context menu Move Up/Down only. Drag is Phase 1.5+ enhancement.
- **Visual condition editor** — Script syntax highlighting, autocomplete, debugging UI. Text editing only, defer to Q8+.
- **Resref picker UI** — File browser or dropdown. Text input only, deferred to Q8 as enhancement.
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

### 3. **Hybrid Validation: Required Fields Block, Optional Warn**

**Decision:** Invalid struct fields use a two-tier validation:
- **Required fields** (e.g., reply Index pointing to entry) block save with error styling
- **Optional fields** (e.g., comments, journal entries) show warnings but allow save

**Rationale:**
- Prevents modders from accidentally exporting broken dialogues with dangling references
- Allows incremental fixing of optional metadata without workflow friction
- Establishes clear field-level schema (Q6 planning phase responsibility)

**Field Classification Example:**
- REQUIRED: Reply.Index (must point to valid entry), Condition script (must parse if non-empty)
- OPTIONAL: Comments, speaker resonance override, quest journal entry text (can be fixed later)

### 4. **Reorder via Context Menu (Drag Deferred to Phase 1.5+)**

**Decision:** Primary reorder mechanism is context menu "Move Up/Down". Drag-and-drop is explicitly deferred to Phase 1.5+ enhancement.

**Rationale:**
- Context menu is proven Godot tree pattern (matches GFF editor approach)
- Drag-and-drop adds implementation complexity with minimal ergonomic gain for typical dialogue workflows (few modders edit >10 replies in sequence)
- Can be added in follow-up enhancement if user feedback justifies the cost

**Phase 1 (MVP):** Context menu Move Up/Down. **Phase 1.5+ (if prioritized):** Optional drag affordance.

### 5. **Entry References Use Local Index and Resref (No Auto-Complete in Phase 1)**

**Decision:** Reply entry-link target references (EntriesList) use local entry index (0-based) or resref name. No autocomplete or picker in Phase 1.

**Rationale:**
- KotOR dialogue uses entry indices and resref names to link replies to entries
- Game engine resolves references at runtime; editor stores raw values
- Matches Q3's resref validation approach (text-only input)
- Phase 1.5+ enhancement: tooltip showing entry list as modders type

**Future:** Q8 resref picker can enhance with file browser/dropdown for cross-file references.

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

**AC1:** Given a DLG entry with multiple replies (RepliesList), user can add a new reply, reorder replies, and remove a reply. All operations support undo/redo and produce valid GFF data.

**AC2:** Given a DLG reply with entry links (EntriesList), user can add a new entry link, set the link target reference (entry index or resref), and edit link condition text. All changes persist and are undo/redo-able.

**AC3:** Given an invalid struct field edit (bad entry link Index, empty required condition), the field shows a blocking error indicator for required fields or warning for optional fields. User can correct it or revert via undo.

**AC4:** Given a series of mutations (add → reorder → edit condition → undo → redo), all operations succeed without data loss, stale references, or state inconsistency.

---

## Technical Foundation

### DLG Data Model (Reference)

From `formats/dlg/kotor_dlg.gd` and `resources/documents/kotor_dlg_document.gd`:

- **DLG file** — Contains EntryList (array of entries), ReplyList (array of replies), StartingList (conversation starts)
- **Entry struct** — Contains Text (locstring), Speaker (resref), RepliesList (array of replies to this entry)
- **Reply struct** — Contains Text (locstring), EntriesList (array of entry-link targets)
- **Entry link struct** — Points to target entry (Index as entry array index or resref name), Condition (script text to gate the response)

**Document interface (Q1–Q3 established):**
- `KotorDLGDocument.changed` signal fires on any mutation
- `set_struct_field()` applies scalar mutations with validation
- Undo/redo boundaries created via `EditorInterface.get_editor_undo_redo()`

**Missing infrastructure (Q6 planning phase responsibility):**
- `KotorGFFDocument.insert_struct_at_array(field_name: String, struct_prototype: Dictionary, index: int)` — Insert struct into array at position
- `KotorGFFDocument.remove_struct_from_array(field_name: String, index: int)` — Remove struct from array at position
- `KotorGFFDocument.reorder_array_item(field_name: String, from_index: int, to_index: int)` — Reorder array item to new position

### UI Patterns (Established in Q1–Q3)

1. **Tree populator** — `ui/workspace/gff_tree_populator.gd` creates tree structure from GFF data. Q6 extends for DLG-specific array rendering (RepliesList, EntriesList).
2. **Editor handler pattern** — `_apply_*_edit()` → `_exec_*_edit()` with undo/redo logic (proven in DLG Q1 refactor and GFF editor Q5).
3. **Validation helpers** — `typed_field_helpers.gd` provides enum mapping and resref validation (reuse for Q6).
4. **Array context menu pattern** — Per-item context menus for array operations (new for Q6, follows GFF editor conventions).

### Godot Primitives

- **TreeItem context menus** — `TreeItem` right-click context menu routing (existing GFF editor pattern, proven)
- **Undo/Redo actions** — `UndoRedo.create_action() → add_do_method() / add_undo_method() → commit_action()`
- **Inline tree editing** — `TreeItem.set_cell_mode()` with text/enum editable modes (established Q3 pattern, CELL_MODE_STRING)

---

## Implementation Plan (High-Level)

### Phase 0 (Planning): Design Array Mutation Methods (PRE-REQUISITE)

**Goal:** Design the three missing array mutation methods before Phase 1 implementation.

**Design tasks** (ce-plan phase 1):
1. Specify `insert_struct_at_array(field_name, struct_prototype, index)` contract — struct initialization, GFF struct ID assignment, reference validation
2. Specify `remove_struct_from_array(field_name, index)` contract — dangling reference handling (e.g., reordering EntriesList invalidates Index fields), cascade validation
3. Specify `reorder_array_item(field_name, from_index, to_index)` contract — state consistency, reference update rules

**Acceptance:** Designs validated against Q7 GFF struct/array patterns; ready for implementation.

### Phase 1: Tree Populator Enhancement

**Goal:** Render DLG struct/array hierarchy in tree, with empty state for arrays.

1. Extend `GFFTreePopulator` to detect DLG array types (RepliesList within entries, EntriesList within replies)
2. Add tree items for array members with visual indicators ("+ Add reply", "+ Add entry link")
3. Render entry-link struct fields inline (Index, Condition text)

**Files:** `ui/workspace/gff_tree_populator.gd`, new DLG-specific section if needed

### Phase 2: Context Menu & Mutation Handlers

**Goal:** Wire context menu operations (add/remove/reorder) to document mutations using designed methods from Phase 0.

1. Build context menu for RepliesList/EntriesList items: "Add", "Remove", "Move Up/Down"
2. Implement `_apply_array_add()`, `_apply_array_remove()`, `_apply_array_reorder()` handlers
3. Each handler calls designed array mutation methods via undo/redo

**Files:** `ui/workspace/editors/dlg_workspace_editor.gd` (new methods), `resources/documents/kotor_dlg_document.gd` (new array mutations)

### Phase 3: Inline Struct Field Editing + Validation

**Goal:** Edit struct fields (condition text, entry link Index) within tree nodes with hybrid validation.

1. Make struct fields editable (TreeItem.set_cell_mode() with CELL_MODE_STRING)
2. Wire field edits to `_apply_struct_field_edit()` handler
3. Implement hybrid validation: required fields block save, optional fields warn

**Files:** `ui/workspace/editors/dlg_workspace_editor.gd`, `ui/workspace/gff_tree_populator.gd`, new validation schemas

### Phase 4: Test & Validation

**Goal:** 8+ enumerated test scenarios covering add/remove/reorder, undo/redo, validation, and edge cases.

**Test file:** `tests/editor/test_dlg_workspace_editor.gd` (extend Phase 2 tests)

**Scenario enumeration (REQUIRED):**
- Add reply to entry with no replies
- Add reply to entry with existing replies (prepend, append, insert middle)
- Remove single reply (boundary)
- Remove middle reply from sequence
- Reorder replies up/down with undo/redo
- Add entry link to reply (set valid Index)
- Add entry link with invalid Index (validation failure)
- Edit condition text (optional field, should warn not block)
- Undo/redo consistency across all mutation types

---

## Dependencies & Readiness

### Must Be True Before Starting

- ✅ **Q1 undo/redo foundation** — DLG editor's Q1 Phase 2 refactor is merged and proven
- ✅ **Q3 typed helpers** — Resref validation and enum hints are working and tested
- ✅ **DLG document surface** — Dialogue tree structure, EntryList, ReplyList, RepliesList, EntriesList semantics are stable (completed in Phase 2)
- ⏳ **Q7 GFF struct/array patterns** — Design array mutation methods (`insert_struct_at_array`, `remove_struct_from_array`, `reorder_array_item`) that Q6 will reuse. Q6 follows Q7's pattern approach rather than inventing own mutation style. Q6 Phase 0 depends on Q7 planning.

### Will Enable

- **Q8: Typed field pickers** — Q6 inline editing + Q8 resref picker = complete reference workflow (enhancement, not blocker)
- **Later: GFF editing** — Patterns established in Q6 DLG work will inform generalized GFF array mutations

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Reordering EntriesList invalidates Index fields pointing to other entries (stale references) | High | Phase 0 design specifies reference update rules: reordering must increment/decrement Index fields in sibling/other links. Unit tests validate this behavior. |
| Array mutations produce invalid GFF structures (empty required fields, schema violations) | High | Define required vs. optional field schema in Phase 0. Hybrid validation blocks save on required fields, warns on optional. Test all add/remove/reorder sequences. |
| Undo/redo state inconsistency (array size mismatch after undo) | High | Unit test undo/redo round-trip for each mutation type; use existing `_document.changed` signal for consistency checks. Q1 pattern already proven. |
| Context menu becomes cluttered with too many options | Medium | Phase 1.5+ enhancement: group options logically or use nested menus if needed. Phase 1 MVP uses simple flat menu. |
| Modders save with warnings and export broken dialogues (bad entry links) | Medium | Hybrid validation: REQUIRED fields block save. Documentation clarifies field-level schema. Testing validates common error paths. |
| Inline editing causes accidental data loss | Low | Undo/redo makes reversible. Optional confirmation for destructive "Remove" ops (Phase 1.5+ polish). |
| Performance degradation with large dialogue files | Low | GDScript tree operations are fast for typical DLG sizes (100–1000 entries, 5–50 replies each). Monitor if needed. |

---

## Definition of Done

- [ ] **Phase 0 Design Complete:** Array mutation methods (`insert_struct_at_array`, `remove_struct_from_array`, `reorder_array_item`) designed with full specifications, reference update rules validated against Q7 patterns
- [ ] **All AC1–AC4 acceptance criteria met** with verified test cases
- [ ] **All 8+ enumerated test scenarios passing** (add/remove/reorder boundaries, undo/redo round-trips, validation blocking/warning behavior)
- [ ] **Hybrid validation implemented:** Required fields block save (with error styling), optional fields warn only
- [ ] **Context menu operations functional:** Add, Remove, Move Up/Down for RepliesList and EntriesList
- [ ] **GDScript validation passes** (`godot --check-only` on all modified editor files)
- [ ] **Backward compatibility maintained:** No breaking changes to DLG document structure, existing scalar mutations still work
- [ ] **Code review:** No P0/P1 issues, patterns align with Q1 undo/redo and Q3 typed helpers
- [ ] **PR merged to main;** tracked in release notes as Q6 ship
- [ ] **Execution queue updated** to mark Q6 as shipped; document note that Q6 follows Q7 pattern design
