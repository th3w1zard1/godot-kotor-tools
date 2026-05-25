---
title: Q12 Install-Aware Feat and Skill 2DA Labels
type: feat
status: completed
date: 2026-05-24
origin: docs/plans/2026-05-24-015-feat-q11-gff-skill-feat-array-editing-plan.md
phase: Q12
track: Phase 2 Capability Expansion
---

# Q12: Install-Aware Feat and Skill 2DA Labels

## Summary

Extend `KotorEnumRegistry` and GFF tree display so UTC creature editing shows install-accurate labels for `FeatList.Feat` values and `SkillList` row indices via `feat.2da` and `skills.2da`, completing the explicit Q11 deferral without adding new picker dialogs.

---

## Problem Frame

Q11 shipped SkillList/FeatList array mutations with numeric-only editing. Modders still see opaque indices (`Feat: 42`, `[3]`) instead of game labels from the active install. Q9 established the enum registry pattern for Gender/Race/Appearance; Q11 deferred feat/skill 2DA integration.

---

## Requirements

- **R1.** `Feat` field resolves enum labels from install `feat.2da` when gamefs is available, with static empty fallback (no hardcoded feat table).
- **R2.** `SkillList` array items display skill name from `skills.2da` by array index in tree column 0 (e.g. `[2] Stealth`), falling back to index-only when 2DA unavailable.
- **R3.** Out-of-range values remain editable; display uses `Unknown (n)` pattern consistent with Q9.
- **R4.** Registry cache invalidates on gamefs reindex; headless tests cover feat load, skill label lookup, and fallback.
- **R5.** Execution queue, STRATEGY, and gap analysis mark Q12 shipped.

---

## Scope Boundaries

- Extend `KotorEnumRegistry.FIELD_TO_2DA` and add skill-index label helper
- Mark `Feat` as enum-hint field in tree populator; decorate SkillList item labels during populate or refresh
- Headless tests + docs refresh

**Deferred:**
- Full feat/skill picker dialogs (Q8-style browse)
- DLG nested `RepliesList`/`EntriesList` path-based array editing (separate slice)
- Rank field enum (Rank is skill level, not skill identity)

---

## Key Technical Decisions

1. **Feat uses existing enum pipeline** — Add `"Feat": "feat"` to `FIELD_TO_2DA`; tree populator already sets `enum_field_name` meta when `has_enum_hints("Feat")` returns true after registry extension.
2. **SkillList labels are index-based, not field-based** — Add `get_table_label(table_resref, row_index)` on registry; GFF tree populator checks parent path ends with `SkillList` when naming `[i]` items.
3. **No static feat map** — Rely on 2DA or show raw index only; avoids K1/TSL divergence in code.

---

## Implementation Units

### U1. Registry feat table + skill label helper

**Goal:** Load `feat.2da` for `Feat` field; expose skill row labels from `skills.2da`.

**Files:**
- Modify: `editor/workspace/kotor_enum_registry.gd`
- Test: `tests/editor/test_enum_registry.gd`

**Approach:**
- Add `FIELD_TO_2DA["Feat"] = "feat"`
- Add `get_table_row_label(table_resref: String, row_index: int) -> String` reusing cached table loads
- Add `get_skill_label(skill_index: int) -> String` convenience wrapper

**Test scenarios:**
- Happy path: synthetic `feat.2da` / `skills.2da` in test install → labels resolve
- Fallback: no gamefs → Feat has no enum hints; skill label returns empty string
- Edge case: out-of-range feat index → `Unknown (n)` via existing TypedFieldHelpers

**Verification:** `test_enum_registry.gd` passes with new cases

---

### U2. Tree display integration

**Goal:** Show feat enum hints and skill row labels in GFF tree.

**Files:**
- Modify: `ui/workspace/gff_tree_populator.gd`
- Modify: `ui/workspace/editors/gff_workspace_editor.gd` (pass registry into populate if needed)
- Test: `tests/editor/test_gff_skill_feat_arrays.gd`

**Approach:**
- Ensure `Feat` scalar leaves get `enum_field_name` meta (via `has_enum_hints` once registry wired)
- When populating SkillList elements, append skill label to item text when registry provides one
- Optional: show feat display name in scalar column via existing enum display helpers on refresh

**Test scenarios:**
- Registration: Feat field has enum meta when registry has feat table
- SkillList item text includes label when skills.2da present in test fixture

**Verification:** headless skill/feat array tests pass

---

### U3. Docs and queue refresh

**Files:**
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`
- `docs/30-gap-analysis/godot-support-gaps.md`

**Verification:** Q12 listed as shipped; active slice none

---

## Sources & References

- `docs/plans/2026-05-24-015-feat-q11-gff-skill-feat-array-editing-plan.md` (deferrals)
- `docs/plans/2026-05-24-013-feat-q9-dynamic-enum-registry-inventory-pickers-plan.md` (registry pattern)
- `editor/workspace/kotor_enum_registry.gd`
