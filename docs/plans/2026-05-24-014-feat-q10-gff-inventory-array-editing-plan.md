---
title: Q10 GFF Inventory Array Editing
type: feat
status: completed
date: 2026-05-24
origin: docs/plans/2026-05-24-013-feat-q9-dynamic-enum-registry-inventory-pickers-plan.md
phase: Q10
track: Phase 2 Capability Expansion
---

# Q10: GFF Inventory Array Editing

## Summary

Enable add/remove/reorder mutations for top-level inventory struct arrays (`Inventory`, `EquippedInventory`) and supply proper default structs for `itemList` entries, building on Q7 array machinery and Q9 UTI item pickers. Modders can author creature/placeable inventories in the GFF tree without manual hex editing.

---

## Problem Frame

Q7 enabled struct-array editing for `CreatureActions`, `Scripts`, and `itemList`, but `itemList` inserts used an empty `{}` default and `Inventory` / `EquippedInventory` were explicitly deferred until picker infrastructure existed. Q9 shipped UTI browse for inventory ResRef fields. Q10 completes inventory authoring: bounded array mutations with sensible defaults, hybrid validation, undo-safe apply, and item-picker metadata on inventory struct paths.

---

## Assumptions

- Inventory item structs share a common KotOR shape: `InventoryRes` (ResRef), `Dropable`/`Droppable`, `Infinite`, `Recharge` (int flags). Exact spelling follows existing parsed GFF keys in fixtures/tests.
- `EquippedInventory` items use the same struct defaults as `itemList` unless fixture inspection reveals extra slot fields (document any delta in tests).
- Empty `InventoryRes` is allowed at insert time with warn-only validation (modder assigns via item picker afterward).

---

## Requirements

- **R1.** `Inventory`, `EquippedInventory`, and `itemList` support add/remove/reorder via existing GFF array context menu.
- **R2.** New inventory structs receive documented defaults (not empty `{}`).
- **R3.** Inventory ResRef fields inside these arrays retain item-picker metadata and UTI normalization.
- **R4.** Hybrid validation: empty `InventoryRes` warns; resref length capped at 16; required-field rules do not block incremental authoring.
- **R5.** Headless tests cover insert/remove/reorder for inventory arrays and default struct shape.
- **R6.** Execution queue and gap docs reflect Q10 as active/shipped and Q9 in shipped table.

**Origin flows:** F2 Item template pick → apply → undo (from Q9 requirements)  
**Acceptance:** AE4 fewer manual operations for inventory editing

---

## Scope Boundaries

- `gff_tree_populator.gd` — add `Inventory`, `EquippedInventory` to editable struct arrays
- `gff_workspace_editor.gd` — inventory default structs in `_create_default_struct`
- `typed_field_helpers.gd` — extend `is_item_resref_field` for inventory array paths; inventory validation warnings
- `tests/editor/test_gff_inventory_arrays.gd` — new headless tests
- `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`, `STRATEGY.md`

### Deferred

- UTI parsed metadata columns in picker (Tag/LocName)
- Full `SkillList` / `FeatList` array editing
- Batch “fix stale inventory refs” tooling

---

## Implementation Units

### U1. Editable inventory arrays + defaults

**Files:** `ui/workspace/gff_tree_populator.gd`, `ui/workspace/editors/gff_workspace_editor.gd`

Add `Inventory`, `EquippedInventory` to `EDITABLE_STRUCT_ARRAY_FIELDS`. Extend `_create_default_struct` with shared inventory item template:

```gdscript
{
    "InventoryRes": "",
    "Dropable": 1,
    "Infinite": 0,
    "Recharge": 0,
}
```

Apply to `itemList`, `Inventory`, `EquippedInventory`.

### U2. Item picker path detection + validation

**Files:** `ui/workspace/typed_field_helpers.gd`

Extend `is_item_resref_field` when path contains `Inventory`, `EquippedInventory`, or `itemList`. Add warn-only empty `InventoryRes` in `get_validation_warning`.

### U3. Tests + docs

**Files:** `tests/editor/test_gff_inventory_arrays.gd`, execution queue, gap analysis, STRATEGY

Mirror Q7 array insert/remove/reorder tests using in-memory UTC/UTP roots with inventory arrays.

---

## Verification

- All new tests pass headless
- Existing `test_gff_workspace_editor.gd`, `test_item_picker.gd` unchanged behavior
- Queue lists Q1–Q10 shipped after landing

---

## Sources

- `docs/plans/2026-05-24-013-feat-q9-dynamic-enum-registry-inventory-pickers-plan.md` (deferrals)
- `docs/designs/2026-05-24-011-q7-gff-struct-array-schema.md`
- `docs/plans/2026-05-24-011-feat-q7-gff-struct-array-editing-plan.md`
