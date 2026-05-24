---
title: feat: Refresh Copilot instruction guidance
type: feat
status: completed
date: 2026-05-24
---

# feat: Refresh Copilot instruction guidance

## Summary

Update `.github/copilot-instructions.md` so future Copilot sessions have accurate project commands, current architecture context, and repository-specific conventions.

---

## Problem Frame

The existing Copilot guidance captured core parser architecture and check-only validation, but it lagged behind current workspace/mutation layers and did not document executable headless editor test commands.

---

## Requirements

- R1. Document build/test/lint command reality for this repo, including single-test and full-test invocation.
- R2. Reflect current plugin/workspace architecture across plugin entry, workspace shell, and mutation pipeline layers.
- R3. Preserve codebase-specific conventions (GFF document wrappers, GameFS precedence, saver/importer behavior) without generic advice.
- R4. Improve the existing instruction file in place rather than replacing it wholesale.

---

## Scope Boundaries

### In scope

- `.github/copilot-instructions.md` content updates
- Verifying command correctness against the current repository

### Out of scope

- Functional plugin/runtime behavior changes
- New test framework or lint/build tooling introduction

---

## Implementation Units

### U1. Reconcile command guidance with actual repo workflows

**Goal:** Ensure command instructions map to commands that are actually usable in this codebase.

**Requirements:** R1

**Dependencies:** None

**Files:** `.github/copilot-instructions.md`

**Approach:** Keep existing check-only commands; add explicit single headless test and all-tests command forms used by current `tests/editor/test_*.gd` scripts.

**Patterns to follow:** Existing command style and direct Godot CLI usage already present in `.github/copilot-instructions.md`.

**Test scenarios:**
- Running a single headless test script exits successfully.
- Running all `tests/editor/test_*.gd` scripts via a batch command exits successfully.
- Running check-only over repo GDScript files exits successfully.

**Verification:** The command section includes single-file check, repo-wide check, single-test, and all-test commands that execute in this repository.

### U2. Refresh high-level architecture mapping

**Goal:** Align architecture notes to the current workspace-centric editor flow.

**Requirements:** R2

**Dependencies:** U1

**Files:** `.github/copilot-instructions.md`

**Approach:** Update architecture bullets to include `plugin.gd` wiring to workspace controller/main screen, `kotor_workspace_shell.gd` role, and mutation service/pipeline responsibilities.

**Patterns to follow:** Existing architecture bullet formatting in `.github/copilot-instructions.md`.

**Test scenarios:**
- Confirm architecture section references workspace shell composition and transaction/mutation layers.
- Confirm architecture section still includes canonical format/parser and GameFS indexing roles.

**Verification:** Architecture section reflects current module boundaries and ownership without file-list bloat.

### U3. Tighten key conventions for future edits

**Goal:** Preserve and sharpen non-obvious repository conventions for future Copilot sessions.

**Requirements:** R3, R4

**Dependencies:** U2

**Files:** `.github/copilot-instructions.md`

**Approach:** Keep existing convention bullets, refine mutation-flow and test-pattern conventions, and keep changes additive to the current file.

**Patterns to follow:** Existing convention phrasing and vertical-slice format support guidance in this repo.

**Test scenarios:**
- Guidance explicitly states GFF edits should flow through document wrappers.
- Guidance explicitly states mutating install/export flows should use mutation service + pipeline preflight/apply flows.
- Guidance keeps importer `.tres` behavior and saver write-back convention clear.

**Verification:** Key-conventions section remains concise, repo-specific, and directly actionable for future sessions.

---

## Deferred Implementation Notes

- Exact wording polish can be refined in follow-up doc-only updates without changing technical intent.
