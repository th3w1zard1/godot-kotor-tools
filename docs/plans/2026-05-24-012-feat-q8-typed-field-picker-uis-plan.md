---
title: Q8 Typed Field Picker UIs
type: feat
status: completed
date: 2026-05-24
origin: docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md
phase: Q8
track: Phase 2 Capability Expansion
---

# Q8: Typed Field Picker UIs

## Summary

Add install-aware picker UX on top of Q3 validation helpers and Q6/Q7 struct/array editing surfaces. Q8 delivers a reusable ResRef browser dialog backed by `KotorGameFS`, enum combo controls for known schema fields, and enhanced locstring/strref editing — all wired through existing `_apply_*` / `_exec_*` undo/redo boundaries in GFF and DLG workspace editors. Workspace-embedded pickers are preferred over a new `EditorInspectorPlugin` layer to stay consistent with shipped editor patterns.

---

## Problem Frame

Q3 introduced ResRef validation and static enum hints; Q6/Q7 added struct/array mutation with text-only ResRef and SpinBox enum entry. Modders still manually type resource names and integer enum values, which is error-prone against a 16-character ResRef limit and opaque enum mappings. The resource browser panel already proves install-aware browsing works — Q8 extracts that into field-level pickers without breaking mutation safety or hybrid validation from Q6/Q7.

---

## Assumptions

*This plan was authored in headless pipeline mode. Items below are agent inferences that downstream review should validate.*

- Static enum mapping in `TypedFieldHelpers.ENUM_FIELD_MAPPING` is sufficient for v1 combo UX; dynamic 2DA-backed enum loading is deferred to a follow-up slice.
- ResRef picker v1 filters by optional resource type hint (e.g., `nss`, `ncs`, `wav`) but does not require existence validation before apply — existence hints are advisory only.
- Multi-language locstring editing in Q8 covers language ID selection plus TLK strref browse; full strref authoring workflow remains text-first with browse assist.

---

## Requirements

From `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md` and execution queue Q8 definition:

- **R1.** High-frequency ResRef fields support install-aware browse/select without leaving the workspace editor.
- **R2.** Known enum-like integer fields render as guided combo controls while preserving validation and undo/redo semantics.
- **R3.** Locstring fields gain strref resolution/browse assist building on existing TLK lookup.
- **R4.** Picker commits route through existing document mutation + undo/redo boundaries (no direct UI-to-data writes).
- **R5.** Picker lists refresh when gamefs reindexes (no stale install state after target switch).
- **R6.** Execution documentation reflects Q6/Q7 shipped status and Q8 scope.

**Origin actors:** A1 Modder, A2 Contributor, A3 GFF/DLG workspace editor  
**Origin flows:** F1 ResRef pick → apply → undo; F2 Enum combo select → apply → undo; F3 Locstring strref browse → apply  
**Origin acceptance examples:** AE4 (fewer manual operations for locstring/ref fields); AE1 (undo/redo restores picker-applied values)

---

## Scope Boundaries

- ResRef picker dialog with search, type filter, and selection callback
- GFF tree + inline struct ResRef browse buttons for `is_resref` metadata fields
- DLG form ResRef browse buttons for Script, Sound, VO_ResRef, and `*Ref` string fields
- Enum `OptionButton` for fields in `TypedFieldHelpers.ENUM_FIELD_MAPPING` (GFF tree + DLG form)
- Locstring strref browse + language ID selector (ID 0 default, additional IDs selectable)
- Headless tests for picker helper logic and editor integration via public apply methods
- Execution queue + gap analysis status refresh for Q6/Q7 shipped

### Deferred to Follow-Up Work

- **Dynamic enum registry from 2DA/gamefs** — load Gender/Race/etc. from live 2DA tables instead of static map
- **Inventory/item pickers** (`EquippedInventory`, `Inventory`) — requires UTC/UTI-specific filtering UX
- **ResRef autocomplete/typeahead** — browse-first v1; inline autocomplete is a separate enhancement
- **EditorInspectorPlugin property editors** — gap analysis direction; out of scope unless workspace pickers prove insufficient
- **Cross-file dialogue link picker** — enhanced DLG EntriesList target selection beyond text/index entry
- **Full multi-language locstring authoring** — translation workflow, not just ID selection + strref browse

---

## Context & Research

### Relevant Code and Patterns

