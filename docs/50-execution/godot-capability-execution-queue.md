# Godot Capability Execution Queue

## Purpose

This queue turns strategy and gap analysis into an execution-ready order for near-term implementation slices.

Use this document to answer:

1. What should ship next?
2. What must be true before starting?
3. What outcome marks the slice as shipped?

## Queue

| Order | Capability slice | Why now | Start readiness criteria | Shipped outcome |
| --- | --- | --- | --- | --- |
| Q1 | Undo/redo command boundaries for document mutations | Highest leverage safety improvement for frequent editing workflows. | Shared document mutation entry points are identified for GFF/DLG/2DA/TLK editors. | Users can undo/redo supported document edits without losing changed/validation consistency. |
| Q2 | Targeted post-mutation refresh/reindex behavior | Prevents stale winners/variants after install or restore actions. | Mutation pipeline refresh points are mapped with current failure paths documented. | Install/restore actions produce deterministic install-aware state without manual re-open/reload workarounds. |
| Q3 | Inspector-guided typed GFF editing helpers | Reduces manual errors in high-frequency structured fields. | Candidate typed field groups (locstrings, refs, enum-like selectors) are finalized. | Common structured fields are editable with guided controls while existing validation constraints hold. |
| Q4 | Archive write-back parity (ERF/RIM/MOD) | Unlocks true round-trip packaging workflows. | Serializer boundaries and saver integration points are defined for archive families. | At least one archive family supports parser→edit→write-back parity through pipeline-owned flows. |
| Q5 | Context-action expansion for compare/install/export | Shortens repetitive navigation effort in workspace flows. | Existing action surfaces are inventoried; no duplicate write logic paths introduced. | Compare/install/export actions are available from more relevant surfaces with unchanged pipeline semantics. |

## Queue Governance

- Re-evaluate queue order after each shipped slice.
- If a slice no longer aligns with `STRATEGY.md` tracks, move it out of the active queue before planning.
- Keep slices bounded: each item should map cleanly to one focused `ce-plan` and one implementation wave.

## Source Inputs

- Strategy grounding: `STRATEGY.md`
- Gap inventory: `docs/30-gap-analysis/godot-support-gaps.md`
- Next-wave requirements: `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
