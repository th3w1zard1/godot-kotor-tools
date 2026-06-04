---
title: Q11 GFF SkillList and FeatList Array Editing
type: feat
status: completed
date: 2026-05-24
origin: docs/plans/2026-05-24-014-feat-q10-gff-inventory-array-editing-plan.md
phase: Q11
track: Phase 2 Capability Expansion
---

# Q11: GFF SkillList and FeatList Array Editing

## Summary

Enable add/remove/reorder mutations for UTC creature progression arrays `SkillList` and `FeatList`, with documented default structs and hybrid validation. Completes the Q7 Phase 1.5 deferral for stat-list editing using the same GFF array machinery shipped in Q7–Q10.

---

## Problem Frame

Q7 shipped general GFF struct-array editing but explicitly deferred `SkillList` and `FeatList` due to stat dependencies. Q10 closed inventory arrays. Creature templates still require manual file surgery to adjust skill ranks and feat entries outside the workspace tree. Q11 applies the proven array pattern: editable arrays, sensible insert defaults, warn-only validation, undo-safe apply, and headless tests.

---

## Assumptions

- **SkillList** entries are structs with a `Rank` field (byte/int). List order maps to skill index (Computer Use, Demolitions, …) per KotOR UTC schema; reorder is allowed but modders should understand index semantics.
- **FeatList** entries are structs with a `Feat` field (word/int index into `feat.2da`). Empty/unset feat uses `65535` (`0xFFFF`) when present in parsed fixtures; otherwise default `0` with warn-only guidance.
- No 2DA-backed feat name picker in this slice — numeric editing only (follow-up can extend `KotorEnumRegistry`).

---

## Requirements

- **R1.** `SkillList` and `FeatList` support add/remove/reorder via existing GFF array context menu.
- **R2.** New structs receive documented defaults (`Rank: 0`, `Feat: 65535` or repo-verified unset sentinel).
- **R3.** Hybrid validation: warn on out-of-range `Rank` (negative or > 127); warn on unset/invalid `Feat` values; do not block incremental authoring.
- **R4.** Existing Q7–Q10 array and picker behavior unchanged.
- **R5.** Headless tests cover insert/remove/reorder and default struct shape for both arrays.
- **R6.** Execution queue, STRATEGY, and gap docs reflect Q11 active → shipped.

**Origin flows:** F1 edit structured data with undo/redo (expansion requirements)  
**Acceptance:** AE4 fewer manual operations for creature stat editing

---

## Scope Boundaries

- `ui/workspace/gff_tree_populator.gd` — add `SkillList`, `FeatList` to editable struct arrays
- `ui/workspace/editors/gff_workspace_editor.gd` — defaults in `_create_default_struct`
- `ui/workspace/typed_field_helpers.gd` — validation warnings for `Rank` and `Feat`
- `tests/editor/test_gff_skill_feat_arrays.gd` — new headless tests
- `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`, `STRATEGY.md`

### Deferred

- 2DA-backed feat label picker / `KotorEnumRegistry` integration for `Feat`
- Skill name labels from `skills.2da`
- Batch stale-reference fix tooling
- UTI picker metadata columns

---

## Implementation Units

### U1. Editable skill/feat arrays + defaults

**Files:** `ui/workspace/gff_tree_populator.gd`, `ui/workspace/editors/gff_workspace_editor.gd`

Add `SkillList`, `FeatList` to `EDITABLE_STRUCT_ARRAY_FIELDS`. Extend `_create_default_struct`:

```gdscript
"SkillList":
    return { "Rank": 0 }
"FeatList":
    return { "Feat": 65535 }
```

### U2. Validation warnings

**Files:** `ui/workspace/typed_field_helpers.gd`

In `get_validation_warning`:
- `Rank`: warn if value < 0 or > 127
- `Feat`: warn if value < 0 or value == 65535 (unset sentinel)

### U3. Tests + docs

**Files:** `tests/editor/test_gff_skill_feat_arrays.gd`, execution queue, STRATEGY, gap analysis

Mirror Q10 tests using in-memory UTC roots with `SkillList` and `FeatList` arrays.

---

## Verification

- `godot --headless --path . --script tests/editor/test_gff_skill_feat_arrays.gd` passes
- `test_gff_inventory_arrays.gd`, `test_gff_workspace_editor.gd` still pass
- Queue lists Q1–Q11 shipped after landing

---

## Sources

- `docs/plans/2026-05-24-014-feat-q10-gff-inventory-array-editing-plan.md` (deferrals)
- `docs/designs/2026-05-24-011-q7-gff-struct-array-schema.md`
- KotOR UTC schema references (SkillList.Rank, FeatList.Feat)
