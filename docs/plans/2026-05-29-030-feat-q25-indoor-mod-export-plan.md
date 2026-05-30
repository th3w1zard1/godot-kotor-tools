---
title: Q25 Indoor MOD Export (PyKotor CLI Bridge)
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q25
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q25: Indoor `.mod` Export via PyKotor CLI

## Summary

Wire Indoor Builder to Holocron/PyKotor `indoor-build`: validate game + kits + layout, invoke `pykotorcli indoor-build` (or `python -m pykotor indoor-build`), and write a playable `.mod` from the current `.indoor` document.

This is one vertical slice toward Holocron parity — not full native GDScript `IndoorMap.build()`.

## Problem frame

Q24 surfaces hook connections but export stops at `.indoor` JSON. Holocron authors expect **Build → `.mod`** with ARE/GIT/IFO/LYT/VIS/BWM/MDL/UTD generation handled by PyKotor.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Build engine | PyKotor CLI subprocess | Matches Holocron; avoids multi-thousand-line native port in one slice |
| Input | Saved path or temp `.indoor` | CLI requires filesystem input |
| Kits | Require `--kits` path | Aligns with existing kit library setting; defer `--implicit-kit` |
| CLI discovery | EditorSettings + PATH fallbacks | `pykotor_cli_path`, then `pykotorcli`, then `python3 -m pykotor` |
| Game flag | Infer from install path when possible | Optional `--game k1|k2` for PyKotor |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorIndoorModExporter.validate_preflight` checks rooms, game path, kits, output path, CLI | Unit test |
| R2 | `build_command` assembles `indoor-build` argv matching PyKotor CLI | Unit test |
| R3 | `export_indoor_to_mod` writes input, runs subprocess, returns structured result | Unit test (mock path / no run when `dry_run`) |
| R4 | `KotorEditorState` stores `kotor_tools/pykotor_cli_path` | Editor wiring |
| R5 | Indoor Builder toolbar **Export .mod** + file dialog + status errors | Manual / editor test hook |
| R6 | Docs mark Q25 shipped in parity matrix + execution queue | Doc update |

## Explicit non-goals (Q25)

- Native GDScript `IndoorMap.build()` port
- `--implicit-kit` / module-kit mode
- Loading screen picker UI
- In-editor build log panel (stdout surfaced in status only)

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_mod_export.gd
godot --headless --path . --script tests/editor/test_indoor_hook_connections.gd
godot --headless --path . --script tests/editor/test_indoor_kit_library.gd
```

## Acceptance

- [x] Preflight + command assembly tests pass
- [x] Export button runs CLI when configured and shows actionable errors when not
- [x] Docs reflect Q25 shipped
