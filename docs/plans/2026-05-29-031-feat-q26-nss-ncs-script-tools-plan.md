---
title: Q26 NSS/NCS Script Tools (PyKotor CLI Bridge)
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q26
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q26: NSS Compile / NCS Decompile via PyKotor CLI

## Summary

Wire the Script Editor tab to Holocron/PyKotor script tooling: **assemble** (NSS→NCS), **decompile** (NCS→NSS), and **disassemble** (NCS→text) through `pykotorcli` subprocess calls. Reuse Q25 CLI discovery (`KotorIndoorModExporter.resolve_cli` + `kotor_tools/pykotor_cli_path`).

This closes the explicit gap in `kotor_dock.gd`: *"Compile/decompile support is not implemented yet."*

## Problem frame

NSS editing ships with validation and counterpart lookup, but modders cannot produce or recover bytecode without leaving Godot. Holocron and PyKotor expose `assemble`, `decompile`, and `disassemble` CLI commands — the same companion-CLI pattern as Q25 `indoor-build`.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Build engine | PyKotor CLI subprocess | Matches Holocron; avoids porting NCS compiler/decompiler to GDScript |
| CLI discovery | Reuse `KotorIndoorModExporter.resolve_cli` | Single setting + PATH fallbacks |
| Game target | `--tsl` when install inferred as K2 | Matches PyKotor `assemble`/`decompile` flags |
| Includes | `--include` for script dir, Override, `data/scripts` | Enables `#include` resolution for assemble |
| Input files | Saved path or temp file | CLI requires filesystem paths |
| NCS install | After successful compile, optional install `.ncs` to Override | Completes modding loop |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorScriptToolBridge.validate_preflight` checks operation, paths, CLI | Unit test |
| R2 | `build_command` assembles argv for `assemble`, `decompile`, `disassemble` | Unit test |
| R3 | `run_tool` executes subprocess (or dry_run returns build_command) | Unit test |
| R4 | Script tab toolbar: **Compile**, **Decompile**, **Disassemble** | Manual / editor wiring |
| R5 | Success loads output into editor; failures show stderr in report | UI behavior |
| R6 | Docs mark Q26 shipped in parity matrix + execution queue | Doc update |

## Explicit non-goals (Q26)

- Native GDScript NCS compiler/decompiler port
- External `nwnnsscomp.exe` integration (use PyKotor `assemble` built-in)
- Workspace shell routing changes (dock script tab only)
- Batch compile of entire module trees

## Verification

```bash
godot --headless --path . --script tests/editor/test_script_tool_bridge.gd
```

## Acceptance

- [x] Preflight + command assembly tests pass
- [x] Compile/decompile/disassemble buttons invoke CLI when configured
- [x] Actionable errors when CLI missing
- [x] Docs reflect Q26 shipped