- `ui/workspace/typed_field_helpers.gd` — ResRef detection/validation, static enum map, Q6/Q7 hybrid validation helpers
- `ui/workspace/gff_tree_populator.gd` — sets `is_resref` and `enum_field_name` metadata (currently unused by editors)
- `ui/workspace/editors/gff_workspace_editor.gd` — `_apply_tree_field_edit` / `_exec_tree_field_edit` undo pattern
- `ui/workspace/editors/dlg_workspace_editor.gd` — form widgets, `_apply_string_edit`, `_apply_int_edit`, `_dlg_resolved_locstring_text`
- `ui/workspace/panels/resource_browser_panel.gd` — search + tree browse via `KotorTargetContext.list_resources`
- `gamefs/kotor_gamefs.gd` — `list_core_resources(query, resource_type, source, limit)`, `resolve_resource`
- `editor/workspace/kotor_target_context.gd` — thin browse API for UI panels

### Institutional Learnings

- `docs/solutions/parity-foundation.md` — pickers must plug into workspace editors, not legacy dock routes
- `docs/solutions/safe-transaction-layer.md` — picker-driven opens/installs still use mutation service + preflight when writing
- Q6/Q7 plans explicitly deferred picker UI to Q8; text-first baseline must remain as fallback

### External References

- None required — local resource browser and typed helper patterns are sufficient for v1

---

## Key Technical Decisions

1. **Workspace widget pickers over EditorInspectorPlugin:** Reuse editor form rows and tree adjunct buttons. Matches Q6/Q7 UX and avoids a parallel inspector registration surface.

2. **Extract browse core from resource browser:** New `KotorResRefPickerDialog` wraps search/list/select without install/compare/export actions. Accepts optional `resource_type` filter and initial query from field context.

3. **Picker commit = one undo action:** Capture old value before opening dialog; on accept, call existing `_apply_*_edit(old, new)` — never mutate document inside dialog callbacks directly.

4. **Enum v1 uses static map:** `OptionButton` populated from `TypedFieldHelpers.get_enum_options_as_array()`. Dynamic 2DA sourcing deferred — document explicitly in queue follow-up.

5. **ResRef type hints by field name:** Extend `TypedFieldHelpers` with optional `get_resref_type_hint(field_name) -> String` mapping (e.g., `Script` → `nss`/`ncs`, `Sound`/`VO_ResRef` → `wav`). Unknown fields browse all types.

6. **Stale list mitigation:** Picker dialog queries gamefs on open; editors pass fresh `KotorTargetContext` from `editor_state`. Re-open refreshes — no long-lived cached picker singleton.

---

## Open Questions

### Resolved During Planning

- **Inspector vs workspace pickers?** Workspace widgets — consistent with shipped editors.
- **Enum from gamefs in v1?** No — static map + combo UX closes the Q3 design gap; dynamic registry is follow-up.

### Deferred to Implementation

- Exact field→type hint table coverage for all GFF/DLG ResRef fields — start with high-frequency fields from Q7 schema design doc, expand as tests reveal gaps.
- Whether GFF tree enum combo uses inline `OptionButton` row vs. popup on edit — implementer chooses least invasive tree UX that preserves `item_edited` flow.

---

## High-Level Technical Design

> *This illustrates the intended approach and is directional guidance for review, not implementation specification. The implementing agent should treat it as context, not code to reproduce.*

```
User focuses ResRef field (GFF tree meta is_resref OR DLG LineEdit)
  → Browse button opens KotorResRefPickerDialog
  → Dialog: search → list_core_resources(query, type_hint) → user selects entry
  → Returns resref string (16-char validated)
  → Editor: _apply_string_edit(path, old_resref, new_resref)
  → _exec_* records undo/redo, document.validate_resref, mark_changed

User focuses enum field (meta enum_field_name OR DLG int field with hints)
  → OptionButton shows "0: Male", "1: Female", ...
  → Selection → _apply_int_edit(path, old_int, new_int)
  → validate_enum_value warns if out of range; undo/redo preserved

Locstring field
  → Language ID OptionButton (0, 1, ... supported IDs)
  → StrRef browse opens picker filtered to TLK-visible strrefs OR manual strref entry
  → _apply_locstring_edit with language_id + text/strref
```

---

## Implementation Units

- U1. **ResRef picker dialog and browse helpers**

