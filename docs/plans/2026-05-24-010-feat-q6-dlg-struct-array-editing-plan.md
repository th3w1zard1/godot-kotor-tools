---
created: 2026-05-24
updated: 2026-05-24
type: feat
status: active
origin: docs/brainstorms/2026-05-24-010-q6-dlg-struct-array-editing-requirements.md
phase: Q6
track: DLG editing & dialogue authoring
---

# Q6: DLG Struct/Array Tree Editing

**Goal:** Enable dialogue modders to edit complex DLG structures (reply arrays, entry links) inline within the workspace, completing the vertical slice from scalar editing → container editing without external tools.

## Problem Frame

DLG editors currently support scalar mutations (text, bool, int) via Q3 helpers + Q1 undo/redo. However, dialogue structures involve containers — reply arrays (RepliesList) and entry-link chains (EntriesList) — that can only be viewed, not edited in place. Modders must export to external tools, breaking the install-aware workspace model.

**Core user job:** Add/remove/reorder replies and entry links in place, maintaining single-workspace editing.

## Summary & Scope

This plan delivers array add/remove/reorder mutations for DLG entries and replies, enabling modders to edit dialogue trees inline with full undo/redo support and hybrid validation (required fields block, optional fields warn).

**In Scope:**
- RepliesList mutations (add/remove/reorder replies to entries)
- EntriesList mutations (add/remove/reorder entry links within replies)
- Tree context menus for array operations
- Hybrid validation (required fields block save, optional warn)
- 8+ enumerated test scenarios covering add/remove/reorder, undo/redo, validation

**Out of Scope / Deferred:**
- Drag-reorder UI (context menu Move Up/Down only; drag = Phase 1.5+ enhancement)
- Resref picker (text input only; picker = Q8 enhancement)
- Visual condition editor (text editing only)
- Bulk operations (single-item mutations first; bulk = later enhancement)

**Dependencies:** Q1 (undo/redo) ✅, Q3 (typed helpers) ✅, Q7 (GFF array mutation pattern design) ⏳, DLG surface design ✅

---

## Key Technical Decisions

1. **Array Mutation Methods in KotorGFFDocument Base Class**
   - Decision: Design three generic array mutation methods (`insert_struct_at_array`, `remove_struct_from_array`, `reorder_array_item`) in KotorGFFDocument so Q7 GFF editing reuses the same pattern.
   - Rationale: Avoids duplication between Q6 DLG and Q7 GFF. Single pattern improves maintainability and consistency across format editors.

2. **Hybrid Validation (Required Blocks, Optional Warns)**
   - Decision: Define field-level schema — required fields (e.g., Entry link Index) block save with error styling; optional fields (comments) warn only.
   - Rationale: Prevents modders from exporting broken dialogues (dangling links) while allowing incremental metadata fixes.

3. **Context Menu for Array Mutations (No Drag in Phase 1)**
   - Decision: Primary reorder = context menu "Move Up/Down". Drag-and-drop deferred to Phase 1.5+.
   - Rationale: Follows proven Godot tree pattern (GFF editor). Drag adds implementation complexity with minimal ergonomic gain for typical workflows.

4. **Tree-First Edit Model**
   - Decision: Array mutations happen via tree context menus and inline struct field editors, not separate detail panel.
   - Rationale: Keeps modders' mental model aligned with hierarchy (entry → replies → links). Minimal new surface area vs. new modal/panel.

5. **Reference Validation at Mutation Time**
   - Decision: When reordering EntriesList, validate that target link Index still points to valid entry. Document the rule: reordering invalidates sibling links; mitigated by validation + test coverage.
   - Rationale: Prevents silent data corruption. Q6 documents the invariant; Q7+ refines if needed after GFF editing surfaces similar risks.

---

## High-Level Technical Design

