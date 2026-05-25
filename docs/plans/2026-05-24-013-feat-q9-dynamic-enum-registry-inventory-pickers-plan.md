---
title: Q9 Dynamic Enum Registry and Inventory Pickers
type: feat
status: completed
date: 2026-05-24
origin: docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md
phase: Q9
track: Phase 2 Capability Expansion
---

# Q9: Dynamic Enum Registry and Inventory Pickers

## Summary

Replace Q8's static enum labels with an install-aware enum registry backed by 2DA tables loaded through `KotorGameFS`, while keeping the static map as a headless/offline fallback. Add a UTI-filtered item picker dialog and wire it into GFF inventory struct fields (`InventoryRes`, template resrefs inside `itemList` / inventory arrays) using the same undo-safe apply pattern as Q8 ResRef pickers. Mark Q8 shipped and advance the execution queue when this slice lands.

---

## Problem Frame

Q8 delivered ResRef browse and static enum combos, but Gender/Race/Appearance labels are hardcoded and can diverge from the active game install (K1 vs TSL, modded 2DA overrides). Inventory editing still requires typing UTI resrefs manually because Q7 deferred `EquippedInventory`, `Inventory`, and rich `itemList` UX until picker infrastructure existed. Q9 closes both gaps without breaking hybrid validation, custom out-of-range enum values, or undo/redo semantics.

---

## Assumptions

*Headless pipeline mode — validate during implementation against a real install when available.*

- Standard KotOR 2DA resrefs for enum tables: `gender`, `racialtypes`, `appearance` (verify column names at implementation time; use `label` or `string` column when present).
- Row index in GFF enum fields maps to 2DA row order (same convention as static map).
- Inventory struct fields use a ResRef member named `InventoryRes` or `ResRef` inside item structs; v1 enables picker on those scalar fields inside editable arrays, not full array schema expansion for `EquippedInventory`/`Inventory` top-level arrays yet.
- Static `ENUM_FIELD_MAPPING` remains the fallback when gamefs is unavailable or 2DA load fails.

---

## Requirements

- **R1.** Enum option labels for known fields resolve from install 2DA when indexed, with static fallback.
- **R2.** Enum registry cache invalidates on gamefs reindex / target switch (no stale labels after install change).
- **R3.** Out-of-range enum values remain editable; UI shows `Unknown (n)` and does not reject apply solely because a value is absent from 2DA.
- **R4.** Item picker browses UTI resources from gamefs with search and type filter, reusing Q8 dialog patterns.
- **R5.** Item/ResRef picker commits route through existing `_apply_*_edit` undo boundaries.
- **R6.** Headless tests cover registry load, fallback, and item picker normalization without a full editor session.
- **R7.** Execution queue and strategy docs reflect Q8 shipped and Q9 completion.

**Origin actors:** A1 Modder, A2 Contributor, A3 GFF/DLG workspace editor  
**Origin flows:** F1 Enum pick with install-accurate labels; F2 Item template pick → apply → undo  
**Origin acceptance examples:** AE4 (fewer manual operations for ref/enum fields)

---

## Scope Boundaries

- `KotorEnumRegistry` service: field→2DA mapping, load/parse/cache, reindex invalidation
- `TypedFieldHelpers` enum APIs delegate to registry with static fallback
- GFF/DLG enum UI unchanged in shape (OptionButton / context menu) but populated from registry
- `KotorItemPickerDialog` (UTI filter) + GFF context menu integration for inventory-related ResRef fields
- Extend `RESREF_TYPE_HINTS` with `uti` where appropriate; detect inventory struct ResRef fields by name heuristics
- Headless tests + execution queue / STRATEGY refresh

### Deferred to Follow-Up Work

- **Full `EquippedInventory` / `Inventory` array editing** — top-level array mutability + struct defaults (beyond picker on existing editable `itemList` fields)
- **UTI typed resource/document** — display Tag/LocName from parsed UTI bytes in picker columns
- **ResRef autocomplete/typeahead** — separate enhancement
- **Dynamic enum for all GFF fields** — v1 covers mapped high-frequency UTC fields only
- **Cross-file dialogue link picker** — remains separate from inventory work

---

## Context & Research

### Relevant Code and Patterns

