---
title: "feat: Q51 HoloPatcher CLI bridge"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q50-next-holopatcher-slice
phase: Q51
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-022-feat-q49-kotordiff-cli-bridge-plan.md
  - docs/plans/2026-06-04-013-feat-q40-override-batch-compare-plan.md
---

# Q51: HoloPatcher CLI Bridge

## Summary

Add `HoloPatcherToolBridge` to invoke standalone `holopatcher` or `python -m holopatcher` for TSL patch validate/install from the GameFS dock, with headless command tests.

---

## Problem Frame

Q49 shipped KotorDiff CLI from the dock. HoloPatcher remains backlog in the parity matrix. Modders applying TSLPatcher mods still leave the editor. This slice adds a companion CLI bridge matching `KotorDiffToolBridge`.

---

## Scope Boundaries

### In scope

- `resources/patch/holo_patcher_tool_bridge.gd`
- GameFS dock **Validate TSL Patch…** and **Install TSL Patch…** (game dir defaults to install)
- Headless `tests/editor/test_holo_patcher_tool_bridge.gd`
- Execution queue + parity matrix Q51 entry

### Deferred

- GUI HoloPatcher launcher
- `--uninstall` / incremental patch UI
- Native in-editor patch application

### Out of scope

- KotorDiff changes
- Module Designer 3D rotate gizmo

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Preflight requires game_dir, tslpatchdata, and resolvable CLI | Unit test |
| R2 | Standalone `holopatcher` builds positional args + mode flag | Unit test |
| R3 | `python -m holopatcher` module launch supported | Unit test |
| R4 | `run_tool` dry-run returns assembled command | Unit test |
| R5 | Dock exposes validate + install actions | Wiring |
| R6 | Docs mark Q51 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_holo_patcher_tool_bridge.gd
```
