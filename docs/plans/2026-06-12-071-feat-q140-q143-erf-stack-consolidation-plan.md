---
title: "chore: Q140–Q143 ERF stack consolidation"
type: chore
status: active
date: 2026-06-12
origin: docs/brainstorms/2026-06-10-q140-q143-erf-stack-consolidation-requirements.md
phase: Q129
track: Execution Readiness
related:
  - docs/50-execution/godot-capability-execution-queue.md
  - STRATEGY.md
  - docs/30-gap-analysis/openkotor-parity-matrix.md
  - tests/editor/test_erf_workspace_editor.gd
---

# Q140–Q143 ERF Stack Consolidation

## Summary

Land PRs #124–#133 through a two-wave merge: Q134–Q138 onto `main` first, then bottom-up hygiene on the Q139–Q143 stack until the capstone (#133) merges cleanly. Each wave ends with `test_erf_workspace_editor.gd` green and doc authority synced.

## Problem Frame

The ERF archive wave spans ten open PRs. Five base `main` and are mergeable; five stack and cascade `CONFLICTING` because Q139's Q138 integration merge (`ca47a51`) is local-only and doc/test rows drift additively up the stack. Q129 active slice is blocked on this hygiene.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | Merge #124–#128 in slice order | U1 |
| R2 | ERF tests pass on `main` after Wave 1 | U1 verification |
| R3 | Doc sync for Q134–Q138 landed state | U5 |
| R4 | Push Q139 merge commit before stack work | U2 |
| R5 | Bottom-up conflict resolution Q139–Q143 | U3 |
| R6 | Each stacked PR `MERGEABLE` before merge | U3, U4 |
| R7 | Land #129–#133 in order | U4 |
| R8 | Full ERF test suite on capstone | U4 verification |
| R9 | Close Q129 slice; mark Q140–Q143 shipped | U5 |
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

### U1. Wave 1 — merge Q134–Q138 to main

**Goal:** Land #124, #125, #126, #127, #128 sequentially on `main`.

**Steps (per PR):**
1. Confirm `gh pr checks <n>` / local headless test on PR head if checks absent.
2. Merge via GitHub (squash or merge commit per repo convention).
3. Pull `main` locally before next merge.

**Files touched by merges (already in PRs):**
- `ui/workspace/editors/erf_workspace_editor.gd`
- `resources/documents/kotor_erf_document.gd`
- `tests/editor/test_erf_workspace_editor.gd`
- `tests/editor/test_erf_document_add_member.gd`
- `tests/editor/test_erf_document_remove_replace.gd`
- `editor/modding/kotor_modding_pipeline.gd`

**Test scenarios:**
- After #128 lands: `test_erf_workspace_editor.gd` passes on `main` including override batch extract tests.
- `gh pr view 124..128 --json mergeable` all were `MERGEABLE` at planning time — re-check before each merge.

**Risks:** Doc-only conflicts between parallel `main`-based PRs if queue/matrix rows edited differently — resolve by keeping cumulative Q134–Q138 wording.

### U2. Unblock Q139 (PR #129)

**Goal:** Push local merge commit and restore `MERGEABLE` on #129.

**Steps:**
1. On `feat/q139-erf-extract-all-folder`: `git push origin HEAD` (includes `ca47a51`).
2. If GitHub still reports conflict: merge or rebase `origin/feat/q138-erf-extract-all-override` into Q139 branch.
3. Resolve conflicts in:
   - `tests/editor/test_erf_workspace_editor.gd` — keep all four batch tests (override happy, override skip, folder happy, folder skip).
   - `docs/50-execution/godot-capability-execution-queue.md` — Q139 active slice wording.
   - `docs/30-gap-analysis/openkotor-parity-matrix.md` — superset through Q139.
4. Run `test_erf_workspace_editor.gd`; push; confirm `gh pr view 129 --json mergeable` is `MERGEABLE`.