- `ui/workspace/typed_field_helpers.gd` — static `ENUM_FIELD_MAPPING`, enum option formatting
- `ui/workspace/dialogs/kotor_resref_picker_dialog.gd` — Q8 browse dialog template
- `ui/workspace/editors/gff_workspace_editor.gd` — field context menu, `_apply_tree_field_edit`
- `ui/workspace/editors/dlg_workspace_editor.gd` — inline enum OptionButton
- `gamefs/kotor_gamefs.gd` — `resolve_resource`, `load_resource_entry_bytes`, reindex signals
- `formats/twoda_parser.gd` — parse bytes to row/column dicts
- `editor/workspace/kotor_target_context.gd` — gamefs wrapper, reindex listener
- `docs/plans/2026-05-24-012-feat-q8-typed-field-picker-uis-plan.md` — explicit Q9 deferrals

### Institutional Learnings

- Workspace-first picker UX; no `EditorInspectorPlugin` (`docs/solutions/parity-foundation.md`)
- Picker commits must use undo-safe apply paths, not direct mutation
- Static enum map already drifts from 2DA intent — registry is corrective, not cosmetic

---

## Key Technical Decisions

- **Registry as RefCounted service on `KotorEditorState`:** Centralizes cache and reindex hooks; editors resolve via `editor_state.enum_registry` (or lazy singleton on gamefs refresh).
- **Field→2DA config as const map in registry file:** Mirrors `RESREF_TYPE_HINTS` pattern; easy to extend without UI changes.
- **Label column resolution:** Prefer `label`, then `string`, then first string column; row index = enum int value.
- **Item picker clones ResRef picker:** Filter `extension = uti`; share `normalize_picker_selection` and dialog layout.
- **Inventory field detection:** `InventoryRes`, fields ending in `Item`, or metadata `is_item_resref` set by populator when inside `itemList` struct context.

---

## Open Questions

### Resolved During Planning

- **Where to load 2DA?** Via `gamefs.resolve_resource(table, "2da")` + `TwoDaParser.parse_bytes` inside registry; no new gamefs API required for v1.
- **Strict validation on dynamic enums?** No — preserve Q8 warn-only behavior for unknown values.

### Deferred to Implementation

- **Exact 2DA column names per table:** Verify against K1/TSL fixture or dev install during U1 spike.
- **Inventory struct field names in the wild:** Confirm from sample UTC/UTP in test fixtures.

---

## High-Level Technical Design

> *Directional guidance for review, not implementation specification.*

```text
editor_state.gamefs ──reindex──► KotorEnumRegistry.clear_cache()
                                      │
field_name ──► FIELD_TO_2DA map ──► load 2DA bytes ──► row[i] → label
                                      │ fail
                                      ▼
                              ENUM_FIELD_MAPPING (static)

GFF field context menu ──► KotorItemPickerDialog (uti filter) ──► _apply_tree_field_edit
```

---

## Implementation Units

- U1. **KotorEnumRegistry service**

**Goal:** Load and cache install-backed enum labels keyed by GFF field name.

**Requirements:** R1, R2, R3

**Dependencies:** None

**Files:**
- Create: `editor/workspace/kotor_enum_registry.gd`
- Modify: `editor/core/kotor_editor_state.gd`
- Test: `tests/editor/test_enum_registry.gd`

**Approach:**
- Define `FIELD_TO_2DA` mapping (`Gender`→`gender`, `Race`→`racialtypes`, `Appearance_Type`→`appearance`).
- `get_enum_values(field_name) -> Dictionary` returns `{ int: label }`; cache per field until reindex.
- `get_enum_source(field_name) -> String` returns `"2da"`, `"static"`, or `"none"`.
- Hook `gamefs_reindexed` on editor state to clear cache.

**Patterns to follow:**
- `KotorTargetContext` gamefs resolve pattern
- Static fallback from `TypedFieldHelpers.ENUM_FIELD_MAPPING`

**Test scenarios:**
- Happy path: fixture 2DA bytes produce expected row count and labels
- Edge case: missing 2DA falls back to static map
- Edge case: empty gamefs returns static map
- Integration: reindex signal clears cached values

**Verification:**
- Registry returns install labels when override 2DA present; static otherwise

---

- U2. **TypedFieldHelpers and editor enum wiring**

**Goal:** Existing enum APIs read from registry without breaking call sites.

**Requirements:** R1, R3

**Dependencies:** U1

