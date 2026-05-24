---
status: active
created: 2026-05-24
type: feat
---

# Phase 2 Capability Expansion: DLG Undo/Redo, Typed Helpers, Documentation Updates

## Summary

Implement the final deferred work from Q1, expand Q3's typed editing helpers, and update execution documentation to reflect Q1–Q5 completion. Phase 2 includes DLG editor undo/redo wiring via lambda-to-named-method refactor, Q3 field-specific editing enhancements (resref validation, enum/dropdown selectors), capability queue documentation refresh, and planning infrastructure for future waves. Work sequences in three parallel tracks: DLG undo/redo (blocks nothing, unblocks downstream DLG improvements), typed helpers (incremental improvements to existing editors), and documentation (async planning artifact).

---

## Problem Frame

Q1–Q5 shipped strong editor mutations, persistence, bool checkboxes, archive write-back, and context actions. However, three categories of follow-up work remain before Q6+ can execute cleanly:

1. **DLG editor mutations** are still Lambda-captured, preventing undo/redo wiring — a safety regression versus GFF/2DA/TLK editors that already have full undo/redo support.
2. **Q3 typed helpers** (locstrings, resource references, enum-like selectors) have only basic editing support — high-frequency fields lack guided controls and input validation that would reduce manual errors.
3. **Execution documentation** (capability queue, gap analysis cross-links) is not yet updated to mark Q1–Q5 as shipped or surface Q6+ planning signals.

---

## Requirements

*From origin: `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`*

- **R1:** Workspace editors should support clear undo/redo boundaries for document mutations (Q1 completeness).
- **R2:** Undo/redo behavior must preserve validation and changed-signal propagation semantics used by current document wrappers.
- **R6:** New editing ergonomics should prioritize high-frequency field patterns first (locstrings, refs, enum-like selectors).
- **R7:** Mutation consistency checks should include failure-path handling and user-visible error context.
- **R5, R8:** Gap-analysis-to-implementation handoff must remain explicit and discoverable; each expansion slice must be small enough to plan independently.

Acceptance Examples:
- **AE1:** Given a DLG struct field edit, undo/redo returns all changed indicators and validation state to expected prior/next values.
- **AE4:** Given high-frequency editing of locstring or reference fields, new editor ergonomics complete edits with fewer manual operations while preserving data constraints.
- **AE3:** Given a contributor selecting a Q6+ backlog item, linked docs provide enough scope/acceptance to produce a bounded implementation plan.

---

## Scope Boundaries

### In Scope

- DLG editor lambda-to-named-method refactor enabling undo/redo wiring (Q1 completion).
- Undo/redo boundaries for DLG struct field mutations (Q1 parity with GFF/2DA/TLK).
- Q3 typed helpers: resref validation (16-char limit, whitespace trim), enum/dropdown for Gender/Race/Appearance_Type fields.
- Capability queue documentation refresh marking Q1–Q5 shipped.
- Planning scaffolding for Q6+ waves (gap analysis cross-links, future-wave readiness).

### Out of Scope (Deferred to Follow-Up Work)

- **DLG struct/array tree editing** (reply list, entry/link mutation UI) — distinct v2 effort, requires new tree populator.
- **GFF array add/remove** (appending new instances to multi-record arrays) — architectural work on array edit surfaces, deferred to v2.
- **Resref picker UI** (file browser or dropdown from gamefs inventory) — UI surface design work beyond validation, deferred.
- **Payment/billing workflows** — N/A (not applicable to this product).
- **Complete gap inventory closure** — Phase 2 targets only the deferred Q1 item + Q3 enhancements. Remaining gap items (particle emitters, material editors, module file type support) route to Q6+ planning.

---

## Key Technical Decisions

1. **DLG refactor scope:** Convert only the signal-connected mutations (text edits, checkbox, spinbox) to named handlers. The underlying `set_struct_field()` and `set_struct_locstring_text()` mutations remain in `KotorDLGDocument` — no changes to document layer (only editor wiring).

2. **Undo/redo pattern:** Mirror GFF editor's proven pattern: `_apply_*_edit()` (validation + undo setup) calls `_exec_*_edit()` (committed mutation). Both DLG and GFF use `EditorInterface.get_editor_undo_redo()` (Godot 4.3+, safe in editor mode only).

3. **Typed helpers approach:** Implement field-specific validation and UI hints in tree populator logic (following GFF bool checkbox precedent). Start with resref validation in `GFFTreePopulator._configure_scalar_leaf()` and Gender/Race enum routing.

