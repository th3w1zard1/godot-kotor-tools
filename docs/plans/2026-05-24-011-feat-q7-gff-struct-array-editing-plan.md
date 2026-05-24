---
created: 2026-05-24
updated: 2026-05-24
type: feat
status: active
origin: docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md
phase: Q7
track: Phase 2 Capability Expansion
---

# Q7: GFF Struct/Array Editing

## Summary

Extend GFF-level editing to support array mutations (add/remove/reorder) and struct-field editing for complex hierarchies. Build on Q6 DLG array patterns and Q3 typed helpers to enable safe, validated editing of locstring trees, complex structs (UTC entries, condition blocks, quest data), and field arrays within GFF resources.

---

## Problem Frame

Q6 shipped array mutation UI for DLG-specific containers (EntryList, RepliesList). Q7 generalizes this to GFF resources: allow modders to edit struct-containing arrays and inline complex struct fields (especially locstrings with language variants) through safe, undo/redo-backed workspace editors. Current state forces modders to:

1. Edit arrays through text/hex inspection (error-prone)
2. Rebuild dialogue trees manually after reordering (tedious)
3. Accept limited locstring UX (single-language text only)

Q7 outcome: Full GFF struct mutation parity — add/remove/reorder array elements and edit nested struct fields without leaving workspace, with validation, undo/redo, and installation-aware refresh.

---

## Actors

- **A1. Modder** — edits complex GFF structures (UTC entries, quest records, condition blocks) and expects array mutations to be as reliable as scalar field edits
- **A2. Contributor** — implements GFF-level editors following patterns from Q6 (DLG) and Q3 (typed helpers)
- **A3. GFF workspace editor** — routes mutations through document abstractions, manages tree refresh and undo/redo boundaries

---

## Key Flows

- **F1. Struct-array mutation (add/remove/reorder)** — A1 right-clicks a struct in array, selects "Add/Remove/Move", mutation routes through `_apply_*()` handler → `_exec_*()` → document method → mark_changed() → tree refresh. Undo/redo available for all operations.
- **F2. Inline struct field editing** — A1 edits nested fields (e.g., locstring text, condition script) within struct array members. Validation enforces required fields; optional fields warn. Changes trigger tree refresh and dirty state.
- **F3. Post-mutation state consistency** — A3 ensures tree refresh captures new/removed/reordered structs correctly; validation state propagates to UI; undo/redo round-trip preserves all state.

---

## Requirements

From `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`:

- **R1 (Undo/Redo)** — Workspace editors support clear undo/redo boundaries for document mutations (covers `set_field`, array mutations, struct mutations)
- **R2 (Validation Semantics)** — Undo/redo preserves validation and changed-signal propagation (validation state persists across undo/redo cycles)
- **R6 (High-Frequency Fields)** — New editing ergonomics prioritize locstrings, resource references, and enum-like selectors
- **R7 (Consistency & Diagnostics)** — Mutation consistency includes failure-path handling; user-visible error context (not just happy-path)
- **R8 (Slice Boundaries)** — Q7 is self-contained; no architectural rewrites (reuse patterns from Q1-Q6)

---

## Acceptance Criteria

- **AC1** — Given a GFF resource with struct array (e.g., UTC entries), when A1 adds/removes/reorders a struct via context menu, the array size, ordering, and item indices update correctly and persist on save
- **AC2** — Given a struct array mutation, when A1 invokes undo/redo, all values, indices, validation state, and changed indicators return to prior/next state consistently
- **AC3** — Given an inline struct field edit (locstring, enum, resref), when A1 edits and saves, validation blocks on invalid required fields and warns on empty optional fields without blocking
- **AC4** — Given a GFF struct with complex fields (nested structs, locstring arrays, condition blocks), when A1 edits via tree UI, the tree refreshes correctly and undo/redo preserves order and hierarchy
- **AC5** — Given a struct array mutation failure (e.g., bounds check, invalid field), when the operation is attempted, the editor preserves current data and surfaces a clear error message (not silent skip)

---

## Key Technical Decisions

