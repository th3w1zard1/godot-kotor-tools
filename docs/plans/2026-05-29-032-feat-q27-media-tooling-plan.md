---
title: Q27 Media Tooling Parity (SSF/TPC/WAV)
type: feat
status: completed
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q27
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q27: Media Tooling Parity (SSF / TPC / WAV)

## Summary

Ship workspace editors and PyKotor CLI bridges for KotOR **media** resources: native **SSF** read/write, **TPC** preview + TGA export, and **WAV** inspection + clean conversion. Matches Holocron/PyKotor `texture-convert` and `sound-convert` while keeping LIP advanced editing deferred to Q28.

## Problem frame

The parity matrix marks texture/media editing as partial: TPC import exists but there is no dedicated workspace for SSF sound sets, TPC textures, or WAV assets. Modders must leave Godot for Holocron to edit creature sound StrRef mappings or export textures/sounds.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| SSF format | Native GDScript parser/writer (28 slots) | Binary layout is fixed; no CLI round-trip needed for edit loop |
| TPC preview | Existing `TPCReader` | Already decodes mip0 to `ImageTexture` |
| TPC/WAV convert | PyKotor CLI subprocess | Matches Holocron; DXT/TGA and obfuscated WAV handling stays upstream |
| CLI discovery | Reuse `KotorIndoorModExporter.resolve_cli` | Same setting as Q25/Q26 |
| LIP | Defer to Q28 | Out of scope for this slice |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `SSFParser` / `SSFWriter` round-trip 28 StrRef slots | `tests/editor/test_ssf_parser.gd` |
| R2 | `SSFResource` + modding pipeline `ssf` serialize | Pipeline export test via SSF editor save path |
| R3 | `KotorMediaToolBridge` builds `texture-convert` / `sound-convert` argv | `tests/editor/test_media_tool_bridge.gd` |
| R4 | Workspace tabs: SSF Editor, TPC Editor, WAV Editor | Shell routing + dock delegation |
| R5 | SSF: edit StrRefs, save, install to Override | Editor toolbar |
| R6 | TPC: preview + Export TGA | Editor toolbar |
| R7 | WAV: metadata + Convert to clean WAV | Editor toolbar |
| R8 | Docs mark Q27 shipped in parity matrix + execution queue | Doc update |

## Explicit non-goals (Q27)

- LIP lip-sync editor (Q28)
- Full Holocron texture paint / mipmap editor
- In-editor WAV playback for obfuscated game WAV without conversion
- SSF→WAV batch extraction

## Verification

```bash
godot --headless --path . --script tests/editor/test_ssf_parser.gd
godot --headless --path . --script tests/editor/test_media_tool_bridge.gd
```

## Acceptance

- [x] SSF parser/writer tests pass
- [x] Media bridge command tests pass
- [x] `ssf`, `tpc`, `wav` open in dedicated workspace tabs from resource browser
- [x] Docs reflect Q27 shipped