4. **Enum dropdown design:** For enum-like fields (Gender, Race, Appearance_Type with known values in 2DA lookup), configure `TreeItem.CELL_MODE_CUSTOM` with ComboBox-style hint rather than free-text edit. Mapping lives in a small `EnumFieldHints` helper that scans field names.

5. **Documentation sequence:** Update capability queue **before** planning Q6+. This ensures clean handoff: contributors see Q1–Q5 marked shipped, Q6+ items visible but explicitly deferred, new waves linked cleanly.

---

## Implementation Units

### U1. Refactor DLG editor mutations from lambdas to named handlers

**Goal:** Enable undo/redo wiring for DLG struct field mutations by breaking lambda-capture coupling and introducing `_apply_*_edit()` entry points.

**Requirements:** R1, R2, R7. Covers AE1 (DLG undo/redo behavior).

**Dependencies:** None (standalone refactor).

**Files:**
- `ui/workspace/editors/dlg_workspace_editor.gd` — refactor signal handlers, add named methods, introduce `_get_undo_redo()`
- `tests/editor/test_dlg_workspace_editor.gd` — extend with undo/redo scenario tests

**Approach:**

1. Identify all lambda-captured mutations in `_on_detail_edit_scalar_field()` and `_on_detail_edit_locstring_field()` (lines 627–696).
   - TextEdit `focus_exited` and `text_submitted`
   - LineEdit `text_submitted` and `focus_exited`
   - CheckBox `toggled`
   - SpinBox `value_changed`

2. Extract each signal connection into a named handler: `_apply_string_edit()`, `_apply_int_edit()`, `_apply_bool_edit()`, `_apply_locstring_edit()`.

3. Each apply method:
   - Validates new value via `coerce_scalar_edit_text()` or equivalent
   - Calls `_exec_*_edit()` with old + new values
   - `_exec_*_edit()` either records undo/redo action or direct mutation (based on `_get_undo_redo()` return)

4. Add `_get_undo_redo()` helper returning `EditorInterface.get_editor_undo_redo()` only in editor mode (guards against headless validation).

5. Update `_on_detail_item_edited()` to route bool checkbox toggles (like GFF editor did in Q3).

6. Remove all lambda-based signal connections in `_on_detail_edit_*` methods.

**Patterns to follow:**
- GFF editor's `_apply_tree_field_edit()` + `_exec_tree_field_edit()` (lines 536–579 in gff_workspace_editor.gd)
- Undo/redo action creation: `create_action() → add_do_method(_exec_*) → add_undo_method(_exec_*) → commit_action()`
- Guard with `Engine.is_editor_hint()` in `_exec_*` when calling `_document.changed` side effects

**Test scenarios:**

- **Happy path:** User edits string field, presses Tab → new value applied + marked dirty. Undo restores old value + clears dirty state. Redo reapplies new value.
- **Bool checkbox toggle:** User clicks bool field checkbox → state flips, dirty set, undo/redo available.
- **Int spinbox increment:** User increments spinbox → int coerced, mutation recorded, undo/redo available.
- **Locstring text edit:** User edits entry Text field → locstring mutation applies, language ID preserved, undo available.
- **Validation failure:** User enters invalid int in spinbox → coercion returns current value, no mutation, no undo action recorded.
- **Stale document state:** Document is closed or null during edit → mutation handler returns gracefully without mutation or undo recording.

**Verification:**
- All lambdas in detail edit paths converted to named handlers.
- `_get_undo_redo()` returns non-null only in editor mode (guarded by `Engine.is_editor_hint()`).
- Undo/redo action names follow `"Edit DLG <field_type>"` convention.
- Detail pane refresh happens after both do and undo operations (via `_on_document_changed()` signal).
- No changes to `KotorDLGDocument` mutation methods themselves.

---

### U2. Wire undo/redo boundaries for DLG editor (parity with GFF/2DA/TLK)

**Goal:** Integrate DLG editor's refactored handlers into the workspace controller's undo/redo system and verify state consistency.

**Requirements:** R1, R2 (parity).

**Dependencies:** U1 (must complete first).

**Files:**
- `ui/workspace/editors/dlg_workspace_editor.gd` — confirm `_get_undo_redo()` is wired
- `ui/workspace/kotor_workspace_shell.gd` — no changes needed (DLG editor is already registered as a document editor)
- `tests/editor/test_dlg_workspace_editor.gd` — add full undo/redo scenario tests