```
DLG Structure (from Phase 2 DLG document design):
  EntryList[i] → RepliesList[] (replies to this entry)
              → RepliesList[j] → EntriesList[] (links back to entries)

Mutation Flow:
  User right-click on RepliesList item in tree
  → Context menu: "Add Reply", "Remove", "Move Up", "Move Down"
  → _apply_array_insert/remove/reorder() handler in dlg_workspace_editor.gd
  → Create undo/redo action, register _exec_array_*() do/undo methods
  → Call kotor_dlg_document.insert_struct_at_array() (mutation)
  → Document.mark_changed() → Tree refreshes via changed signal

Validation:
  1. Schema phase (U1): Define required/optional field schema for entry links
  2. Mutation phase (U2-U3): Check required fields before insert, warn on optional violations
  3. Test phase (U5): Enumerate validation blocking/warning behaviors

Reference Update on Reorder:
  - When reordering EntriesList[from] → EntriesList[to]:
    - Validate: Does Index field point to valid EntryList[Index]?
    - Warn if invalid; allow save (permissive model)
    - Test scenario: Verify no silent link corruption
```

---

## Implementation Units

### U1. Design Array Mutation Methods & Reference Rules (Phase 0 — Planning)

**Goal:** Design the three missing array mutation methods so Q6 DLG implementation follows the same pattern that Q7 GFF editing will build.

**Requirements:** Depends on planning decisions 1–5; enables U2, U3, U4.

**Dependencies:** None (planning task).

**Files:**
- `resources/documents/kotor_gff_document.gd` — Design contract (not yet implemented)
- `resources/documents/kotor_dlg_document.gd` — Document where methods will be added (Phase 1)

**Approach:**

1. **Method Contract Design:**
   - `insert_struct_at_array(array_field_name: String, index: int, struct_value: Dictionary) -> bool`
     - Inserts `struct_value` at position `index` within root[array_field_name]
     - Returns true if insert succeeded, false if index out of bounds
     - Calls `mark_changed()` after mutation
   - `remove_struct_from_array(array_field_name: String, index: int) -> bool`
     - Removes element at `index` from root[array_field_name]
     - Returns true if removal succeeded
     - Calls `mark_changed()` after mutation
   - `reorder_array_item(array_field_name: String, from_index: int, to_index: int) -> bool`
     - Moves element from `from_index` to `to_index`
     - Returns true if reorder succeeded
     - Calls `mark_changed()` after mutation

2. **Reference Validation Rules (for documentation):**
   - When reordering EntriesList within a Reply: check that each link's Index field still points to valid EntryList element
   - Rule: Reordering does NOT update Index fields (that's the modder's responsibility). Validation is warn-only (permissive model).
   - Test scenario: Insert entry link with Index=0, reorder to position 1, link should still point to EntryList[0]

3. **Struct Initialization:**
   - Default struct for new RepliesList entry: `{Index: -1, Comment: "", Active: "", IsChild: 0}`
   - Default struct for new EntriesList entry: `{Index: -1, Comment: "", Active: "", IsChild: 0}`
   - Q1 planning: confirm field names and defaults match DLG format spec

**Patterns to Follow:**
- `set_struct_field(struct_value, field_name, value)` pattern from kotor_dlg_document.gd:133-140 (check equality, mutate in-place, mark_changed, return bool)

**Test Scenarios:** None — design phase, no code generated.

**Verification:** Design document exists with method contracts, reference update rules, struct defaults, and rationale. Ready for implementation.

---

### U2. Implement Array Mutation Methods in KotorGFFDocument & KotorDLGDocument

**Goal:** Add the three array mutation methods to the base GFF document class (so Q7 GFF editing reuses them) and wire them to KotorDLGDocument.

**Requirements:** Advances R1 (struct/array mutations), R3 (undo/redo parity), and foundational contract for Q7.

**Dependencies:** U1 (design complete).

