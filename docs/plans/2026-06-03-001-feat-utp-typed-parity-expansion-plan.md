---
title: feat: Expand UTP typed parity for trap and script helpers
type: feat
status: shipped
date: 2026-06-03
origin: docs/brainstorms/2026-06-03-utp-typed-parity-expansion-requirements.md
---

## Summary
Plan and deliver a bounded UTP parity slice that exposes trap scalar and script hook fields through typed document/resource helpers, with deterministic fallback behavior and aligned summary output. The implementation stays scoped to UTP and lands with explicit regression coverage in headless editor tests.

---

## Problem Frame
UTP currently exposes only a thin typed surface while richer trap and script information is already represented in summary behavior. That mismatch increases carrying cost and encourages raw-field traversal in workflows that should be able to rely on typed contracts.

This plan closes that gap in one UTP-only vertical slice aligned to the active parity-expansion strategy, while preserving deterministic editing behavior and test confidence (see origin: docs/brainstorms/2026-06-03-utp-typed-parity-expansion-requirements.md).

---

## Requirements
**UTP typed helper coverage**
- R1. Expose explicit UTP document helpers for placeable trap scalar fields currently treated as first-class summary fields (see origin: docs/brainstorms/2026-06-03-utp-typed-parity-expansion-requirements.md).
- R2. Expose explicit UTP document helpers for placeable script hook fields currently treated as first-class summary fields (see origin: docs/brainstorms/2026-06-03-utp-typed-parity-expansion-requirements.md).
- R3. Mirror the expanded UTP document helper surface in typed UTP resource wrappers so callers stay on typed APIs (see origin: docs/brainstorms/2026-06-03-utp-typed-parity-expansion-requirements.md).

**Behavior and consistency**
- R4. Make helper behavior deterministic for present, missing, and default-value states without requiring raw dictionary access.
- R5. Keep summary and typed helper semantics aligned for overlapping UTP fields.

**Validation and durability**
- R6. Extend factory mapping assertions to cover the newly exposed UTP helper fields with explicit fixture values.
- R7. Preserve green headless editor validation for existing regression entry points.
- R8. Keep this implementation pass scoped to UTP only.

---

## Key Technical Decisions
- KTD1. Use typed helper output as the canonical parity contract, and treat summary output as a consumer of that typed contract rather than a separate source of truth.
- KTD2. Add UTP parity through existing UTP document/resource classes first, avoiding shared cross-family abstraction in this slice.
- KTD3. Represent fallback behavior explicitly in helper methods (missing/unset/default) so callers and tests do not infer semantics from raw GFF data shape.
- KTD4. Keep tests close to existing factory parity style and add only the minimum new assertions needed to lock behavior for this slice.

---

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
  - **When:** typed helpers and summary are evaluated.
  - **Then:** helper fallback behavior is stable and summary semantics remain aligned.

---

## Implementation Units
### U1. Expand UTP trap scalar helper surface
- **Goal:** Add explicit trap-scalar helper coverage in UTP document and typed resource layers.
- **Requirements:** R1, R3, R4, R8
- **Dependencies:** None
- **Files:**
  - resources/documents/kotor_utp_document.gd
  - resources/typed/utp_resource.gd
- **Approach:** Add helper methods for trap scalar fields that already appear as first-class summary information, with deterministic defaults for absent fields.
- **Execution note:** Start with failing helper assertions in existing factory parity tests before final helper method wiring.
- **Patterns to follow:**
  - resources/documents/kotor_utc_document.gd
  - resources/typed/utc_resource.gd
- **Test scenarios:**
  - Happy path: fixture has explicit trap scalars; helpers return exact typed values.
  - Edge case: one trap scalar missing; helper returns deterministic fallback.
  - Error/failure path: malformed scalar type in fixture yields stable coercion/fallback semantics (no caller raw-field dependency).
  - Integration scenario: typed helper output remains consistent when document is created via factory-created resource.
- **Verification:** UTP trap helper assertions pass and no non-UTP typed surfaces change.

### U2. Expand UTP script hook helper surface
- **Goal:** Add explicit script-hook helper coverage for UTP in document and typed resource layers.
- **Requirements:** R2, R3, R4, R8
- **Dependencies:** U1
- **Files:**
  - resources/documents/kotor_utp_document.gd
  - resources/typed/utp_resource.gd
