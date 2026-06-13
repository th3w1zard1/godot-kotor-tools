---
title: "feat: Holocron parity Wave C — savegame write-back"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q153-Q154
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - ui/workspace/editors/savegame_workspace_editor.gd
  - formats/savegame_inspector.gd
  - resources/documents/kotor_erf_document.gd
---

# Wave C: Savegame Write-back (Q153–Q154)

## Summary

Move from read-only/extract-only savegame tooling to Holocron `savegame.py` parity: edit SAV members in-place and write back the `.sav` container.

## Godot today

- Q132: read-only inspector (`savenfo`, `partytable`, `globalvars`)
- Q147/Q149: extract single/all members to override

## Requirements

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | `KotorSavegameDocument` wraps SAV ERF with member mutation API | Q153 |
| R2 | Edit selected member via embedded GFF document; dirty tracking per member | Q153 |
| R3 | Write modified member bytes back into SAV container | Q154 |
| R4 | Save-as / install modified `.sav` with preflight + undo | Q154 |
| R5 | Headless round-trip: parse → mutate member → serialize → re-parse | Q154 |

## Q153 — Member edit path

**Files:**
- `resources/documents/kotor_savegame_document.gd` (new)
- `ui/workspace/editors/savegame_workspace_editor.gd` — **Edit Member** flow
- `tests/editor/test_savegame_workspace_editor.gd`

**Pattern:** ERF document mutation + `KotorModdingPipeline` serialize arm for `sav`.

## Q154 — Full SAV write-back

**Files:**
- `formats/erf_writer.gd` — SAV container round-trip
- `savegame_workspace_editor.gd` — **Save SAV** / **Install SAV** toolbar
- Preflight via `KotorPreflightDialog`

## Verification

```bash
godot --headless --path . --script tests/editor/test_savegame_workspace_editor.gd
godot --headless --path . --script tests/editor/test_savegame_inspector.gd
```

## Out of scope

- Runtime savegame loading in game engine
- K2 save format deltas (Q200+)
