---
title: Q28 LIP Lip-Sync Tooling Parity
type: feat
status: completed
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q28
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q28: LIP Lip-Sync Tooling Parity

## Summary

Ship native **LIP V1.0** read/write and a workspace **LIP Sync Editor** with keyframe list editing (time + viseme shape), duration control, save/install — matching Holocron/PyKotor binary layout (`LIP ` / `V1.0`, float length, uint32 count, 5-byte keyframes).

## Problem frame

Q27 deferred LIP. The parity matrix still lists lip-sync as backlog. Modders need in-editor keyframe editing without leaving Godot for Holocron's LIP editor.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| LIP format | Native GDScript parser/writer | Fixed 16-byte header + 5×N entries; same as PyKotor `io_lip.py` |
| Visemes | 16 Preston Blair shapes (0–15) | Matches `LIPShape` in PyKotor |
| Waveform / audio scrub | Defer to Q29+ | Holocron uses Qt multimedia; Godot pairing needs separate UX slice |
| Batch LIP generator | Defer | Holocron `batch_processor.py` out of Q28 scope |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `LIPParser` / `LIPWriter` round-trip keyframes + length | `tests/editor/test_lip_parser.gd` |
| R2 | `LIPResource` + modding pipeline `lip` serialize | Editor save path |
| R3 | Workspace tab: LIP Sync Editor | Shell routing + dock delegation |
| R4 | Edit duration, add/remove keyframes, edit time/shape | Editor toolbar + tree |
| R5 | Save, Save As, Install to Override | Mutation service |
| R6 | Docs mark Q28 shipped in parity matrix + execution queue | Doc update |

## Explicit non-goals (Q28)

- Waveform display and scrub-to-keyframe
- Paired WAV auto-load and playback sync
- Batch LIP generation from WAV folder
- LIP XML/JSON import-export via PyKotor CLI

## Verification

```bash
godot --headless --path . --script tests/editor/test_lip_parser.gd
godot --headless --path . --script tests/editor/test_dock_workspace_routing.gd
```

## Acceptance

- [x] LIP parser/writer tests pass
- [x] `lip` opens in dedicated workspace tab from resource browser
- [x] Docs reflect Q28 shipped