**Files:**
- `resources/documents/kotor_gff_document.gd` — Add base methods (insert_struct_at_array, remove_struct_from_array, reorder_array_item)
- `resources/documents/kotor_dlg_document.gd` — Inherit methods, add DLG-specific validation if needed

**Approach:**

1. **Implement in KotorGFFDocument:**
   - `insert_struct_at_array()` — Get root array field, bounds-check, insert at index, `mark_changed()`, return true
   - `remove_struct_from_array()` — Get root array field, bounds-check, remove at index, `mark_changed()`, return true
   - `reorder_array_item()` — Get root array field, bounds-check both indices, swap/move elements, `mark_changed()`, return true

2. **Validation in KotorDLGDocument (optional override):**
   - On insert/remove to RepliesList: check ReplyList size bounds (RepliesList indices must be < ReplyList.size())
   - On insert/remove to EntriesList: check EntryList size bounds (EntriesList indices must be < EntryList.size())
   - Validation is warn-only (documents pattern for Q6/Q7, permits permissive saves)

3. **Signal Pattern:**
   - Call `mark_changed()` after each mutation (inherited from KotorGFFDocument:297-298)
   - Emits `changed` signal → Tree refresh, dirty state update in UI

**Patterns to Follow:**
- `set_struct_field()` approach: in-place mutation, guard checks, `mark_changed()`, return bool
- `mark_changed()` behavior: emits signal, updates tracking

**Test Scenarios:**
- Insert struct into empty array (boundary)
- Insert at beginning, middle, end of existing array
- Remove single struct (boundary case)
- Remove from middle, preserves neighbors
- Reorder from start → end, end → start, adjacent swap
- Index bounds checking: reject negative, out-of-range

**Verification:** All mutations produce correct GFF state; `changed` signal fires; undo/redo consistency (tested at U5).

---

### U3. Add Context Menu Handlers & Undo/Redo Wiring in DLG Editor

**Goal:** Wire "Add Reply", "Remove", "Move Up/Down" context menu operations to array mutation methods with full undo/redo support.

**Requirements:** Advances R1 (add/remove/reorder), R2 (undo/redo), AC1, AC2.

**Dependencies:** U2 (array mutation methods exist).

**Files:**
- `ui/workspace/editors/dlg_workspace_editor.gd` — Add handlers and context menu wiring
- `ui/workspace/gff_tree_populator.gd` — Add context menu builder for DLG arrays (minimal change)

**Approach:**

1. **Context Menu Builder (gff_tree_populator.gd extension):**
   - Detect DLG array types: `RepliesList` (within entries) and `EntriesList` (within replies)
   - For array items, add right-click context menu with "Add [item]", "Remove", "Move Up", "Move Down"
   - Hide "Move Up" for first item, "Move Down" for last item
   - Store array path and item index in menu metadata for handler dispatch

2. **Handler Pattern (dlg_workspace_editor.gd):**
   - `_apply_array_insert(parent_struct, array_name, index, new_struct) → void`
     - Guard checks (document null, parent empty)
     - Get undo/redo manager, create action, register do/undo methods (follows U2 scalar pattern)
     - Call document.insert_struct_at_array() via undo/redo
   - `_apply_array_remove(parent_struct, array_name, index) → void`
     - Same pattern, calls document.remove_struct_from_array()
   - `_apply_array_reorder(parent_struct, array_name, from_index, to_index) → void`
     - Same pattern, calls document.reorder_array_item()
   - `_exec_array_insert/remove/reorder() → void` — Direct document calls (undo/redo do/undo targets)

3. **Tree Refresh:**
   - Document.changed signal triggers tree rebuild (existing pattern from Q1/Q3)
   - No explicit tree manipulation needed in handlers

**Patterns to Follow:**
- `_apply_*_edit()` → `_exec_*_edit()` with undo/redo (dlg_workspace_editor.gd:1060-1078)
- `_get_undo_redo()` manager pattern (dlg_workspace_editor.gd:1054-1057)
- Guard checks, early return on no-op (dlg_workspace_editor.gd:1064-1065)