| Decision | Rationale | Impact |
|----------|-----------|--------|
| **Reuse Q6 array methods** | `insert_struct_at_array()`, `remove_struct_from_array()`, `reorder_array_item()` already in `KotorGFFDocument` base class; no reimplementation needed. DLG patterns apply 1:1 to GFF. | Q7 context menus call same document methods; no array mutation code duplication. Handlers follow `_apply_*()` + `_exec_*()` pattern from Q6. |
| **Generalize Q6 context menu** | DLG editor (dlg_workspace_editor.gd) created context menus for EntryList/RepliesList. GFF editor (gff_workspace_editor.gd) extends gff_tree_populator to mark all struct-array items the same way. | Tree populator constants (e.g., `DLG_ARRAY_FIELDS`) become `GFF_ARRAY_FIELDS`; context menu handler follows identical pattern (item marked with field name + index → menu action). Single codebase pattern across DLG and GFF surfaces. |
| **Hybrid validation (required blocks, optional warns)** | Q6 pattern: required fields (e.g., Index) block save; optional fields (Comment, Active) warn. Extend to GFF types: define schema per struct type (UTC entry: Index required; Comment optional, etc.). | Implementer defines `is_required_field()` extensions in `typed_field_helpers.gd` for each GFF struct type. UI styling reflects validation state (red = error, yellow = warning). |
| **Locstring tree iteration** | Q7 Phase 1: Support single-language (ID=0) text editing via `set_locstring_text()` pattern (proven in Q3). Q8 will add multi-language picker and strref resolution. | Q7 focuses on simpler UX; locstring display shows summary (English + fallback); edit mode allows text-only for ID=0. Full multi-language picker deferred to Q8 (typed field picker expansion). |
| **No automatic reference updates** | Reordering struct arrays does NOT auto-update sibling reference fields (documented in Q6 design). Modders manually fix stale references; validation warns. | Preserves clarity; prevents silent data loss. Test coverage ensures warnings are visible. Future enhancement: "Fix stale refs" batch operation. |
| **Struct initialization defaults** | New struct instances start with sensible defaults (Index=-1 for links, Comment="", Active="", flags=0). Allows incremental authoring; validation signals incomplete links. | Modders can add structure, then fix references later (permissive model). Each GFF struct type must define defaults (e.g., Quest struct defaults differ from UTC entry defaults). |

---

## Scope Boundaries

### Included in Q7

- Array mutations (add/remove/reorder) via context menu on struct arrays (UTC entries, condition blocks, quest records)
- Inline struct field editing (strings, enums, resrefs, locstrings) within array members
- Hybrid validation (required blocks, optional warns)
- Undo/redo boundaries for all mutations
- Tree refresh after mutations (via mark_changed() signal)
- Single-language locstring editing (English text only)
- Test scenarios covering happy path, boundaries, undo/redo, validation
- GFF workspace editor (gff_workspace_editor.gd) — parallel to dlg_workspace_editor established in Q6

### Deferred to Follow-Up Work

- **Q8: Typed field picker UIs** — Multi-language locstring editing, strref file browser, enum combo sourced from gamefs registry
- **Phase 1.5+ Enhancements** — Drag-reorder UI (low priority), batch "fix stale refs" operation, struct cloning/copying
- **Outside this product's identity** — External diff/merge tools for manual reference fixing; per-type validation rule dialogs

---

## Implementation Units

### U1. Design GFF struct/array mutation schema and validation rules

**Goal:** Define struct field schemas, array mutability rules, and validation strategy per GFF struct type (UTC, UTP, quest records, condition blocks). Create design document with defaults, required/optional field categorization, and reference update rules.

**Requirements:** R6 (field prioritization), R7 (diagnostics), R8 (reusable patterns)

**Dependencies:** None (planning artifact)

**Files:**
- `docs/designs/2026-05-24-011-q7-gff-struct-array-schema.md` (new design doc)

**Approach:**
1. Identify target struct types in Q7 (UTC entries, condition blocks, quest data, loot tables)
2. For each type, define:
   - **Mutability:** Which arrays are editable (EntryList, ConditionalList, etc.)
   - **Schema:** Which fields are required, optional, read-only
   - **Defaults:** Sensible initial values for new struct instances
   - **References:** Which fields link to other arrays and validation rules
3. Extend typed_field_helpers schema categories (enum fields, resref, locstring)
4. Document parallel to Q6 DLG design (line-by-line decisions for implementer reference)

**Patterns to follow:**
- `docs/designs/2026-05-24-010-q6-array-mutation-design.md` (method contracts, validation rules, defaults)
- `formats/kotor_gff_parser.gd` (GFF struct field definitions by type)
- `resources/typed/` (existing struct-specific resource wrappers)

