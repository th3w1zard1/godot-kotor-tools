---
title: "chore: merge open PRs and post-stack gap audit"
type: chore
status: completed
date: 2026-06-12
origin: user-request-lfg
phase: Q144-prep
track: Execution Readiness
related:
  - docs/residual-review-findings/main-q130-q133-stack.md
  - docs/30-gap-analysis/godot-support-gaps.md
  - docs/50-execution/godot-capability-execution-queue.md
---

# Merge Open PRs and Gap Audit

## Summary

Confirm the GitHub PR queue is empty, reconcile stale plan/doc authority drift after Q130–Q133 + ERF waves, fix the known MDX sidecar install gap, and publish a gap audit for Q144+ planning.

## Problem Frame

User requested merging all open PRs and investigating gaps. `gh pr list --state open` returns zero PRs — merge work is already complete. Remaining risk is authority drift (plans still `active` after ship) and the P1 MDX sidecar install gap from the Q130–Q133 stack review.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | Zero open PRs on GitHub (or merge all mergeable) | U1 |
| R2 | Gap audit documented with tiered findings | U2 |
| R3 | MDX paired install on Model Editor install path | U3 |
| R4 | Stale `status: active` plans for shipped Q119–Q123 module tools closed | U4 |
| R5 | `godot-support-gaps.md` reflects Q130–Q133 shipped scope | U4 |
| R6 | Headless tests pass for touched surfaces | U3 |

## Implementation Units

### U1. PR queue verification

**Goal:** Confirm nothing blocks `main`.

**Verification:**
```bash
gh pr list --state open
```

### U2. Gap audit

**Goal:** Tiered gap inventory for Q144+.

**Files:** `docs/30-gap-analysis/godot-support-gaps.md`

**Sources:** residual findings, parity matrix Partial rows, active slice Q144+, stale plans grep.

### U3. MDX sidecar install (P1)

**Goal:** `Install MDL to Override` writes paired `.mdx` when `MdlResource.has_mdx()`.

**Files:** `ui/workspace/editors/mdl_workspace_editor.gd`, `tests/editor/test_mdl_workspace_editor.gd`

**Verification:**
```bash
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```

### U4. Plan/doc hygiene

**Goal:** Mark shipped slice plans `completed`; fix support-gaps stale queue pointer.

**Files:** `docs/plans/2026-06-10-051` through `055`, `docs/plans/2026-06-10-056`, `docs/plans/2026-06-10-058`, `docs/residual-review-findings/main-q130-q133-stack.md`

## Out of Scope

- Selecting Q144 feature slice
- Holocron master plan full rewrite
- GitHub Actions CI

## Execution-Time Unknowns

- Whether any remote-only branches have unpushed work not represented as PRs — spot-check only.
