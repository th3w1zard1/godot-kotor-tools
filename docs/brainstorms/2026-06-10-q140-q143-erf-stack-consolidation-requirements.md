---
title: "Q140–Q143 ERF stack consolidation and merge hygiene"
type: requirements
status: active
date: 2026-06-10
origin: ce-brainstorm
related:
  - docs/50-execution/godot-capability-execution-queue.md
  - STRATEGY.md
---

# Q140–Q143 ERF Stack Consolidation

## Summary

Land the Q134–Q143 ERF archive wave through a two-phase merge: merge the five `main`-based slices (Q134–Q138) first, then unblock and land the stacked Q139–Q143 chain bottom-up. Each phase ends with headless ERF workspace tests green and execution-queue docs aligned to what actually merged.

## Problem Frame

Ten open PRs (#124–#133) implement the ERF archive authoring wave. Q134–Q138 target `main` and are mergeable today. Q139–Q143 stack on each other and show cascading `CONFLICTING` status — largely doc/test drift and an unpushed Q139 merge commit (`ca47a51`) that integrates Q138. Without a deliberate merge order, reviewers cannot trust the stacked tip and the Q129 active slice ("merge/stack hygiene") stalls.

## Requirements

**Wave 1 — main-based slices**

- R1. Merge PRs #124–#128 (Q134–Q138) into `main` in slice order (Q134 first through Q138 last) without dropping any shipped behavior from the wave.
- R2. After each Wave 1 merge (or after the full wave if CI is batched), `godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd` passes on `main`.
- R3. Wave 1 completion updates `docs/50-execution/godot-capability-execution-queue.md`, `STRATEGY.md`, and `docs/30-gap-analysis/openkotor-parity-matrix.md` so Q134–Q138 rows reflect merged state (no stale "open PR" qualifiers for landed slices).

**Wave 2 — stacked slices**

- R4. Push the local Q139 merge commit to `origin/feat/q139-erf-extract-all-folder` before rebasing or updating upstream PR #129.
- R5. Resolve merge conflicts bottom-up: Q139 onto updated Q138 tip, then Q140, Q141, Q142, Q143 — preserving all toolbar actions and tests from each slice (no silent drops like the Q142 skip test regression fixed in Q143).
- R6. After each stacked PR is unblocked, its GitHub mergeable status is `MERGEABLE` against its declared base branch.
- R7. Wave 2 lands through PRs #129–#133 in order; the capstone (#133 / Q143) merges only after #129–#132 are mergeable and tested.

**Verification and closure**

- R8. Final verification on the Q143 branch (or `main` after full landing): full `test_erf_workspace_editor.gd` suite passes with all batch extract, compare, export, open-archive, and dirty-path behaviors covered.
- R9. Close Q129 active-slice planning item: execution queue advances past "merge/stack hygiene for Q130–Q139" and records Q140–Q143 as shipped with PR references.
- R10. Residual open PRs outside the ERF wave (#120–#123) are explicitly out of scope for this consolidation pass — note their status but do not block ERF wave landing.

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Consolidation shape | Two-wave sequential merge | Q134–Q138 are independent of the stack; landing them first shrinks the rebase surface for Q139–Q143 |
| PR preservation | Keep individual PRs #124–#133 | Review history and slice traceability stay intact; matches existing Compound/LFG workflow |
| Conflict resolution | Bottom-up per stacked branch | Matches proven Q138/Q139 merge pattern; doc/test conflicts are additive, not intent conflicts |
| Squash alternative | Rejected for this pass | Higher review cost and loses per-slice blame; only reconsider if bottom-up fails twice |

## Scope Boundaries

**In scope**

- Git merge/rebase hygiene across #124–#133
- Doc authority sync for landed slices
- Headless test verification gates per wave

**Deferred for later**

- Rebasing parallel tracks #120–#123 onto post-wave `main`
- New ERF parity slices beyond Q143
- CI/GitHub Actions introduction (repo still uses local headless gates)

**Outside this product's identity**

- Rewriting the ERF editor architecture or collapsing the stacked PRs into one mega-PR without user request

## Success Criteria

- All ten ERF wave PRs (#124–#133) are merged to `main` in order with no regressions in `test_erf_workspace_editor.gd`.
- No open `CONFLICTING` status remains on #129–#133 when the capstone merges.
- Execution queue and parity matrix describe Q134–Q143 as shipped, not open.

## Outstanding Questions

- None blocking — merge order and two-wave shape are confirmed.

## Approaches Considered

**A. Two-wave sequential (chosen)** — Land Q134–Q138 on `main`, then bottom-up stack hygiene for Q139–Q143. Lowest risk; reuses Q138/Q139 conflict playbook.

**B. Single squash PR** — One branch off `main` with full wave diff. Faster merge click count but loses per-slice review and rebases all open review threads.

**C. Top-down rebase only** — Rebase Q143 onto `main` without intermediate merges. High conflict density across six slices in one step; hard to bisect failures.
