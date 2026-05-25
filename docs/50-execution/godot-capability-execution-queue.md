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

## Active Slice

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| Q8 | Typed field picker UIs | Add install-aware ResRef browsers, enum combos, and locstring/strref assist in workspace editors. | Q7 struct/array patterns validated; gamefs browse API stable. | Builds on Q3 typed helpers and Q6/Q7 editor surfaces. |

## Next Slices (Deferred)

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| Q9 | Dynamic enum registry + inventory pickers | Load enum labels from 2DA/gamefs and add item/inventory picker UX. | Q8 picker patterns validated. | Follow-up to Q8 static enum mapping. |

## Queue Governance

- Re-evaluate queue order after each shipped slice.
- If a slice no longer aligns with `STRATEGY.md` tracks, move it out of the active queue before planning.
- Keep slices bounded: each item should map cleanly to one focused `ce-plan` and one implementation wave.

## Source Inputs

- Strategy grounding: `STRATEGY.md`
- Gap inventory: `docs/30-gap-analysis/godot-support-gaps.md`
- Next-wave requirements: `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
