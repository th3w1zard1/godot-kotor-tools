---
date: 2026-06-03
topic: utp-typed-parity-expansion
---

## Summary

Expand UTP typed parity so placeable editing workflows can access high-value trap and script-hook fields through typed document/resource helpers instead of raw field traversal. Keep behavior install-aware and consistent with existing summary surfaces. Deliver a requirements shape that can be planned as a focused vertical slice.

## Problem Frame

UTP currently exposes a narrow typed surface (`name`, `template`, `tag`, `conversation`, inventory/useable booleans) while the same document already surfaces richer trap and script-hook data in summary output. This creates a mismatch between what users can see and what typed workflows can reliably access, forcing deeper raw-GFF handling for common placeable edits.

Within the current parity program, this gap increases carrying cost: each editor path that needs trap/script fields must rediscover field names instead of relying on one typed contract.

## Key Decisions

- D1. Prioritize UTP next, not a new family: this is the shortest path to value because UTP already has document/typed scaffolding and summary-level evidence of the needed fields.
- D2. Define parity as typed access parity first: user-facing editing behavior should consume typed helpers for trap/script fields before adding broader UX changes.
- D3. Keep this slice bounded to UTP: cross-family abstraction or generation can follow only after this slice clarifies stable requirements and test shape.

## Requirements

**UTP typed helper coverage**

- R1. The UTP document contract must expose explicit typed helpers for placeable trap scalar fields currently treated as first-class summary fields.
- R2. The UTP document contract must expose explicit typed helpers for placeable script hook fields currently treated as first-class summary fields.
- R3. Typed UTP resource wrappers must mirror the new UTP document helper surface so callers can stay on typed APIs.

**Behavior and consistency**

- R4. Typed helper behavior must be deterministic for present, missing, and default-value cases, without requiring callers to inspect raw dictionaries.
- R5. Summary output and typed helper output must remain semantically aligned for overlapping fields.

**Validation and durability**

- R6. Factory mapping tests must cover all newly exposed UTP helper fields with explicit fixture values and direct assertions.
- R7. Existing editor headless regression checks must continue to pass without weakening assertions.
- R8. The slice must not expand scope into unrelated families (UTD, UTT, UTC, etc.) in the same implementation pass.

## Acceptance Examples

- AE1. Covers R1, R3, R6.
  - **Given:** a UTP fixture with concrete trap scalar values.
  - **When:** a typed UTP resource is created from parser output.
  - **Then:** each trap scalar helper returns the expected typed value directly from typed APIs.

- AE2. Covers R2, R3, R6.
  - **Given:** a UTP fixture with explicit script hook values.
  - **When:** typed script helper methods are called on the UTP resource.
  - **Then:** each helper returns the expected script resref value without raw field traversal.

- AE3. Covers R4, R5.
  - **Given:** a UTP fixture missing one optional trap or script field.
  - **When:** typed helpers and summary are both evaluated.
  - **Then:** typed helper fallback behavior is stable and summary semantics remain aligned.

## Success Criteria

- S1. UTP typed surface now includes trap/script helper coverage that matches the intended UTP editing needs for this slice.
- S2. UTP factory assertions provide direct helper-level confidence for newly exposed fields.
- S3. Headless editor validation remains green with no new diagnostics in touched files.

## Scope Boundaries

### Deferred for later

- Cross-family normalization framework for script/trap helper generation.
- Wider blueprint-family parity expansion beyond UTP in this brainstorm artifact.

### Out of scope for this slice

- New workspace UX or inspector interaction redesign.
- Mutation-service, transaction, or install pipeline behavior changes unrelated to UTP typed access parity.

## Dependencies / Assumptions

- The existing UTP summary surface is a valid indicator of which fields are meaningful to expose in typed helpers.
- Current headless test entry points remain the acceptance baseline for this repo.

## Sources / Research

- STRATEGY alignment: `STRATEGY.md`
- UTP current document surface: `resources/documents/kotor_utp_document.gd`
- UTP current typed wrapper surface: `resources/typed/utp_resource.gd`
- Existing parity assertion style and fixture shape: `tests/editor/test_gff_resource_factory.gd`
- Shared script/trap field conventions: `resources/kotor_gff_document.gd`
