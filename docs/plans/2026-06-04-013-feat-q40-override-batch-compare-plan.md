---
title: "feat: Q40 batch override compare (KotorDiff install scan)"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q39-next-kotordiff-slice
phase: Q40
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-012-feat-q39-indoor-layout-validation-plan.md
  - docs/plans/2026-06-04-005-feat-q32-semantic-gff-compare-plan.md
---

# Q40: Batch Override Compare

## Summary

Add `KotorModdingPipeline.compare_all_overrides` to scan every indexed override resource against its core source, aggregate semantic diff summaries, and expose a **Compare All Overrides** action in the KotOR dock GameFS and workspace sidebars.

---

## Problem Frame

Q32–Q38 shipped per-format semantic compare for single resources. Modders still compare overrides one file at a time. KotorDiff-style workflows need an install-wide scan that lists which override files differ, match, or have no core source.

---

## Scope Boundaries

### In scope

- `compare_all_overrides(gamefs)` in `editor/modding/kotor_modding_pipeline.gd`
- `build_override_compare_report(counts, entries)` formatter
- Dock **Compare All Overrides** buttons (GameFS tab + workspace sidebar)
- Headless `tests/editor/test_override_batch_compare.gd`
- Execution queue + parity matrix Q40 entry

### Deferred

- Save report to disk / export dialog
- Full KotorDiff CLI integration
- Native indoor build

### Out of scope

- HoloPatcher UI
- Changes to single-resource compare semantics

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `compare_all_overrides` returns counts for identical/different/override-only | Unit test |
| R2 | Empty override folder returns ok with zero total | Unit test |
| R3 | Override-only files counted and listed in report | Unit test |
| R4 | Report includes semantic details for differing resources | Unit test (formatter) |
| R5 | Dock Compare All invokes batch compare and shows report | Wiring |
| R6 | Docs mark Q40 shipped | Doc diff |

---

## Implementation Units

### U1. Pipeline batch compare — `editor/modding/kotor_modding_pipeline.gd`

### U2. Dock wiring — `ui/kotor_dock.gd`

### U3. Tests + docs — `tests/editor/test_override_batch_compare.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_override_batch_compare.gd
```
