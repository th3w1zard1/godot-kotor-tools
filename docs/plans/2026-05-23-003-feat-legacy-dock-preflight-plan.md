---
title: feat: Interactive preflight for legacy dock mutations
type: feat
status: complete
date: 2026-05-23
completed: 2026-05-23
---

## Progress (2026-05-23)

| Unit | Status |
|------|--------|
| U1 | Landed — `_run_mutation_preflight` coordinator on `KotorDock` |
| U2 | Landed — GameFS + ERF export/install routed through preview |
| U3 | Landed — DLG/2DA/TLK/script tab mutations routed |
| U4 | Landed — `test_dock_preflight_routing.gd`, solution doc update |

# feat: Interactive preflight for legacy dock mutations

## Summary

Workspace editors already show `KotorPreflightDialog` before install/export mutations. Legacy `ui/kotor_dock.gd` routes through `KotorMutationService` but calls `apply_*` directly with default `proceed=true`, bypassing the user-facing preview step. This plan closes that gap so dock mutations match workspace safety UX.

## Problem Frame

PR #1 residual P3: dock install/export records transactions but does not surface preflight. Users editing via dock tabs (GFF inspector paths, GameFS browser, ERF, DLG/2DA/TLK/script singleton tabs) can mutate the install without the same confirmation flow as workspace editors.

## Requirements

- R1. Every dock `apply_install_to_override` and `apply_export_to_path` entrypoint must call `preview_*` first.
- R2. When preview is ok and action is not noop, show `KotorPreflightDialog` unless test skip flag is set.
- R3. Apply mutations only after user proceeds; cancel must not write files.
- R4. Existing `_skip_preflight_for_testing` pattern must allow headless tests to bypass UI.
- R5. Noop previews must short-circuit without opening the dialog.

## Scope Boundaries

- In scope: all direct `apply_*` calls in `ui/kotor_dock.gd`.
- Out of scope: new compare-first UX, entity GFF workspace migration, profile manager.

## Implementation Units

### U1. Preflight coordinator on KotorDock

**Files:** `ui/kotor_dock.gd`, `ui/workspace/dialogs/kotor_preflight_dialog.gd` (reuse only)

Add `_preflight_dialog`, pending apply callable, `_skip_preflight_for_testing`, and `_run_mutation_preflight(preview, apply_fn, on_complete)`.

### U2. Route GameFS and ERF mutations

**Files:** `ui/kotor_dock.gd`

Refactor `_export_gamefs_entry`, `_install_gamefs_entry`, `_export_selected_erf_entry`, `_install_selected_erf_entry`.

### U3. Route format-tab mutations

**Files:** `ui/kotor_dock.gd`

Refactor DLG, 2DA, TLK, and script save/install helpers.

### U4. Tests and docs

**Files:** `tests/editor/test_dock_preflight_routing.gd`, `docs/solutions/safe-transaction-layer.md`

Headless tests with skip flag; document dock parity with workspace preflight.

## Success Metrics

- Dock install/export paths show the same preflight dialog as workspace editors for destructive actions.
- Cancel leaves install unchanged (service-level contract already enforced when `proceed=false`).
- All existing editor headless tests pass.