**Test scenarios:** None (design phase, no behavioral change)

**Verification:**
- Schema document covers at least 3 GFF struct types
- Required/optional field categorization matches type definitions from parser
- Defaults include rationale
- Reference update rules explicitly stated (e.g., "reordering does NOT auto-update Index")

---

### U2. Extend tree populator to mark GFF struct arrays

**Goal:** Generalize `gff_tree_populator.gd` to mark struct-containing array items with metadata, enabling context menu detection for all GFF types (not just DLG). Extend `DLG_ARRAY_FIELDS` constant to include GFF arrays from U1 schema.

**Requirements:** R8 (reuse patterns)

**Dependencies:** U1 (schema defines which arrays are editable)

**Files:**
- `ui/workspace/gff_tree_populator.gd` (modify)

**Approach:**
1. Rename `DLG_ARRAY_FIELDS` → `EDITABLE_ARRAY_FIELDS` or create combined dict with format type + array field names
2. Extend `populate()` to mark items in GFF struct arrays with same metadata as DLG:
   - `META_IS_DLG_ARRAY_ITEM` (keep naming for compat, applies to all formats)
   - `META_ARRAY_FIELD` = field name (e.g., "EntryList", "ConditionalList")
   - `META_ARRAY_INDEX` = numeric index
3. Add type-aware filtering: only mark arrays listed in schema (U1) as editable
4. Handle nested arrays (structs within arrays within structs) — annotate path correctly

**Patterns to follow:**
- `gff_tree_populator.gd` lines 32–47 (DLG array item marking)
- `ui/workspace/gff_workspace_editor.gd` (parallel editor surface to dlg_workspace_editor)

**Test scenarios:**
- Mark array items in UTC resource with EntryList (happy path)
- Mark only editable arrays; skip read-only arrays
- Verify metadata structure for nested struct arrays
- Boundary: empty array (no items to mark)

**Verification:**
- Tree populator marks struct array items for at least 2 GFF types
- Right-click on marked item triggers context menu (tested in U3)
- Metadata structure matches Q6 DLG pattern (item.get_metadata(META_ARRAY_FIELD) returns field name)

---

### U3. Implement GFF workspace editor context menus and undo/redo handlers

**Goal:** Create GFF-level context menu handlers for struct array mutations (add/remove/reorder). Wire undo/redo using EditorUndoRedoManager following Q6 pattern. Handlers call document array methods and trigger tree refresh.

**Requirements:** R1 (undo/redo), R2 (validation semantics), R7 (error paths), R8 (reuse patterns)

**Dependencies:** U1 (schema), U2 (tree marking)

**Files:**
- `ui/workspace/editors/gff_workspace_editor.gd` (modify or create new for GFF-specific handling)

**Approach:**
1. Add context menu infrastructure (PopupMenu instance + signal handlers):
   - Detect right-click on marked struct-array item (item_mouse_selected signal with button_index==2)
   - Show context menu with "Add Item", "Remove Item", "Move Up" (disabled if first), "Move Down" (disabled if last)
2. Implement `_apply_array_*()` handlers (boundary entry points):
   - `_apply_array_insert(array_field_name, index, default_struct)`
   - `_apply_array_remove(array_field_name, index)`
   - `_apply_array_reorder(array_field_name, from_index, to_index)`
3. Implement `_exec_array_*()` methods (undo/redo targets, call document methods):
   - `_exec_array_insert()` → calls `document.insert_struct_at_array()`
   - `_exec_array_remove()` → calls `document.remove_struct_from_array()`
   - `_exec_array_reorder()` → calls `document.reorder_array_item()`
4. Undo/redo boundary pattern (from Q6, proven in Q1-Q5):
   ```gdscript
   var ur := _get_undo_redo()
   if ur != null:
       ur.create_action("Insert GFF struct", UndoRedo.MERGE_DISABLE, self)
       ur.add_do_method(self, "_exec_array_insert", array_field_name, index, default_struct)
       ur.add_undo_method(self, "_exec_array_remove", array_field_name, index)
       ur.commit_action()
   else:
       _exec_array_insert(...)  # Headless fallback
   ```
5. Error handling: Guard checks, bounds validation, user-visible error messages (R7)