**Approach:**

1. Confirm DLG editor is wired into workspace shell as a document editor (already done in Q1 work).
2. Verify `_exec_*_edit()` methods emit `_document.changed` signal so workspace controller's dirty tracking stays in sync.
3. Test undo/redo sequences: edit → undo → redo, and multi-step undo (edit A, edit B, undo, undo, redo, redo).
4. Verify validation state resets on undo (validation report updates via `_on_document_changed()`).

**Patterns to follow:**
- Existing GFF/2DA/TLK undo/redo integration (workspace shell already calls `_get_undo_redo()` via controller's `EditorUndoRedoManager` tracking).
- Document's `changed` signal propagation: mutation → `_notify_changed()` → controller's `update_document_dirty_state()`.

**Test scenarios:**

- **Undo sequence:** Edit entry A text → edit entry B bool → undo (B restores) → undo (A restores) → redo (A reapplies) → validation state matches.
- **Changed signal:** Each mutation emits `changed` signal, triggering controller's dirty state update and detail pane refresh.
- **Stale state during undo:** If document is replaced during undo sequence, next undo action fails gracefully with no mutation.
- **Multi-entry edits:** Edit multiple entry structs in sequence, undo all, state fully restored with no orphaned changes.

**Verification:**
- All undo/redo actions execute without errors.
- `changed` signal fires for each mutation (do and undo).
- Validation report updates correctly after undo.
- No data corruption or orphaned state after undo/redo sequences.

---

### U3. Implement Q3 typed helpers: resref validation and enum dropdowns

**Goal:** Reduce manual errors in high-frequency structured fields (resrefs, enums) by adding field-specific validation and UI hints to both GFF and DLG editors.

**Requirements:** R6 (high-frequency field patterns), R7 (failure-path handling).

**Dependencies:** U1 (applies validation in context of DLG refactor), but can proceed in parallel with U2.

**Files:**
- `ui/workspace/gff_tree_populator.gd` — add resref validation + enum dropdown logic to `_configure_scalar_leaf()`
- `resources/documents/kotor_gff_document.gd` — add resref validation method (shared with DLG)
- `resources/documents/kotor_dlg_document.gd` — add enum validation method for struct fields
- `ui/workspace/typed_field_helpers.gd` (new) — shared enum-to-value, resref-to-field mapping utilities
- `tests/editor/test_typed_field_helpers.gd` (new) — unit tests for validation and enum mapping

**Approach:**

1. **Resref validation in GFFTreePopulator:**
   - When configuring a scalar leaf with resref-type name pattern (contains "Ref" + string type), add 16-char max-length hint.
   - Call document's `validate_resref(text)` method which trims whitespace and checks length.
   - If invalid, set leaf text to previous value + validation error comment.

2. **Enum dropdowns for known enum fields:**
   - Create `EnumFieldHints` helper mapping field names (e.g., `Gender`, `Race`, `Appearance_Type`) to enum values.
   - In `_configure_scalar_leaf()`, detect enum field and set `CELL_MODE_CUSTOM` with ComboBox metadata.
   - Populate dropdown options from enum hints (e.g., Gender: 0=Male, 1=Female, 2=Other).

3. **Shared resref validation in documents:**
   - Add `validate_resref(text: String) -> String` method returning trimmed + validated text or current value if invalid.
   - Reuse in both GFF + DLG editors' `_apply_resref_edit()` handlers.

4. **DLG struct field enum handling:**
   - For DLG entries (Reply/Entry records), check field names against enum hints during `_apply_int_edit()`.
   - Render as dropdown instead of free-text int spinbox for known enums (Gender, Race).

**Patterns to follow:**
- GFF tree populator's bool checkbox configuration (Q3, lines 38–45) — use `CELL_MODE_CUSTOM` for dropdowns similarly.
- Document validation methods for type-specific rules (GFFDocument's `coerce_scalar_edit_text()` model).

**Technical Design:**

```
EnumFieldHints (new utility):
  - FIELD_TO_ENUM_MAP: Dict[String, Array[String]] mapping "Gender" -> ["Male", "Female", "Other"]
  - get_enum_values(field_name: String) -> Array[String] | []
  - is_enum_field(field_name: String) -> bool

GFFTreePopulator._configure_scalar_leaf():
  - If is_resref_field(field_name):
      item.set_cell_mode(col, TreeItem.CELL_MODE_STRING)
      item.add_text_character_limit(16)
  - If is_enum_field(field_name):
      item.set_cell_mode(col, TreeItem.CELL_MODE_CUSTOM)
      item.set_custom_draw_callback(enum_dropdown_renderer)

KotorGFFDocument.validate_resref(text):
  - Return text.strip_edges() if len <= 16 else _current_resref_value
```

**Test scenarios:**

- **Resref max-length:** User types resref with 20+ chars → validation rejects excess, field reverts to previous. Undo/redo respects reversion.
- **Resref whitespace:** User enters resref with leading/trailing spaces → validation trims and applies trimmed value.
- **Enum dropdown:** User clicks Gender field → dropdown shows "Male", "Female", "Other" options. Selecting option applies int value (0, 1, 2) to field.
- **Enum invalid value:** Struct has enum field with out-of-range int (e.g., Gender = 99) → dropdown disabled/grayed, validation warning shown.
- **Resref field name detection:** Fields matching `*Ref` pattern (e.g., `HeadRef`, `BodyRef`) get max-length validation. Non-matching strings do not.
- **DLG enum field:** DLG Entry struct with Gender field → dropdown rendered in detail edit panel, selection applies mutation via `_apply_int_edit()`.

**Verification:**
- Resref fields enforce 16-char limit without data loss (truncation not allowed).
- Enum dropdown renders correctly for known enum fields.
- Unknown enum fields fall back to spinbox/text edit.
- Validation errors do not corrupt document state.
- Undo/redo preserves both resref trimming and enum selection.

---

### U4. Update capability queue documentation to mark Q1–Q5 as shipped

**Goal:** Refresh execution documentation to reflect Q1–Q5 completion and surface Q6+ planning signals for contributors.

**Requirements:** R5 (handoff discoverability), R8 (scope clarity for follow-up slices).

**Dependencies:** None (documentation task).

**Files:**
- `docs/50-execution/godot-capability-execution-queue.md` — update queue table, add shipped section, link Q6+ planning
- `docs/30-gap-analysis/godot-support-gaps.md` — add cross-link to capacity queue, mark Q1–Q5 item groups as "shipped"
- `STRATEGY.md` — add Phase 2 work as active track, update "Completed" section

**Approach:**

1. **Capability queue refresh:**
   - Move Q1–Q5 to new `## Shipped Slices` section with outcome summary.
   - Add Q6–Q8 skeleton items (DLG undo/redo completion, struct/array editing, resref picker UI) with "Deferred" status.
   - Link to this plan from the shipped Q1 item.

2. **Gap analysis cross-link:**
   - Add "Execution Status" column mapping gap items to queue position or "Deferred" label.
   - Link queue document from gap analysis.

3. **STRATEGY.md update:**
   - Add "Phase 2 Capability Expansion" track with status "Active".
   - Update "Completed Tracks" with Q1–Q5 summary.

**Patterns to follow:**
- Queue template (existing rows for Q1–Q5 serve as model).
- Markdown table format (existing).

**Test expectation:** None — documentation task. Verification is by manual review.

**Verification:**
- Q1–Q5 clearly marked as shipped with brief outcome descriptions.
- Q6+ items visible but not yet planned (no detailed acceptance examples).
- All links are valid (docs exist at stated paths).
- No broken markdown or missing sections.

---

### U5. Create Q6+ planning scaffolding and contributor handoff

**Goal:** Establish clear entry points for Phase 2 follow-up work and future capability waves so contributors can select and plan next slices independently.

**Requirements:** R5, R8 (handoff discoverability and scope clarity).

**Dependencies:** U4 (queue documentation must be updated first).

**Files:**
- `docs/50-execution/godot-capability-execution-queue.md` — Q6–Q8 skeleton with readiness criteria
- `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md` — add cross-link to Q6+ queue section
- `STRATEGY.md` — add "Next Waves" subsection with capability families and priority signals
- `README.md` — update contributor entry point to reference queue + gap analysis + strategy (verify links work)

**Approach:**

1. **Q6–Q8 skeleton in execution queue:**
   - Q6: "DLG undo/redo completion" (struct/array editing UI) — depends on U1, lower priority than DLG undo wiring.
   - Q7: "GFF struct/array editing" (locstring tree, array add/remove) — cross-cutting enhancement.
   - Q8: "Typed field picker UIs" (resref file browser, enum combo from gamefs) — UI surface design.

2. **Readiness criteria for Q6+:**
   - Q6: DLG undo/redo wired (U1–U2 complete), struct editing surface design sketched.
   - Q7: GFF tree populator patterns validated (bool checkboxes + enums from U3 working).
   - Q8: Gap analysis inventory finalized, resref picker scope defined.

3. **STRATEGY.md "Next Waves" section:**
   - List three capability families: "Editor Ergonomics", "Data Mutation Safety", "Workspace Integration".
   - Map Q6–Q8 items to families.
   - Note dependencies (Q6 depends on U1 complete).

4. **README contributor link update:**
   - Verify README links to STRATEGY, gap analysis, execution queue, and plan repo.
   - Add inline note: "For next-wave planning, see the execution queue's Q6–Q8 section."

**Patterns to follow:**
- Existing requirements doc structure (brainstorms) as reference.
- Existing queue table format.

**Test expectation:** None — documentation/planning scaffolding task.

**Verification:**
- Q6–Q8 items are clearly deferred (not planned for immediate implementation).
- Each has stated readiness criteria (blockers, design sketches needed).
- All links from README → STRATEGY → queue → gap analysis → plans are valid and discoverable.
- Contributor reading README can identify next-wave planning entry point.

---

## System-Wide Impact

| Surface | Impact | Mitigation |
|---|---|---|
| **DLG Editor UI** | Signal wiring changes; user undo/redo now works like GFF/2DA/TLK. No behavioral change except undo/redo availability. | Test undo sequences in detail panel. |
| **Validation flow** | Resref + enum validation adds field-specific error reporting. Validation state updates on undo. | Test validation state after undo; confirm errors don't block mutations. |
| **Workspace controller** | DLG editor's changed signal now properly integrated into dirty state tracking (already done in Q1). | Existing dirty state tests cover this. |
| **Contributor documentation** | Q1–Q5 marked shipped, Q6+ visible but deferred. Reduces "what's next" ambiguity. | Manual review of queue + README links. |

---

## Risk Analysis & Mitigation

| Risk | Signal | Mitigation |
|---|---|---|
| **Lambda refactor introduces state desync** | DLG mutations bypass undo/redo during refactor. | Test undo scenarios before shipping. Pair unit tests with integration tests. |
| **Enum dropdown rendering incomplete** | Wrong field names matched or enum options missing. | Validate EnumFieldHints against actual game data (Gender/Race 2DA). Test rendering in detail panel. |
| **Resref validation blocks valid inputs** | 16-char rule too strict or special chars excluded. | Test against corpus of real resrefs (check existing game files). Whitespace-only trimming, no char exclusion. |
| **Documentation links rot** | Q6+ items reference nonexistent docs. | Verify all links at plan-write time. Add lint check for link validity (future work). |

---

## Deferred to Follow-Up Work

- **DLG struct/array mutation UI** (reply list, entry/link editing) — separate v2 effort after U1–U2 undo/redo foundation.
- **GFF array add/remove** (appending new struct instances) — architectural work on array edit surfaces, deferred to v2.
- **Resref file picker UI** (browser or dropdown from gamefs inventory) — distinct UI design work, separate plan.
- **Advanced enum validation** (enum values from 2DA lookup, live fallback if 2DA unavailable) — later enhancement.
- **Full gap inventory closure** — Q6+ planning surfaces remaining items; Phase 2 targets only deferred Q1 + Q3 enhancements.

---

## Success Criteria

- ✅ DLG editor mutations wired to undo/redo with full parity to GFF/2DA/TLK.
- ✅ Resref fields enforce 16-char max-length without data loss.
- ✅ Gender/Race/Appearance_Type fields render as enum dropdowns in both GFF and DLG editors.
- ✅ Capability queue documents Q1–Q5 as shipped, Q6–Q8 sketched with readiness criteria.
- ✅ Contributors can identify next-wave work by reading README → STRATEGY → queue → gap analysis flow.
- ✅ All 110+ GDScript files pass `godot --headless --check-only` validation.
- ✅ Existing tests pass; new tests cover undo/redo and validation scenarios.

---

## Assumptions

- `EnumFieldHints` mapping for Gender/Race/Appearance_Type matches game data exactly (verified against game 2DA files before shipping).
- DLG editor's document layer (`KotorDLGDocument`) mutation methods remain stable; no changes to their signatures or behavior.
- Contributors will use updated queue + gap analysis + strategy docs as primary navigation for Q6+ planning (no additional scaffolding needed).