**Test scenarios:**
- 15 tests pass (current count after Q139 merge resolution).
- PR #129 diff vs Q138 contains only Q139 slice files (6 files, ~182 LOC delta at planning time).

### U3. Bottom-up stack hygiene (Q140–Q143)

**Goal:** Each stacked branch rebased/merged onto updated parent until #133 is mergeable.

**Order:** Q140 branch ← Q139 tip, then Q141 ← Q140, Q142 ← Q141, Q143 ← Q142.

**Per-branch conflict playbook:**
| Branch | Typical conflict files | Resolution rule |
| --- | --- | --- |
| `feat/q140-erf-export-selected-member` | tests, erf_workspace_editor.gd, parity matrix | Add export-selected tests/API; keep all Q139 batch tests |
| `feat/q141-erf-open-game-archive` | erf_workspace_editor.gd, tests | Add open-game-archive dialog; preserve Q140 export |
| `feat/q142-erf-compare-all-members` | erf_workspace_editor.gd, kotor_modding_pipeline.gd, tests | Add batch compare; keep `_test_compare_all_members_skips_invalid` |
| `feat/q143-erf-dirty-path-indicator` | erf_workspace_editor.gd, tests, docs | Add dirty path label; full test union |

**Test scenarios (run on each branch after resolution):**
- Q140: export selected member test passes; all prior batch tests pass.
- Q141: open game archive test passes (if present); export + batch tests pass.
- Q142: batch compare + skip-invalid tests pass.
- Q143: dirty path indicator test passes; full suite green (target: all Q134–Q143 behaviors).

### U4. Wave 2 — merge stacked PRs

**Goal:** Land #129, #130, #131, #132, #133 in order.

**Steps:**
1. Merge #129 into `feat/q138-erf-extract-all-override` OR onto updated base per GitHub stack (if Q138 already on `main`, retarget #129 base to `main` first).
2. After Q138/Q139 on `main`: update #130 base to `main` (or merge Q139 then merge #130).
3. Repeat for #131–#133, verifying `mergeable=MERGEABLE` before each merge.
4. Final merge #133 to `main`.

**Note:** Once Wave 1 completes, consider retargeting entire stack to `main` sequentially rather than merging into feature branches — reduces intermediate branch debt. Choose whichever yields green tests faster; do not duplicate work.

**Test scenarios:**
- Capstone branch: full `test_erf_workspace_editor.gd` pass.
- `gh pr view 129..133 --json mergeable` all `MERGEABLE` before merge clicks.

### U5. Doc authority sync and queue closure

**Goal:** Execution docs match merged reality.

**Files:**
- `docs/50-execution/godot-capability-execution-queue.md` — mark Q134–Q143 shipped; advance active slice past Q129; note PR numbers merged.
- `STRATEGY.md` — ERF wave status on `main`.
- `docs/30-gap-analysis/openkotor-parity-matrix.md` — archive row lists Q134–Q143 as shipped.

**Test scenarios:**
- Grep queue for stale "open PR" qualifiers on landed slices — none remain for #124–#133.
- Q129 active slice row removed or marked completed.

## Verification

```bash
# After each wave and at capstone
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd

# Merge readiness
gh pr view 124 --json mergeable
gh pr view 129 --json mergeable
gh pr view 133 --json mergeable
```

## Dependencies and Sequencing

```
U1 (Q134–Q138 → main)
  → U2 (push/fix Q139)
    → U3 (bottom-up Q140–Q143 hygiene)
      → U4 (merge #129–#133)
        → U5 (doc sync)
```

## Out of Scope

- PRs #120–#123 (parallel NSS/LTR/savegame/MDL tracks)
- New ERF feature work beyond Q143
- GitHub Actions CI setup

## Execution-Time Unknowns

- Whether GitHub allows direct merge of #129 while Q138 still open vs retargeting bases after Wave 1 — decide at U4 based on `gh pr view` base refs after `main` updates.
- Exact conflict hunks on Q141–Q143 branches until U3 rebases run — playbook above covers file categories.