**Patterns to follow:**
- `dlg_workspace_editor.gd` lines 519–579 (context menu infrastructure)
- `dlg_workspace_editor.gd` lines 1270–1341 (undo/redo handler pattern)
- `resources/kotor_gff_document.gd` lines 153–196 (array method signatures to call)
- `typed_field_helpers.gd` (validation helpers for error messaging)

**Test scenarios:**
- Insert struct into array at various positions (prepend, append, middle)
- Remove struct (first, middle, last item; empty after last removal)
- Reorder struct (move up/down, boundary conditions)
- Undo/redo round-trip: insert → undo → redo → verify values/indices/dirty state
- Error paths: invalid index, bounds check, missing field — verify error message surface (not silent fail)
- Context menu disabled states: "Move Up" unavailable on first item, "Move Down" unavailable on last

**Verification:**
- Context menus appear on right-click on marked struct-array items
- All three mutation types (insert/remove/reorder) route through handlers without errors
- Undo/redo work across all mutation types with consistent state preservation
- Error conditions produce user-visible messages (not crash or silent skip)

---

### U4. Integrate struct field editing with hybrid validation

**Goal:** Extend inline struct field editing (Q3 pattern) to handle struct fields within arrays. Integrate required/optional validation so required fields block save and optional fields warn. Update typed_field_helpers with GFF struct field categorization from U1 schema.

**Requirements:** R2 (validation semantics), R6 (field prioritization), R7 (error paths)

**Dependencies:** U1 (schema defines required/optional), U3 (array context ready for field edits)

**Files:**
- `ui/workspace/typed_field_helpers.gd` (extend validation)
- `ui/workspace/editors/gff_workspace_editor.gd` (integrate validation into field edit handlers)

**Approach:**
1. Extend `typed_field_helpers.gd`:
   - Add GFF struct type schemas (e.g., `is_required_field_for_type(struct_type, field_name) → bool`)
   - For each struct type (UTC entry, condition block, quest record), define required vs optional fields
   - Extend `validate_required_field()` to accept struct type context
2. Implement field edit handlers in gff_workspace_editor:
   - `_apply_*_edit()` for string, int, bool, enum, resref, locstring (parallel to DLG editor lines 1173–1239)
   - Call validation helpers: `TypedFieldHelpers.is_required_field()` → block on invalid, `get_validation_warning()` → warn only
   - Use same undo/redo pattern (apply/exec split)
3. Validation UI:
   - Required field invalid state: show error icon/red color in tree, error message in log
   - Optional field empty state: show warning icon/yellow color in tree, warning in log
4. Integration: Tree cell editing triggers validation immediately (not deferred to save)

**Patterns to follow:**
- `dlg_workspace_editor.gd` lines 1173–1239 (string/int edit handlers with validation)
- `typed_field_helpers.gd` lines 85–115 (Q6 hybrid validation helpers)
- `docs/designs/2026-05-24-010-q6-array-mutation-design.md` (reference validation rules precedent)

**Test scenarios:**
- Edit required field with valid value (succeeds)
- Edit required field with invalid value (blocked, error message)
- Edit optional field with empty value (warns, allows save)
- Edit optional field with valid value (succeeds, no warning)
- Undo/redo field edit in array context (state preserved)
- Locstring text edit (single language, ID=0 only, Q7 scope)
- Enum field edit (dropdown from schema)
- ResRef edit (length validation, clamping)

**Verification:**
- Required fields defined per struct type (UTC, UTP, quest)
- Invalid required field edit produces user-visible error
- Optional field edit warns but doesn't block save
- Validation state persists across undo/redo cycles
- Validation matches struct type context (different rules for UTC vs quest)

---

### U5. Write comprehensive test suite covering struct array and field mutations

**Goal:** Add 12+ test scenarios to test suite covering happy paths (insert/remove/reorder, field edits), boundaries (empty arrays, last items, required/optional fields), undo/redo round-trips, error paths, and integration with tree refresh.

**Requirements:** R1 (undo/redo), R2 (validation), R7 (error paths), R8 (reuse patterns)

**Dependencies:** U2 (tree marking), U3 (context menus), U4 (validation)

**Files:**
- `tests/editor/test_gff_workspace_editor.gd` (new, parallel to test_dlg_workspace_editor.gd)

