---
title: "chore: Q146 GitHub Actions headless editor test CI"
type: chore
status: completed
date: 2026-06-13
origin: docs/30-gap-analysis/godot-support-gaps.md
phase: Q146
track: Contributor Workflow
related:
  - .github/workflows/headless-editor-tests.yml
  - scripts/run_headless_editor_tests.sh
  - .github/copilot-instructions.md
---

# Q146: GitHub Actions Headless Editor Test CI

## Summary

Add a GitHub Actions workflow that runs all `tests/editor/test_*.gd` headless scripts on push and pull request, closing the P3 **GitHub Actions CI** gap.

## Problem Frame

The repo has 120+ executable headless editor tests but no automated CI gate. Copilot instructions document the `find … xargs godot` pattern manually; contributors and PRs lack a shared validation baseline.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | Workflow triggers on `push` to `main` and all `pull_request` events | U1 |
| R2 | CI installs Godot 4.6.x and runs every `tests/editor/test_*.gd` script | U1, U2 |
| R3 | Runner script exits non-zero on first failure with clear script path logging | U2 |
| R4 | Copilot instructions reference the workflow and runner script | U3 |
| R5 | Execution queue + gap audit mark Q146 shipped | U4 |

## Implementation Units

### U1. GitHub Actions workflow

**Files:** `.github/workflows/headless-editor-tests.yml`

- `ubuntu-latest` job
- Install Godot 4.6.stable via `chickensoft-games/setup-godot`
- Invoke `scripts/run_headless_editor_tests.sh`

### U2. Test runner script

**Files:** `scripts/run_headless_editor_tests.sh`

- Discover `tests/editor/test_*.gd` in sorted order
- Run `godot --headless --path . --script <script>` per file
- Print pass/fail summary; exit 1 if any fail

### U3. Contributor docs

**Files:** `.github/copilot-instructions.md`, `docs/QUICKSTART.md` (optional one-line CI reference)

### U4. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`

## Verification

```bash
bash scripts/run_headless_editor_tests.sh
```

Workflow validates on PR #137 after push.

## Out of Scope

- Parallel test sharding
- GDScript check-only pass on every `.gd` file (too slow for initial CI)
- Browser/UI verification
