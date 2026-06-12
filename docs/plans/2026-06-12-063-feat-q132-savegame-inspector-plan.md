---
title: "feat: Q132 Savegame inspector foundations"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q132
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-027-feat-q127-erf-workspace-plan.md
  - docs/50-execution/godot-capability-execution-queue.md
---

# Q132: Savegame Inspector Foundations

## Summary

Add read-only KotOR `.sav` (SAV ERF) metadata inspection and route save files through a dedicated workspace tab, extracting `savenfo`, `partytable`, and `globalvars` GFF summaries per Holocron `savegame.py` parity.

## Problem Frame

KotOR saves are `SAV` ERF containers with embedded GFF members. Q127 ships a generic archive browser for `.sav`, but modders lack save-specific metadata (name, module, area, play time, party size). Holocron exposes this via `savegame.py`; Godot parity lists savegame as **Not started**.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `SavegameInspector.inspect_bytes` parses SAV ERF and extracts savenfo/partytable/globalvars metadata | `test_savegame_inspector.gd` |
| R2 | `SavegameInspectorResource` holds inspection snapshot (read-only) | Resource test |
| R3 | `KotorSavegameWorkspaceEditor` shows metadata + member tree; member open delegates to workspace | `test_savegame_workspace_editor.gd` |
| R4 | `.sav` routes to Savegame Inspector (not generic Archive Browser) in shell + dock | Routing grep / headless test |
| R5 | ERF workspace keeps `erf`/`rim`/`mod` only; `sav` removed from archive extensions | Static helper test |
| R6 | Execution queue marks Q132 shipped; active slice → Q133 | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Scope | Read-only metadata + member browse | Foundations slice — no save editing or write-back |
| Parser | Reuse `ERFParser` + `GFFParser` on known resrefs | Avoid duplicate container logic |
| Routing | Dedicated tab for `.sav` | Distinct UX from mod/erf archive tooling |
| Pattern | Mirror Q127 ERF editor shell with inspector header | Established workspace stack |

## Implementation Units

### U1. Inspector + resource

**Files:**

- `formats/savegame_inspector.gd`
- `resources/savegame_inspector_resource.gd`

### U2. Workspace editor + routing

**Files:**

- `ui/workspace/editors/savegame_workspace_editor.gd`
- `ui/workspace/editors/erf_workspace_editor.gd` (remove `sav` from archive list)
- `ui/workspace/kotor_workspace_shell.gd`
- `ui/kotor_dock.gd`

### U3. Tests + docs

**Files:**

- `tests/editor/test_savegame_inspector.gd`
- `tests/editor/test_savegame_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_savegame_inspector.gd
godot --headless --path . --script tests/editor/test_savegame_workspace_editor.gd
```

## Out of Scope (Q133+)

- Save editing / mutation
- Folder-level `savenfo.res` outside `.sav` ERF
- Full party member field inspection