**Approach:**
1. Create test suite extending `SceneTree` (headless runner, proven pattern from Q6)
2. Build test resource: UTC with entries array and nested condition blocks
3. Test categories:
   - **Happy path (3 scenarios):** Insert entry, remove entry, reorder entry
   - **Boundaries (3 scenarios):** Insert into empty array, remove last item, reorder edge cases
   - **Field editing (3 scenarios):** Edit required field (valid), edit required field (invalid), edit optional field
   - **Undo/redo (2 scenarios):** Array mutation round-trip, field edit round-trip
   - **Integration (1+ scenario):** Tree refresh after array mutation, dirty state tracking
4. Each scenario:
   - Open resource in editor, perform mutation
   - Assert state change (size, ordering, values, indices)
   - Assert dirty flag, validation state, signal emission
   - For undo/redo tests: undo() → redo() → assert original state restored/reapplied

**Patterns to follow:**
- `tests/editor/test_dlg_workspace_editor.gd` (test structure, resource builder, assertions)
- `docs/brainstorms/2026-05-24-010-q6-dlg-struct-array-editing-requirements.md` lines 267–276 (test scenario categories)

**Test scenarios:** (see above categories; 12+ enumerated)

**Verification:**
- All test scenarios pass on first run
- Undo/redo tests verify exact state preservation (not approximate)
- Error path tests verify error messages are surfaced (not silent)
- Test coverage matches Q6 pattern (happy/boundary/undo/redo/validation)

---

## High-Level Technical Design

### Context Menu Flow (Established in Q6, Reused in Q7)

```
Right-click on struct-array item (marked by tree populator)
  ↓
gff_workspace_editor receives item_mouse_selected(at_position, button_index)
  ↓
Check item metadata (META_IS_DLG_ARRAY_ITEM == true) [generic marker]
  ↓
Build context menu:
  - "Add Item" (always enabled)
  - "Remove Item" (enabled if array not empty)
  - "Move Up" (enabled if not first item)
  - "Move Down" (enabled if not last item)
  ↓
User selects action
  ↓
_apply_array_insert/remove/reorder() [signal handler, boundary entry]
  ↓
EditorUndoRedoManager:
  - create_action("Insert GFF struct", MERGE_DISABLE, self)
  - add_do_method(self, "_exec_array_insert", ...)
  - add_undo_method(self, "_exec_array_remove", ...)
  - commit_action()
  ↓
_exec_array_insert/remove/reorder() [undo/redo target, execute=true]
  ↓
document.insert_struct_at_array(array_field_name, index, struct_value)
  ↓
mark_changed() [emit changed signal]
  ↓
Tree refresh (signal handler in editor listens to document.changed)
```

### Struct Field Editing Flow (Q3 Pattern Extended)

```
User clicks struct field cell (e.g., locstring text, enum, resref)
  ↓
_on_tree_item_edited() signal handler
  ↓
_apply_*_edit(struct_value, field_name, new_value) [boundary entry]
  ↓
TypedFieldHelpers.is_required_field(field_name, value) [validation check]
  ↓
If REQUIRED and INVALID:
  - push_error() (user-visible)
  - return (no mutation)
Else (REQUIRED+valid OR OPTIONAL):
  - EditorUndoRedoManager boundary
  - _exec_*_edit() [mutation target]
  - document.set_field() / set_locstring_text() [document method]
  - mark_changed()
  ↓
Tree refresh
  ↓
If OPTIONAL and EMPTY:
  - push_warning() [non-blocking]
```

### Schema-Driven Validation

For each GFF struct type (UTC, UTP, quest), define:

```gdscript
# In typed_field_helpers.gd (or separate schema module)
static var STRUCT_SCHEMAS = {
    "UTCCreature": {
        "required_fields": ["ResRef"],
        "optional_fields": ["Comment", "Tag"],
        "defaults": {"ResRef": "", "Comment": "", "Tag": ""}
    },
    "QuestRecord": {
        "required_fields": ["Title"],
        "optional_fields": ["Description"],
        "defaults": {"Title": "", "Description": ""}
    },
    # ... per struct type
}

static func is_required_field(struct_type: String, field_name: String) -> bool:
    var schema = STRUCT_SCHEMAS.get(struct_type, {})
    return field_name in schema.get("required_fields", [])
```

---

## Patterns to Follow