**Files:**
- Modify: `ui/workspace/typed_field_helpers.gd`
- Modify: `ui/workspace/editors/gff_workspace_editor.gd`
- Modify: `ui/workspace/editors/dlg_workspace_editor.gd`
- Test: `tests/editor/test_enum_field_picker.gd` (extend)

**Approach:**
- Add optional `registry` parameter or resolve from editor state in editors before calling helpers.
- `get_enum_values` / `get_enum_options_as_array` consult registry first, then static map.
- Preserve `Unknown (n)` display and DLG warn-on-out-of-range behavior.

**Test scenarios:**
- Happy path: options array reflects registry labels
- Edge case: custom value not in registry still round-trips through find/parse helpers

**Verification:**
- Existing enum picker tests pass; options differ when registry mock supplies labels

---

- U3. **KotorItemPickerDialog**

**Goal:** Reusable UTI browse dialog mirroring Q8 ResRef picker.

**Requirements:** R4, R5

**Dependencies:** None (parallel with U1)

**Files:**
- Create: `ui/workspace/dialogs/kotor_item_picker_dialog.gd`
- Modify: `ui/workspace/typed_field_helpers.gd` (add `is_item_resref_field`, `uti` hint)
- Test: `tests/editor/test_item_picker.gd`

**Approach:**
- Clone `KotorResRefPickerDialog` structure; default `resource_type_filter = "uti"`.
- Title "Browse Item Template"; emit `item_selected(resref)`.
- Use `normalize_picker_selection` for 16-char limit.

**Test scenarios:**
- Happy path: dialog configures with uti filter
- Edge case: selection normalizes/respects max length
- Edge case: no gamefs shows status message, empty tree

**Verification:**
- Headless test instantiates dialog with mock gamefs and selects entry

---

- U4. **GFF inventory picker integration**

**Goal:** Context menu opens item picker for inventory-related ResRef fields inside editable structs.

**Requirements:** R4, R5

**Dependencies:** U3

**Files:**
- Modify: `ui/workspace/gff_tree_populator.gd`
- Modify: `ui/workspace/editors/gff_workspace_editor.gd`
- Test: extend `tests/editor/test_gff_workspace_editor.gd` if applicable

**Approach:**
- Set metadata `is_item_resref` on ResRef fields inside `itemList` (and similar) structs.
- Add context menu action "Browse Item…" alongside existing ResRef browse.
- Apply via `_apply_tree_field_edit` with undo.

**Test scenarios:**
- Happy path: apply item resref through public apply API updates document
- Integration: undo restores prior resref

**Verification:**
- GFF editor test or manual check on UTC fixture with itemList field

---

- U5. **Docs, queue, and strategy refresh**

**Goal:** Close Q8 in execution tracking and record Q9 shipped outcome.

**Requirements:** R7

**Dependencies:** U1–U4

**Files:**
- Modify: `docs/50-execution/godot-capability-execution-queue.md`
- Modify: `STRATEGY.md`

**Approach:**
- Move Q8 to Shipped Slices; Q9 to Shipped (or Active until verified).
- Update Phase 2 status line to Q1–Q8 shipped, Q9 in progress/completed.

**Test expectation:** none — documentation only

**Verification:**
- Queue table matches merged capability set

---

## System-Wide Impact

- **Interaction graph:** `KotorEditorState` gains registry reference; gamefs reindex clears enum cache; GFF/DLG editors unchanged in apply flow.
- **Error propagation:** 2DA parse failures log and fall back silently to static map; no user-blocking errors on browse.
- **State lifecycle risks:** Cache must clear on reindex to avoid stale labels after override install.
- **Unchanged invariants:** Undo/redo boundaries, hybrid validation, ResRef picker behavior, DLG struct/array editing.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| 2DA column names differ K1 vs TSL | Verify mapping during U1; prefer flexible label column detection |
| Headless CI lacks game 2DA | Static fallback + fixture bytes in tests |
| Inventory struct naming varies | Name heuristics + metadata from populator |
| Scope creep into full inventory arrays | Defer top-level `Inventory` array editing explicitly |

---

## Sources & References

- **Origin document:** `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
- **Q8 plan deferrals:** `docs/plans/2026-05-24-012-feat-q8-typed-field-picker-uis-plan.md`
- **Q7 inventory deferrals:** `docs/designs/2026-05-24-011-q7-gff-struct-array-schema.md`
- **Execution queue:** `docs/50-execution/godot-capability-execution-queue.md`