- **Approach:** Add script hook getters aligned to current field naming conventions and mirror them in typed wrappers.
- **Execution note:** Keep helper naming consistent with established typed blueprint naming to minimize caller churn.
- **Patterns to follow:**
  - resources/documents/kotor_utc_document.gd
  - resources/typed/utc_resource.gd
  - resources/kotor_gff_document.gd
- **Test scenarios:**
  - Happy path: fixture includes representative script hook values; helpers return expected resrefs.
  - Edge case: one script field omitted; helper returns deterministic default.
  - Error/failure path: empty-string hook values remain stable and do not break summary composition.
  - Integration scenario: helpers behave consistently when invoked through typed resource created by parser result factory.
- **Verification:** UTP script helper assertions pass with no regressions in existing typed helper behavior.

### U3. Align UTP summary behavior with typed helper contract
- **Goal:** Ensure summary output and typed helper output remain semantically aligned for overlapping UTP fields.
- **Requirements:** R4, R5, R8
- **Dependencies:** U1, U2
- **Files:**
  - resources/documents/kotor_utp_document.gd
- **Approach:** Route summary-relevant field output through the helper semantics defined in U1/U2 and preserve current summary structure where possible.
- **Patterns to follow:**
  - resources/documents/kotor_utd_document.gd
  - resources/documents/kotor_utc_document.gd
- **Test scenarios:**
  - Happy path: summary includes expected values for fields covered by new helpers.
  - Edge case: missing optional trap/script fields still yield stable summary behavior.
  - Error/failure path: malformed optional field does not destabilize summary generation.
  - Integration scenario: summary and typed helper reads agree on value semantics for the same fixture.
- **Verification:** Summary assertions and helper assertions remain mutually consistent across the UTP fixture matrix.

### U4. Extend UTP factory parity regression coverage
- **Goal:** Lock the new UTP helper surface and fallback behavior with direct factory-level assertions.
- **Requirements:** R6, R7, R8
- **Dependencies:** U1, U2, U3
- **Files:**
  - tests/editor/test_gff_resource_factory.gd
  - tests/editor/test_gff_workspace_editor.gd
- **Approach:** Expand UTP fixture data and assertion set to cover helper happy-path and fallback expectations, then verify no regressions in existing headless editor checks.
- **Execution note:** Add deterministic assertions first, then run the existing narrow validation ladder before broader checks.
- **Patterns to follow:**
  - tests/editor/test_gff_resource_factory.gd
- **Test scenarios:**
  - Happy path: each new helper has a direct assertion with explicit fixture data.
  - Edge case: fixture variant omits at least one optional trap/script field and validates fallback semantics.
  - Error/failure path: fixture with malformed optional value confirms stable behavior expectations.
  - Integration scenario: factory-created typed resource and document summary stay aligned for overlapping fields.
- **Verification:** Factory parity test and workspace editor headless test both pass with no relaxed assertions.

---

## Scope Boundaries
### Deferred for later
- Cross-family helper-generation and parity automation framework.
- Broader parity expansion into UTD/UTT and other blueprint families.

### Deferred to Follow-Up Work
- Shared abstraction for trap/script helper contracts across multiple families.

### Out of scope for this slice
- Workspace UX redesign.
- Mutation pipeline and transaction model changes unrelated to UTP typed helper parity.

---

## Risks & Dependencies
- Risk: Field-semantics drift between helper defaults and summary output could reintroduce parity mismatch.
  - Mitigation: Explicit fallback assertions and summary/helper alignment scenarios in U4.
- Risk: Scope creep into adjacent families due shared helper opportunities.
  - Mitigation: UTP-only file touch discipline with explicit boundary checks in code review.
- Dependency: Existing UTP summary and script/trap conventions remain the authoritative parity baseline for this slice.

---

## Sources / Research
- Origin requirements: docs/brainstorms/2026-06-03-utp-typed-parity-expansion-requirements.md
- Strategy context: STRATEGY.md
- Existing UTP document pattern: resources/documents/kotor_utp_document.gd
- Existing UTP typed wrapper pattern: resources/typed/utp_resource.gd
- Shared script/trap field conventions: resources/kotor_gff_document.gd
- Existing typed parity style reference: resources/documents/kotor_utc_document.gd
- Existing typed parity assertions: tests/editor/test_gff_resource_factory.gd
