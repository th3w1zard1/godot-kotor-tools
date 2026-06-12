---
title: "chore: ERF U5 F2 runbook collapse + compound docs"
type: chore
status: completed
date: 2026-06-10
origin: docs/plans/2026-06-10-075-chore-erf-u5-doc-closure-plan.md
phase: Q144+
track: Execution Readiness
related:
  - docs/plans/2026-06-12-071-feat-q140-q143-erf-stack-consolidation-plan.md
  - docs/solutions/parity-foundation.md
  - docs/solutions/safe-transaction-layer.md
  - CONCEPTS.md
  - https://github.com/th3w1zard1/godot-kotor-tools/pull/134
---

# ERF U5 F2 Runbook Collapse + Compound Docs

## Summary

Complete PR #134 follow-up: collapse the consolidation plan's imperative U1–U4 runbook into a historical execution record, and land compound-knowledge docs (solutions refresh, `CONCEPTS.md`, CE local-config gitignore) on `feat/erf-u5-doc-closure`.

## Problem Frame

PR #134 closed U5 authority docs but left review residual F2 — `docs/plans/2026-06-12-071-feat-q140-q143-erf-stack-consolidation-plan.md` still reads as an active merge runbook. Uncommitted local work updates `docs/solutions/*`, seeds `CONCEPTS.md`, and ignores `.compound-engineering/*.local.yaml`.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | U1–U4 imperative steps moved to historical appendix; narrative sections past-tense | U1 |
| R2 | Execution Record preserves merge outcomes (#124–#133) without actionable merge steps | U1 |
| R3 | `parity-foundation.md` reflects ERF workspace + current editor families | U2 |
| R4 | `safe-transaction-layer.md` documents ERF batch preflight exceptions | U2 |
| R5 | `CONCEPTS.md` committed as project glossary seed | U3 |
| R6 | `.gitignore` excludes CE local config; no IDE state committed | U4 |

## Implementation Units

### U1. Consolidation plan F2 — runbook collapse

**Goal:** Completed plan reads as archive, not operator instructions.

**Files:**
- `docs/plans/2026-06-12-071-feat-q140-q143-erf-stack-consolidation-plan.md`

**Approach:**
- Replace U1–U4 **Steps** blocks with short **Outcome** bullets (what landed, when).
- Add `## Execution Record (historical)` appendix containing condensed merge sequence and conflict-playbook tables for archaeology.
- Remove `gh pr merge` / rebase choreography from primary Implementation Units.
- Keep U5 and Verification as-is (already doc-sync oriented); trim Verification to capstone-only (no per-PR mergeable checks).

**Verification:** Grep plan body for imperative verbs in U1–U4 primary sections (`Confirm`, `Merge via`, `Push`, `retarget`) — none outside Execution Record appendix.

### U2. Solutions docs refresh

**Goal:** Institutional learnings match post-ERF-wave reality.

**Files:**
- `docs/solutions/parity-foundation.md`
- `docs/solutions/safe-transaction-layer.md`

**Approach:** Commit existing working-tree edits (ERF in editor families list; ERF batch mutation exceptions).

**Verification:** Grep both files for `ERF` / `erf_workspace_editor` — present and accurate.

### U3. CONCEPTS.md seed

**Goal:** Shared vocabulary file tracked in repo.

**Files:**
- `CONCEPTS.md`

**Approach:** Commit as-is (workspace/mutation glossary).

**Verification:** File exists at repo root; no secrets or machine-specific paths.

### U4. Gitignore hygiene

**Goal:** CE local config stays untracked.

**Files:**
- `.gitignore`

**Approach:** Commit `.compound-engineering/*.local.yaml` ignore rule only.

**Out of scope for commit:** `.cursor/hooks/state/`, `.cursor/agents/`, `.compound-engineering/config.local.yaml` contents.

**Verification:** `git status` shows no staged IDE state files.

## Test Scenarios

- Doc-only slice: no Godot test run required.
- `grep -E 'Confirm|Merge via|git push' docs/plans/2026-06-12-071-feat-q140-q143-erf-stack-consolidation-plan.md` — matches only inside `## Execution Record` section.

## Dependencies and Sequencing

```
U1 → U2 → U3 → U4 (single PR #134 update commit)
```

## Out of Scope

- Merging PR #134 to `main` (user/CI decision)
- Q144 feature planning
- ERF editor refactor or new tests
- Committing `.compound-engineering/` template files

## Execution-Time Unknowns

- None — all changes are pre-staged doc edits.