**Test Scenarios:**
- Context menu visible on RepliesList/EntriesList items (not on scalars)
- "Add Reply" inserts new struct with defaults (Index:-1, Comment:"")
- "Remove" deletes item, shifts neighbors
- "Move Up/Down" reorders, preserves other links
- Undo/redo round-trip: add → undo → redo should restore state
- Menu disabled/hidden appropriately for first/last items

**Verification:** Menu handlers fire, mutations apply via document, undo/redo state consistent, tree rebuilds correctly.

---

### U4. Inline Struct Field Editing in Array Items + Hybrid Validation

**Goal:** Enable editing of struct fields (condition text, entry link Index) within tree nodes, with required fields blocking save and optional fields warning.

**Requirements:** Advances R2 (struct field editing in tree), R3 (validation), AC3.

**Dependencies:** U2 (array methods exist), U3 (handlers exist).

**Files:**
- `ui/workspace/gff_tree_populator.gd` — Render struct fields as editable tree cells
- `ui/workspace/editors/dlg_workspace_editor.gd` — Add `_apply_struct_field_edit()` handler (reuse Q3 pattern) with validation dispatch
- `resources/typed_field_helpers.gd` — Add hybrid validation helpers (check required vs. optional fields)

**Approach:**

1. **Inline Field Rendering (gff_tree_populator.gd):**
   - When populating entry-link (EntriesList) or reply (RepliesList) struct children, render key fields as editable tree cells
   - Example fields: Index (int, editable), Comment (string, editable), Condition (string, editable, for replies)
   - Use `TreeItem.set_editable(column, true)` to enable inline editing
   - Store field path as metadata (struct path + field name)

2. **Field Edit Handler (dlg_workspace_editor.gd):**
   - On tree item_edited signal, call `_apply_struct_field_edit(struct_value, field_name, new_value)`
   - Reuse Q3 scalar pattern (dlg_workspace_editor.gd:1060-1085)
   - For resref fields: truncate via TypedFieldHelpers.validate_resref()
   - For Index fields (entry links): validate against EntryList size → block if invalid
   - For optional fields (comment): allow any value, warn if empty

3. **Hybrid Validation Rules:**
   - **Required:** Entry link Index must be 0 ≤ Index < EntryList.size() → BLOCK with error styling
   - **Optional:** Comment, Condition script → WARN if empty, allow save anyway
   - Styling: Red background for blocked errors, yellow for warnings (Q3 pattern adaptation)

4. **Validation Helpers (typed_field_helpers.gd):**
   - `is_required_field(field_name) → bool` — Returns true for Index, etc.
   - `validate_required_field(field_name, value) → bool` — Returns true if valid
   - `get_validation_warning(field_name, value) → String` — Returns warning text or ""

**Patterns to Follow:**
- Scalar field edit pattern (dlg_workspace_editor.gd:1060-1085, 1088-1113)
- TreeItem.set_editable() and item_edited signal (gff_tree_populator.gd:44, 50)
- TypedFieldHelpers validation (typed_field_helpers.gd:69-80)

**Test Scenarios:**
- Edit Index on entry link: valid (< EntryList.size()) → allow, invalid (≥ size) → block with error
- Edit Comment on reply: empty string → warn but allow, non-empty → allow
- Edit Condition script: empty → warn but allow, invalid syntax → warn (no parser validation in Q6)
- Undo/redo on field edit: change → undo → original value restored
- Validation styling visible (red for blocked, yellow for warning)

**Verification:** Field edits apply correctly, validation blocks/warns appropriately, undo/redo works for field changes, tree updates reflect new values.

---

### U5. Test Suite: 8+ Scenarios Covering Add/Remove/Reorder, Undo/Redo, Validation

**Goal:** Write comprehensive test scenarios covering happy path, boundary cases, undo/redo, and validation failure modes.

