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

## Next Slices (Deferred)

These items are planned for Phase 2+ waves pending completion of prior dependencies and readiness validation. No detailed requirements are active yet.

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| Q6 | DLG struct/array mutation UI | Extend mutation surface for dialogue-specific container editing (speaker-action arrays, links, reply conditions). | Q1 (undo/redo) complete, DLG document surface design validated. | Priority deferred pending validation of struct/array editing patterns from Q7 (GFF). |
| Q7 | GFF struct/array editing | Add array add/remove/reorder controls and struct-field mutation for locstring trees and complex field hierarchies. | Q3 (typed helpers) patterns validated, struct editing interaction design sketched. | Foundation for Q6 DLG and Q8 typed field picker expansion. |
| Q8 | Typed field picker UIs | Add inspector-backed editors for resref file browsers and enum combos sourced from gamefs registry. | Q7 (struct/array patterns) validated, gamefs API stability confirmed. | Builds on Q3 typed helpers; depends on consistent struct/array surface from Q7. |

## Queue Governance

- Re-evaluate queue order after each shipped slice.
- If a slice no longer aligns with `STRATEGY.md` tracks, move it out of the active queue before planning.
- Keep slices bounded: each item should map cleanly to one focused `ce-plan` and one implementation wave.

## Source Inputs

- Strategy grounding: `STRATEGY.md`
- Gap inventory: `docs/30-gap-analysis/godot-support-gaps.md`
- Next-wave requirements: `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
