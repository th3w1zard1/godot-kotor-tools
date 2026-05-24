---
title: feat: GFF entity workspace editor pilot
type: feat
status: complete
date: 2026-05-23
---

# feat: GFF entity workspace editor pilot

## Summary

Move blueprint GFF files (UTC pilot, UTP in the same editor) from the legacy dock GFF inspector onto the main-screen workspace contract: open from the resource browser, document registration, session restore, and save/install with preflight.

## Problem Frame

Plans 001–003 proved the workspace platform for DLG, text/table families, transactions, and dock preflight. Entity GFF blueprints still fall through to the legacy shell when opened from the resource browser. Users editing creatures and placeables lack the same document/session/mutation flow as other workspace editors.

## Requirements

- R1. Opening `.utc` / `.utp` from the resource browser loads a dedicated workspace editor tab (not legacy shell).
- R2. Editor registers documents with `editor_kind` `gff` on the workspace controller.
- R3. Save and install use preview → preflight → apply (with `_skip_preflight_for_testing` for headless tests).
- R4. Session restore reopens saved `gff` documents.
- R5. Minimal field edit (Tag) marks dirty and round-trips through GFFWriter on save/install.

## Scope Boundaries

- In scope: read-only GFF tree, summary panel, Tag edit, UTC/UTP routing, tests, solution doc update.
- Out of scope: full field-tree editing, ARE/GIT/IFO module editors, compare-first UX.

## Implementation Units

### U1. Shared GFF tree populator

**Files:** `ui/workspace/gff_tree_populator.gd`

Extract tree population logic from `ui/kotor_dock.gd` for reuse.

### U2. GFF workspace editor

**Files:** `ui/workspace/editors/gff_workspace_editor.gd`

Mirror `twoda_workspace_editor.gd` patterns: open/save/install, preflight, controller registration, Tag edit.

### U3. Shell routing and session restore

**Files:** `ui/workspace/kotor_workspace_shell.gd`

Route entity GFF extensions to the new editor; restore `gff` session entries.

### U4. Tests and docs

**Files:** `tests/editor/test_gff_workspace_editor.gd`, `docs/solutions/parity-foundation.md`

Headless UTC save/install test with schema-bearing fixture.

## Success Metrics

- Resource browser opens UTC/UTP in workspace editor.
- Headless test passes save + install to override.
- All existing `tests/editor/test_*.gd` scripts pass.
