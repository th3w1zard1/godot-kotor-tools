---
title: "chore: Q140–Q143 ERF stack consolidation"
type: chore
status: completed
date: 2026-06-12
origin: docs/brainstorms/2026-06-10-q140-q143-erf-stack-consolidation-requirements.md
phase: Q140–Q143
track: Execution Readiness
related:
  - docs/50-execution/godot-capability-execution-queue.md
  - STRATEGY.md
  - docs/30-gap-analysis/openkotor-parity-matrix.md
  - tests/editor/test_erf_workspace_editor.gd
---

# Q140–Q143 ERF Stack Consolidation

## Summary

Landed PRs #124–#133 through a two-wave merge: Q134–Q138 onto `main`, then bottom-up hygiene and sequential retarget-to-`main` for #129–#133. Capstone #133 merged with full `test_erf_workspace_editor.gd` green; doc authority synced via U5.

## Outcome

Q129 merge/stack hygiene closed. Q134–Q143 ERF archive behaviors are on `main`. Active execution queue advanced to Q144+ planning. PRs #120–#123 remain open and unblocked.

## Execution progress

| Unit | Status | Notes |
| --- | --- | --- |
| U1 | Done | #124–#128 merged to `main` (2026-06-10) |
| U2 | Done | #129 pushed and merged to `main` (2026-06-12) |
| U3 | Done | Bottom-up hygiene; full test union on capstone |
| U4 | Done | #129–#133 retargeted to `main` and merged sequentially |
| U5 | Done | Queue, STRATEGY, parity matrix synced |

## Problem Frame (historical)

At planning time, the ERF archive wave spanned ten PRs. Five based on `main` and five stacked with cascading conflicts because Q139's Q138 integration merge (`ca47a51`) was local-only and doc/test rows drifted additively up the stack. Q129 active slice was blocked on this hygiene until consolidation completed.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | Merge #124–#128 in slice order | U1 |
| R2 | ERF tests pass on `main` after Wave 1 | U1 verification |
| R3 | Doc sync for Q134–Q138 landed state | U1 exit + U5 |
| R4 | Push Q139 merge commit before stack work | U2 |
| R5 | Bottom-up conflict resolution Q139–Q143 | U3 |
| R6 | Each stacked PR `MERGEABLE` before merge | U3, U4 |
| R7 | Land #129–#133 in order | U4 |
| R8 | Full ERF test suite on capstone | U4 verification |
| R9 | Close Q129 slice; mark Q134–Q143 shipped | U5 |
| R10 | #120–#123 out of scope | Scope boundary |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Merge topology | Two-wave sequential | Shrinks rebase surface; Q138/Q139 conflict pattern is additive doc/test drift |
| Conflict resolution | Keep all slice tests and toolbar actions | Prior Q143 regression dropped Q142 skip test — union, don't pick sides |
| Doc conflicts | Prefer superset rows (latest slice wins in prose) | Parity matrix and queue entries are cumulative changelog-style |
| Base branch updates | After each Wave 1 merge, fast-forward stacked bases only when needed | Avoid wide rebase until `main` contains Q134–Q138 |

## Existing Patterns

- Q138/Q139 merge resolution (conversation `ca47a51`): test file keeps override batch + folder batch tests in order; docs take Q139 superset wording.
- Per-slice verification: `godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd`
- PR stack bases: #129→Q138, #130→Q139, #131→Q140, #132→Q141, #133→Q142

## Implementation Units

### U1. Wave 1 — Q134–Q138 on `main`

**Outcome:** #124–#128 merged sequentially to `main` (2026-06-10). Wave 1 landed member add/remove/replace, override batch extract, and related document/pipeline tests. Doc conflicts between parallel `main`-based PRs were resolved with cumulative Q134–Q138 queue/matrix wording.

**Files landed:** `erf_workspace_editor.gd`, `kotor_erf_document.gd`, `test_erf_workspace_editor.gd`, `test_erf_document_add_member.gd`, `test_erf_document_remove_replace.gd`, `kotor_modding_pipeline.gd`.

**Verification:** `test_erf_workspace_editor.gd` green on `main` after #128.

### U2. Q139 unblock (PR #129)

**Outcome:** Local Q138 integration merge (`ca47a51`) pushed; #129 conflicts resolved with full four-batch test union and superset doc rows through Q139. #129 merged to `main` (2026-06-12).

**Verification:** 15 headless ERF workspace checks passed at merge time.

### U3. Bottom-up stack hygiene (Q140–Q143)

**Outcome:** Q140–Q143 branches rebased/merged onto updated parents in order. Each slice preserved prior toolbar/tests; Q143 capstone included review hardening (`89871f0` — folder path sanitization, mkdir fail-fast).

**Verification:** Full test union green on `feat/q143-erf-dirty-path-indicator` before Wave 2.

### U4. Wave 2 — stacked PRs on `main`

**Outcome:** #129–#133 retargeted to `main` and merged sequentially after Wave 1. Chose retarget-over-intermediate-branch-merge to reduce stack debt.

**Verification:** Capstone #133 merged with full `test_erf_workspace_editor.gd` pass on `main`.

### U5. Doc authority sync and queue closure

**Outcome:** Queue, STRATEGY, parity matrix, and `godot-support-gaps.md` synced via PR #134 (`feat/erf-u5-doc-closure`). Q129 active slice advanced; Q134–Q143 marked shipped.

**Verification:** No stale "open PR" qualifiers for #124–#133 in authority docs.

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```

Capstone check: full ERF workspace headless suite green on `main` after #133.

## Dependencies and Sequencing

```
U1 → U2 → U3 → U4 → U5 (completed 2026-06-10 through 2026-06-12)
```

## Out of Scope

- PRs #120–#123 (parallel NSS/LTR/savegame/MDL tracks)
- New ERF feature work beyond Q143
- GitHub Actions CI setup

## Execution Record (historical)

_Archive of the operator runbook used during consolidation. Not actionable post-merge._

### Wave 1 sequence

Merged #124, #125, #126, #127, #128 to `main` in order. #128 required a local `main` merge on `feat/q138-erf-extract-all-override` (STRATEGY.md + execution queue conflicts).

### Q139 unblock

Pushed `ca47a51` on `feat/q139-erf-extract-all-folder`. Conflict resolution kept all four batch tests and superset doc rows in `test_erf_workspace_editor.gd`, `godot-capability-execution-queue.md`, `openkotor-parity-matrix.md`.

### Bottom-up hygiene playbook

| Branch | Typical conflict files | Resolution rule |
| --- | --- | --- |
| `feat/q140-erf-export-selected-member` | tests, erf_workspace_editor.gd, parity matrix | Add export-selected tests/API; keep all Q139 batch tests |
| `feat/q141-erf-open-game-archive` | erf_workspace_editor.gd, tests | Add open-game-archive dialog; preserve Q140 export |
| `feat/q142-erf-compare-all-members` | erf_workspace_editor.gd, kotor_modding_pipeline.gd, tests | Add batch compare; keep `_test_compare_all_members_skips_invalid` |
| `feat/q143-erf-dirty-path-indicator` | erf_workspace_editor.gd, tests, docs | Add dirty path label; full test union |

### Wave 2 sequence

Retargeted #129–#133 bases to `main` after Wave 1. Merged each PR sequentially; queue doc conflicts were the dominant hunks on #130–#132.