- **Array methods:** `resources/kotor_gff_document.gd` lines 153–196 (insert/remove/reorder signatures and implementation)
- **Context menu:** `ui/workspace/editors/dlg_workspace_editor.gd` lines 519–579 (menu creation and item marking detection)
- **Undo/redo handlers:** `ui/workspace/editors/dlg_workspace_editor.gd` lines 1270–1341 (apply/exec split, signal boundaries)
- **Validation:** `ui/workspace/typed_field_helpers.gd` lines 85–115 and `dlg_workspace_editor.gd` lines 1200–1239 (required blocks, optional warns)
- **Tree marking:** `ui/workspace/gff_tree_populator.gd` lines 32–47 (metadata constants and population)
- **Test structure:** `tests/editor/test_dlg_workspace_editor.gd` lines 1–100 (headless runner, resource builder, assertion helpers)
- **Design reference:** `docs/designs/2026-05-24-010-q6-array-mutation-design.md` (method contracts, validation rules, defaults, pattern precedent)

---

## System-Wide Impact

**Affected Components:**
- **GFF workspace editor** — New context menu surface for struct arrays (parallel to DLG editor)
- **Tree populator** — Extended to mark all editable struct-array items
- **Document layer** — Array methods already in place (Q6); validation extensions added
- **Typed field helpers** — Extended with GFF struct type schemas
- **Test suite** — New test file for GFF editor (parallel to DLG tests)

**User Impact:**
- Modders gain struct mutation UI for all GFF types (not just DLG)
- Editing is safer (validation enforces required fields, warns on optional)
- Undo/redo works reliably across all mutations
- Tree reflects changes immediately (signal-driven refresh)

**Contributor Impact:**
- Reuse Q6 array methods (no new mutation logic)
- Extend Q3 validation pattern (per-type schema definition)
- Follow established undo/redo boundaries (apply/exec split)
- Test coverage matches Q6 pattern (happy/boundary/undo/validation)

**Installation-Aware Workflow:**
- Mutations trigger `mark_changed()` → dirty tracking → save prompt
- Write-back uses existing document serialization (no new serializers needed for Q7)
- Post-save refresh via mutation pipeline (established in Q2)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| **Complex struct hierarchies missing validation** | U1 schema design identifies all struct types + fields upfront; test suite covers each type. |
| **Reordering breaks sibling references** | Design (U1) documents "no auto-update" rule; validation warns on stale refs; test scenarios verify warnings. |
| **Undo/redo state inconsistency** | Follow Q6 apply/exec pattern; test round-trips verify exact state preservation (not approximate). |
| **Tree refresh lag or missed updates** | Use signal-driven refresh (proven in Q1-Q6); test integration scenarios verify refresh timing. |
| **Locstring multi-language too complex** | Q7 focuses on single-language (English) text edit; defer multi-language UI to Q8 typed field picker. |
| **Error messages unclear to modders** | R7 requirement + test scenarios ensure error diagnostics surface user-visible context. |

---

## Deferred Implementation Notes

1. **Exact struct defaults per GFF type** — U1 design will enumerate (TBD during planning review)
2. **UI styling for validation state** — Tree icons/colors for error vs warning (TBD, may vary by editor)
3. **Context menu position/animation** — Godot PopupMenu positioning TBD (follow Q6 pattern as starting point)
4. **Struct cloning for "duplicate item"** — Useful enhancement; deferred to Phase 1.5
5. **Batch reference fix operation** — "Fix stale refs" command; deferred to Phase 1.5+
6. **Multi-language locstring UI** — Full implementation deferred to Q8; Q7 uses single-language pattern from Q3

---

## Verification Criteria

- ✅ GFF struct arrays (UTC, UTP, quest) support add/remove/reorder via context menu
- ✅ All mutations have working undo/redo with state preservation
- ✅ Required struct fields enforce validation (block save on invalid)
- ✅ Optional struct fields warn but allow save
- ✅ Tree refresh works correctly after mutations
- ✅ Test suite passes all 12+ scenarios (happy path, boundaries, undo/redo, validation, error paths)
- ✅ GDScript validation: `godot --check-only` passes for all modified files
- ✅ Pattern compliance: Follows Q6 array design, Q3 validation, Q1 undo/redo boundaries
- ✅ AC1-AC5 acceptance criteria met (struct array mutations, undo/redo, validation, tree refresh, error paths)