**Requirements:** Advances AC1–AC4, ensures quality signal for production ship.

**Dependencies:** U1–U4 (all units complete).

**Files:**
- `tests/editor/test_dlg_workspace_editor.gd` — Add test methods for array mutations (extend existing Q1/Q3 tests)

**Approach:**

1. **Test Structure (follow existing pattern from test_dlg_workspace_editor.gd):**
   - Setup phase: Build dialogue resource with entries, replies, entry links
   - Per-test: Apply mutation, assert state, undo/redo round-trip
   - Cleanup: Free resources

2. **Scenario Enumeration:**

   **Happy Path (2 scenarios):**
   - **AC1.1:** Add reply to entry with existing replies → new reply appears at specified index
   - **AC1.2:** Reorder replies up/down → order changes, all other fields preserved

   **Add/Remove Boundaries (3 scenarios):**
   - **AC2.1:** Add entry link to empty EntriesList → single link, Index validates
   - **AC2.2:** Remove middle entry link from sequence → neighbors shift, Index fields warn if stale
   - **AC2.3:** Remove last reply from entry → entry now has empty RepliesList (valid state)

   **Undo/Redo (2 scenarios):**
   - **AC3.1:** Add reply → undo → reply removed; redo → reply restored (full round-trip consistency)
   - **AC3.2:** Remove entry link → undo → link restored; redo → link removed (state parity)

   **Validation Blocking/Warning (2 scenarios):**
   - **AC4.1:** Add entry link with Index ≥ EntryList.size() → ERROR, save blocked, error styling visible
   - **AC4.2:** Add entry link with empty Comment → WARN but allow save, warning styling visible

   **Additional Edge Cases (1+ scenarios):**
   - Reorder first item to last, vice versa
   - Multiple mutations in sequence (add → add → reorder → remove)
   - Undo beyond initial state (should no-op gracefully)

3. **Test Helper Functions:**
   - `_build_dialogue_with_replies(entry_count, replies_per_entry)` → DLGResource
   - `_assert_array_equals(actual, expected, message)` → bool
   - `_apply_and_verify_mutation(mutation_type, params, expected_state)` → void

**Patterns to Follow:**
- Test resource factory (test_dlg_workspace_editor.gd:301-413)
- Undo/redo round-trip verification (test_dlg_workspace_editor.gd:75-84)
- Dirty state checking (test_dlg_workspace_editor.gd:72-73)
- Signal connection and emission count (test_dlg_workspace_editor.gd:238-256)

**Test Scenarios:** (enumerated above, 8+ total)

**Verification:** All tests pass; code coverage ≥ 85% for array mutation methods; edge cases handled.

---

## Scope Boundaries

### Deferred to Follow-Up Work

- **Drag-and-drop reorder UI** — Phase 1.5+ enhancement; context menu sufficient for MVP
- **Resref picker** — Q8 deliverable; text input only in Phase 1
- **Visual condition editor** — Text editing only; defer syntax highlighting/autocomplete to Q8+
- **Bulk array operations** — Single-item mutations first; multi-select reorder in later enhancement
- **GFF array editing** — Q7 will adapt Q6 patterns; Q6 is DLG-only

### Outside Scope

