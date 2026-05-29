# Godot Capability Execution Queue

## Purpose

This queue turns strategy and gap analysis into an execution-ready order for near-term implementation slices.

Use this document to answer:

1. What should ship next?
2. What must be true before starting?
3. What outcome marks the slice as shipped?

## Shipped Slices

Phase 2 Capability Expansion ([STRATEGY.md](../../STRATEGY.md)) has delivered the following completed capabilities:

| Order | Capability slice | Shipped outcome |
| --- | --- | --- |
| Q1 | Undo/redo command boundaries for document mutations | Users can undo/redo supported document edits (GFF/DLG/2DA/TLK) without losing changed/validation consistency. |
| Q2 | Targeted post-mutation refresh/reindex behavior | Install/restore actions produce deterministic install-aware state without manual re-open/reload workarounds. |
| Q3 | Inspector-guided typed GFF editing helpers | Common structured fields (locstrings, refs, enum-like fields) are editable with guided controls while validation constraints hold. |
| Q4 | Archive write-back parity (ERF/RIM/MOD) | ERF, RIM, and MOD archives support parser→edit→write-back parity through pipeline-owned flows. |
| Q5 | Context-action expansion for compare/install/export | Compare/install/export actions are available from resource browser, document tabs, and area tools surfaces. |
| Q6 | DLG struct/array mutation UI | Reply/entry container editing with add/remove/reorder, hybrid validation, and undo/redo support. |
| Q7 | GFF struct/array editing | GFF struct-array mutations and inline struct field editing with validation and undo/redo. |
| Q8 | Typed field picker UIs | Install-aware ResRef browsers, enum combos, and locstring/strref assist in workspace editors. |
| Q9 | Dynamic enum registry + inventory pickers | Install-aware 2DA enum labels, UTI item picker, GFF itemList integration. |
| Q10 | GFF inventory array editing | Inventory/EquippedInventory/itemList editable with shared item struct defaults. |
| Q11 | GFF skill/feat array editing | SkillList/FeatList editable with Rank/Feat defaults and hybrid validation. |
| Q12 | Install-aware feat/skill 2DA labels | Feat enum labels from feat.2da; SkillList rows show skills.2da names by index. |
| Q13 | GFF blueprint typed factory completion (`utt`, `utw`) | Holocron blueprint types `utt` and `utw` map to typed resources/documents in `GFFResourceFactory` with headless tests. |

## Active Slice

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| P1 | OpenKotOR parity program (PyKotor/Holocron) | Drive upstream parity in bounded Godot editor slices with matrix-driven backlog. | Q13 shipped baseline, parity master plan active, per-slice verification retained. | Next: Q14 blueprint field-depth parity per master plan Phase B. |

## Next Slices (Deferred)

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| Q10 | GFF inventory array editing | Add/remove/reorder `Inventory`, `EquippedInventory`, and proper `itemList` defaults. | Q9 item picker shipped. | **Shipped** — inventory arrays editable with shared item struct defaults. |
| Q11 | GFF skill/feat array editing | Add/remove/reorder `SkillList` and `FeatList` with Rank/Feat defaults. | Q7 array machinery shipped. | **Shipped** — creature skill/feat lists editable in GFF tree. |
| Q12 | Install-aware feat/skill 2DA labels | Feat values and SkillList indices show install 2DA labels in GFF tree. | Q9 enum registry + Q11 arrays shipped. | **Shipped** — feat.2da and skills.2da labels in creature editing. |

## Queue Governance

- Re-evaluate queue order after each shipped slice.
- If a slice no longer aligns with `STRATEGY.md` tracks, move it out of the active queue before planning.
- Keep slices bounded: each item should map cleanly to one focused `ce-plan` and one implementation wave.

## Source Inputs

- Strategy grounding: `STRATEGY.md`
- Gap inventory: `docs/30-gap-analysis/godot-support-gaps.md`
- OpenKotOR parity matrix: `docs/30-gap-analysis/openkotor-parity-matrix.md`
- Next-wave requirements: `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
