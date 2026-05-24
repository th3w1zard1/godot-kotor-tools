---
title: feat: Dock workspace editor routing
type: feat
status: complete
date: 2026-05-23
---

# feat: Dock workspace editor routing

## Summary

When the legacy dock is embedded in `KotorWorkspaceShell`, GameFS opens from the dock sidebar should use the same workspace editors as the resource browser (DLG pilot, 2DA, TLK, script, GFF entity editor) instead of the read-only legacy dock tabs.

## Problem Frame

Plans 004–008 built the GFF workspace editor and resource-browser routing. The dock’s internal workspace tree still calls `_open_gamefs_entry`, which loads UTC/ARE/etc. into the legacy “GFF Inspector” tab. Users editing from the Legacy Workspace tab get a worse experience than opening the same file from Resources.

## Requirements

- R1. With a workspace entry opener wired, dock opens `dlg`, `2da`, `tlk`, `nss`/`ncs`, and workspace-allowed GFF extensions via `KotorWorkspaceShell._open_workspace_entry`.
- R2. Extensions not handled by workspace editors (e.g. `jrl`, `erf`, area tools) keep legacy dock behavior.
- R3. Delegation must not recurse when workspace falls through to legacy shell for unhandled types.
- R4. Headless test: dock with opener delegates UTC; dock without opener does not call opener.
- R5. Update `docs/solutions/parity-foundation.md`.

## Scope Boundaries

- In scope: `kotor_dock.gd`, `kotor_editor_shell.gd`, `kotor_workspace_shell.gd`, one headless test, docs.
- Out of scope: Removing legacy GFF tab, locstring/struct tree editing, profiles.

## Implementation Units

### U1. Dock delegate hook

**Files:** `ui/kotor_dock.gd`

- Preload `KotorGFFWorkspaceEditor`.
- `set_workspace_entry_opener(Callable)`.
- `_should_delegate_to_workspace_editor(extension)`.
- At start of `_open_gamefs_entry`, delegate before GameFS byte load when opener is valid.

### U2. Wire opener from workspace shell

**Files:** `editor/shell/kotor_editor_shell.gd`, `ui/workspace/kotor_workspace_shell.gd`

- `get_dock()` on editor shell.
- After legacy shell is created, `set_workspace_entry_opener(Callable(self, "_open_workspace_entry"))`.

### U3. Tests and docs

**Files:** `tests/editor/test_dock_workspace_routing.gd`, `docs/solutions/parity-foundation.md`

## Success Metrics

- UTC opened from dock workspace tree lands on GFF Entity Editor tab when shell is wired.
- `tests/editor/test_*.gd` pass.