**Goal:** Reusable install-aware ResRef selection dialog extracted from resource browser patterns.

**Requirements:** R1, R5

**Dependencies:** None

**Files:**
- Create: `ui/workspace/dialogs/kotor_resref_picker_dialog.gd`
- Modify: `ui/workspace/typed_field_helpers.gd` — add `get_resref_type_hint(field_name)`
- Test: `tests/editor/test_resref_picker.gd`

**Approach:**
- Subclass or compose `AcceptDialog` with search `LineEdit`, filtered `Tree`, status label
- Accept `target_context`, optional `resource_type_filter`, optional `initial_query`
- On confirm, emit selected `resref` string (from entry dictionary)
- Helper: `TypedFieldHelpers.normalize_picker_selection(entry) -> String` trims to valid ResRef

**Patterns to follow:**
- `ui/workspace/panels/resource_browser_panel.gd` search/tree layout
- `KotorResourceLocator` for entry display labels

**Test scenarios:**
- Happy path: indexed install → search "dan" → select entry → returns resref ≤ 16 chars
- Edge case: empty index → dialog shows status error, confirm disabled
- Edge case: type filter `"nss"` excludes non-script resources from results
- Error path: selection with resref > 16 chars → normalized/truncated per validate_resref rules

**Verification:**
- Dialog returns resref on accept, empty on cancel
- Headless test passes with temp override install fixture

---

- U2. **Enum combo widget integration**

**Goal:** Replace SpinBox/free-text enum editing with `OptionButton` for known enum fields in DLG form and GFF contexts.

**Requirements:** R2, R4

**Dependencies:** None (parallel with U1)

**Files:**
- Create: `ui/workspace/widgets/enum_field_row.gd` (optional shared row: label + OptionButton)
- Modify: `ui/workspace/editors/dlg_workspace_editor.gd` — enum fields use OptionButton
- Modify: `ui/workspace/editors/gff_workspace_editor.gd` — honor `enum_field_name` meta for struct inline edits
- Test: `tests/editor/test_enum_field_picker.gd`

**Approach:**
- Build OptionButton items from `TypedFieldHelpers.get_enum_options_as_array(field_name)`
- On item selected, call `_apply_int_edit` with parsed int key
- Preserve SpinBox fallback for unknown int fields
- Invalid stored values: show current value + warning label (Q6/Q7 hybrid validation)

**Patterns to follow:**
- DLG `_apply_int_edit` / `_exec_int_edit` undo pattern
- GFF struct inline field editor paths from Q7

**Test scenarios:**
- Happy path: Gender field → select "1: Female" → document int = 1, undo restores prior
- Edge case: out-of-range stored value → combo shows warning, selection still applies valid option
- Integration: enum edit in GFF struct array member preserves array path and hybrid validation

**Verification:**
- Known enum fields no longer use SpinBox in DLG detail panel
- Undo/redo round-trip for enum selection

---

- U3. **Wire ResRef picker to GFF editor**

**Goal:** Attach browse affordance to GFF tree ResRef fields and inline struct ResRef edits.

**Requirements:** R1, R4, AE4

**Dependencies:** U1

**Files:**
- Modify: `ui/workspace/editors/gff_workspace_editor.gd`
- Modify: `ui/workspace/gff_tree_populator.gd` — ensure `is_resref` meta on all ResRef leaves
- Test: extend `tests/editor/test_gff_workspace_editor.gd`

**Approach:**
- For tree items with `is_resref` meta: add context menu "Browse ResRef…" or adjacent browse action on struct inline rows
- Open picker with `get_resref_type_hint(field_name)` filter
- On accept: `_apply_tree_field_edit` / struct inline `_apply_string_edit` with old/new values
- Text entry remains available as fallback

**Patterns to follow:**
- GFF `_apply_tree_field_edit` + `_exec_tree_field_edit`
- Q7 struct inline `_apply_*_edit` handlers

**Test scenarios:**
- Happy path: picker selection updates UTC Script field, save/reload round-trip
- Covers AE4: ResRef edit completes with browse + apply in fewer manual steps than typed entry
- Edge case: cancel picker → no mutation, no undo action
- Integration: picker apply after array struct insert preserves path correctness

**Verification:**
- GFF ResRef fields open picker and commit through undo/redo
- Existing scalar/array tests still pass

