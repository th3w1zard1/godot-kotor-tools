---
title: "feat: Q49 KotorDiff CLI bridge"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q48-next-kotordiff-slice
phase: Q49
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-014-feat-q41-compare-report-export-plan.md
  - docs/plans/2026-06-04-013-feat-q40-override-batch-compare-plan.md
---

# Q49: KotorDiff CLI Bridge

## Summary

Add `KotorDiffToolBridge` to invoke standalone `kotordiff` or PyKotor `diff` from the editor, with dock wiring for install/directory comparison and headless command tests.

---

## Problem Frame

Q40–Q41 shipped native override compare and report export. Full KotorDiff CLI workflows (install-vs-install, directory diffs, PyKotor log output) still require leaving the editor. This slice adds a PyKotor-style CLI bridge matching `KotorScriptToolBridge`.

---

## Scope Boundaries

### In scope

- `resources/diff/kotor_diff_tool_bridge.gd`
- GameFS dock **Run KotorDiff CLI…** (path1 defaults to game install)
- Headless `tests/editor/test_kotor_diff_tool_bridge.gd`
- Execution queue + parity matrix Q49 entry

### Deferred

- GUI kotordiff launcher
- TSLPatcher `--tslpatchdata` / `--incremental` UI
- HoloPatcher integration

### Out of scope

- Replacing native compare (Q40)
- Indoor native build

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Preflight requires path1, path2, and resolvable CLI | Unit test |
| R2 | Standalone `kotordiff` builds `--path1` / `--path2` / `--output-log` | Unit test |
| R3 | PyKotor CLI builds `diff` subcommand with same path flags | Unit test |
| R4 | `run_tool` dry-run returns assembled command | Unit test |
| R5 | Dock exposes Run KotorDiff CLI action | Wiring |
| R6 | Docs mark Q49 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_kotor_diff_tool_bridge.gd
```
