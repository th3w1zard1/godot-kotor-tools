---
title: feat: Module GFF workspace routing
type: feat
status: complete
date: 2026-05-23
---

# feat: Module GFF workspace routing

## Summary

Extend the GFF workspace editor so module-family GFF files (ARE, GIT, IFO) open from the resource browser on the same workspace contract as entity blueprints, instead of falling through to the legacy shell.

## Problem Frame

Plan 004 routed entity blueprint extensions (UTC, UTP, etc.) through `gff_workspace_editor.gd`. Module GFF (`.are`, `.git`, `.ifo`) still open in the legacy workspace tab. `GFFResourceFactory` already produces typed ARE/GIT/IFO resources; only routing and allowlists block the workspace path.

## Requirements

- R1. Resource browser opens `.are`, `.git`, and `.ifo` in the GFF workspace editor tab.
- R2. `open_gff_bytes` accepts file types `ARE`, `GIT`, and `IFO` (factory-created typed resources).
- R3. Save and install with preflight continue to work for a module fixture (ARE pilot).
- R4. Session restore for `gff` documents already works; no shell change beyond extension routing.
- R5. Update `docs/solutions/parity-foundation.md` to reflect module GFF on the workspace contract.

## Scope Boundaries

- In scope: extension allowlist, file-type allowlist, open dialog filter, ARE headless test, docs.
- Out of scope: full field-tree editing, DLG/ARE specialized editors, compare-first UX.

## Implementation Units

### U1. Extend GFF workspace allowlists

**Files:** `ui/workspace/editors/gff_workspace_editor.gd`

Add `are`, `git`, `ifo` to workspace-routed extensions and file-type checks. Update open-file filter string.

### U2. Tests

**Files:** `tests/editor/test_gff_workspace_editor.gd`

Add ARE resource fixture test: open, edit Tag, save, install (reuse patterns from UTC test).

### U3. Documentation

**Files:** `docs/solutions/parity-foundation.md`

Note module GFF routing on workspace contract; clarify remaining deferred work (field-tree edit, profiles).

## Success Metrics

- `.are` / `.git` / `.ifo` from resource browser land in GFF Entity Editor tab.
- Headless test covers ARE save + install.
- All `tests/editor/test_*.gd` scripts pass.
