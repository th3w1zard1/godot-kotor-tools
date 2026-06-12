---
title: "chore: Q130–Q133 stack merge (#120–#123)"
type: chore
status: active
date: 2026-06-10
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q130–Q133
track: Execution Readiness
related:
  - docs/plans/2026-06-12-071-feat-q140-q143-erf-stack-consolidation-plan.md
  - tests/editor/test_script_compile_install.gd
  - tests/editor/test_ltr_workspace_editor.gd
  - tests/editor/test_savegame_workspace_editor.gd
  - tests/editor/test_mdl_writer.gd
---

# Q130–Q133 Stack Merge (#120–#123)

## Summary

Land the parallel NSS/LTR/savegame/MDL wave by rebasing each open PR onto current `main` (post-ERF U5), resolving doc conflicts, and merging #120 → #121 → #122 → #123 sequentially.

## Problem Frame

PRs #120–#123 were opened parallel to the ERF wave. `main` advanced through #124–#133 and U5 doc closure (`f90b9f4`), leaving all four PRs `CONFLICTING`. Queue active slice is Q144+ TBD; this stack is the highest-priority open implementation work.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | #120 mergeable and merged to `main` (Q130 NSS compile install) | U1 |
| R2 | #121 mergeable and merged after #120 (Q131 LTR workspace) | U2 |
| R3 | #122 mergeable and merged after #121 (Q132 savegame inspector) | U3 |
| R4 | #123 mergeable and merged after #122 (Q133 MDL writeback phase 0) | U4 |
| R5 | Headless tests pass per slice after conflict resolution | U1–U4 |
| R6 | Execution queue + parity matrix reflect shipped Q130–Q133 | U5 |

## Implementation Units

### U1. Resolve and merge #120 (Q130)

**Goal:** NSS compile-to-override on `main`.

**Branch:** `feat/q130-nss-compile-install`

**Conflict playbook:** `godot-capability-execution-queue.md`, `openkotor-parity-matrix.md`, `STRATEGY.md`, `godot-support-gaps.md` — prefer post-ERF `main` superset + Q130 shipped rows.

**Files (feature):** `script_workspace_editor.gd`, `kotor_dock.gd`, `test_script_compile_install.gd`, `kotor_script_document.gd`

**Verification:**
```bash
godot --headless --path . --script tests/editor/test_script_compile_install.gd
```

### U2. Resolve and merge #121 (Q131)

**Goal:** LTR parser + workspace editor on `main`.

**Branch:** `feat/q131-ltr-workspace`

**Conflict playbook:** Doc files + `kotor_dock.gd` routing; keep Q130 script install paths.

**Verification:**
```bash
godot --headless --path . --script tests/editor/test_ltr_parser.gd
godot --headless --path . --script tests/editor/test_ltr_workspace_editor.gd
```

### U3. Resolve and merge #122 (Q132)

**Goal:** Savegame inspector workspace on `main`.

**Branch:** `feat/q132-savegame-inspector`

**Conflict playbook:** `kotor_workspace_shell.gd`, dock routing, doc superset through Q132.

**Verification:**
```bash
godot --headless --path . --script tests/editor/test_savegame_inspector.gd
godot --headless --path . --script tests/editor/test_savegame_workspace_editor.gd
```

### U4. Resolve and merge #123 (Q133)

**Goal:** MDL writeback phase 0 on `main`.

**Branch:** `feat/q133-mdl-writeback-phase0`

**Conflict playbook:** `kotor_modding_pipeline.gd`, doc superset through Q133.

**Verification:**
```bash
godot --headless --path . --script tests/editor/test_mdl_writer.gd
```

### U5. Post-merge doc authority

**Goal:** Active slice advances past Q133; Q130–Q133 marked shipped in queue and parity matrix.

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`, `STRATEGY.md`

**Verification:** Grep queue for Q130–Q133 without stale open-PR language.

## Dependencies and Sequencing

```
U1 (#120) → U2 (#121) → U3 (#122) → U4 (#123) → U5
```

## Out of Scope

- Q144 new feature selection
- Holocron parity roadmap (#56 plan)
- GitHub Actions CI setup

## Execution-Time Unknowns

- Exact conflict hunks until `git merge origin/main` on each branch — doc cumulative merge rule applies.