---

- U4. **Wire ResRef picker and locstring assist to DLG editor**

**Goal:** Add browse buttons for DLG ResRef string fields and strref/language assist for locstring fields.

**Requirements:** R1, R3, R4

**Dependencies:** U1, U2

**Files:**
- Modify: `ui/workspace/editors/dlg_workspace_editor.gd`
- Test: extend `tests/editor/test_dlg_workspace_editor.gd`

**Approach:**
- ResRef LineEdit rows: add "Browse…" button → picker → `_apply_string_edit`
- Locstring rows: language ID OptionButton (0–5 or configurable small set); "Browse StrRef" uses TLK strref listing or picker with dialog.tlk context
- Promote read-only `_dlg_resolved_locstring_text` label to interactive browse where strref ≥ 0
- Preserve Q6 hybrid validation on linked fields

**Patterns to follow:**
- Existing locstring `_apply_locstring_edit` undo path
- DLG `_build_dlg_struct_editor` widget factory

**Test scenarios:**
- Happy path: Script field browse → select nss resref → validation passes, undo restores
- Happy path: locstring strref browse updates reference, TLK resolution label refreshes
- Edge case: browse with no indexed gamefs → user-visible error, no mutation
- Covers AE1: undo/redo after picker apply restores prior ResRef and locstring state

**Verification:**
- DLG Script/Sound/VO_ResRef fields have working browse
- Locstring language ID + strref assist functional for ID 0 baseline

---

- U5. **Execution documentation refresh**

**Goal:** Mark Q6/Q7 shipped, document Q8 in progress, update stale deferral language.

**Requirements:** R6

**Dependencies:** U1–U4 implementation complete (update on ship)

**Files:**
- Modify: `docs/50-execution/godot-capability-execution-queue.md`
- Modify: `docs/30-gap-analysis/godot-support-gaps.md`
- Modify: `STRATEGY.md` — Q6/Q7 to completed, Q8 active
- Modify: `docs/solutions/parity-foundation.md` — remove stale "array editing deferred" language

**Approach:**
- Move Q6/Q7 to Shipped Slices with outcome summaries
- Set Q8 status to active/in-progress during implementation, shipped on completion
- Add Q9 skeleton for dynamic enum registry + inventory pickers if needed

**Test expectation:** none — documentation verification by link review

**Verification:**
- Queue reflects actual shipped state
- README/STRATEGY/queue links remain valid

---

## System-Wide Impact

- **Interaction graph:** Pickers read from `KotorTargetContext` / `gamefs`; writes still go through document + mutation service. Resource browser panel unchanged.
- **Error propagation:** Picker cancel = no-op. Missing index = dialog-level error. Validation errors surface in existing validation panels after apply.
- **State lifecycle risks:** Picker must not hold stale `target_context` across install switch — always resolve from `editor_state` at open time.
- **API surface parity:** GFF tree, GFF struct inline, and DLG form paths all use same picker dialog and enum row widget.
- **Integration coverage:** Headless tests cover apply paths; manual editor verification for dialog UX.
- **Unchanged invariants:** Direct text entry remains for all fields; pickers are additive. Q6/Q7 array mutations and hybrid validation unchanged.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Tree + browse button UX clunky in GFF | Start with context menu "Browse ResRef"; iterate to inline button if needed |
| `list_core_resources` 256 limit truncates results | Search-required model; type filter narrows set; document limit in picker status |
| Enum combo breaks free-form int entry for modded values | Keep manual entry fallback or "Custom value" option showing SpinBox |
| Locstring multi-language scope creep | Cap v1 to ID selector + strref browse; defer translation workflow |
| Docs drift (queue still shows Q6/Q7 deferred) | U5 explicitly refreshes on ship |

---

## Sources & References

- **Origin document:** `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
- **Execution queue:** `docs/50-execution/godot-capability-execution-queue.md`
- **Q7 deferrals:** `docs/designs/2026-05-24-011-q7-gff-struct-array-schema.md`
- **Q6 requirements:** `docs/brainstorms/2026-05-24-010-q6-dlg-struct-array-editing-requirements.md`
- **Gap analysis:** `docs/30-gap-analysis/godot-support-gaps.md`
- Related code: `ui/workspace/panels/resource_browser_panel.gd`, `ui/workspace/typed_field_helpers.gd`