- **Dialogue tree graph visualization** — Separate product surface; out of scope for vertical slice
- **Speaker action mutations** — KotOR DLG format does not use speaker actions; term was incorrect in initial brainstorm
- **Cross-file dialogue linking** — Q6 works within single DLG; Q8 resref picker enables cross-file in Phase 1.5+

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Reordering EntriesList invalidates Index fields (stale links) | High | Phase 0 documents rule: reordering does NOT update sibling Index fields; modder is responsible. Test scenarios verify warning behavior, document invariant. |
| Array mutations produce invalid GFF (schema violations) | High | U1 design specifies struct defaults and field requirements. U4 validates required fields block save. U5 tests enumerated error paths. |
| Undo/redo state inconsistency (array size mismatch after undo) | High | U5 tests undo/redo round-trip for each mutation type. Q1 pattern already proven; U2/U3 follow established approach. |
| Context menu cluttered with too many options | Medium | U3 hides irrelevant actions (Move Up for first, Move Down for last). Future: nested menus if needed (Phase 1.5+). |
| Modders save with warnings and export broken dialogues | Medium | U4 hybrid validation: REQUIRED fields block save (e.g., Index out of bounds). OPTIONAL fields warn only. Documentation clarifies field-level schema. |
| Performance with large DLG files (100+ entries, 50+ replies) | Low | GDScript tree operations are fast for typical sizes. U5 includes perf scenario: rebuild tree with 1000 items. |

---

## System-Wide Impact

**DLG Workspace Editor:**
- Tree rendering extended to include array context menus and inline struct field editing (U3, U4)
- Document mutation handlers follow established pattern (U2, U3)
- Dirty state and undo/redo already integrated (no new machinery)

**GFF Document & Typing:**
- Base array mutation methods added to KotorGFFDocument (U2) — enables Q7 reuse
- No breaking changes to existing scalar mutation APIs
- TypedFieldHelpers extended with hybrid validation helpers (U4)

**Test Coverage:**
- Extends existing test_dlg_workspace_editor.gd with 8+ scenarios (U5)
- No new test infrastructure required

**No Impact On:**
- Plugin core, importer/saver registration, gamefs
- Q1/Q3 scalar editing, existing DLG surface
- Other editors (GFF, 2DA, TLK, Script)

---

## Success Criteria

- [ ] All AC1–AC4 acceptance criteria met with verified test cases
- [ ] 8+ enumerated test scenarios passing (happy path, boundaries, undo/redo, validation)
- [ ] Hybrid validation implemented (required fields block, optional warn)
- [ ] Context menu operations (Add, Remove, Move Up/Down) functional for RepliesList and EntriesList
- [ ] GDScript validation passes (`godot --check-only` on modified files)
- [ ] No breaking changes to DLG document structure or existing scalar mutations
- [ ] Code review: patterns align with Q1 undo/redo and Q3 typed helpers
- [ ] PR merged; tracked in release notes as Q6 ship

---

## Definition of Done

- [ ] **U1 (Design):** Array mutation method contracts, reference update rules, struct defaults documented
- [ ] **U2 (Implementation):** `insert_struct_at_array`, `remove_struct_from_array`, `reorder_array_item` added to KotorGFFDocument; inherited/validated in KotorDLGDocument
- [ ] **U3 (Implementation):** Context menu handlers wired; `_apply_array_*()` and `_exec_array_*()` methods added to dlg_workspace_editor.gd with undo/redo
- [ ] **U4 (Implementation):** Inline struct field editing in tree; hybrid validation (required block, optional warn); validation helpers added
- [ ] **U5 (Tests):** 8+ enumerated test scenarios written, passing, covering add/remove/reorder boundaries, undo/redo, validation blocking/warning
- [ ] **GDScript Validation:** `godot --check-only` passes on all modified editor files
- [ ] **Backward Compatibility:** No breaking changes to DLG document, existing mutations still work
- [ ] **Code Review:** P0/P1 issues resolved, patterns align with Phase 2 conventions
- [ ] **PR:** Merged to main; execution queue updated to mark Q6 as shipped

---

## Deferred Implementation Unknowns

- **Final struct defaults:** Confirm exact field names and default values for RepliesList/EntriesList entries during U2 implementation (may require GFF schema review)
- **Validation rule details:** Field-level schema (which fields required vs. optional) finalized during U4 planning before implementation
- **Error message copy:** Exact validation error strings defined during U4 implementation
- **Test resource complexity:** Actual test dialogue structure (entry count, reply branching) determined during U5 implementation based on coverage needs

