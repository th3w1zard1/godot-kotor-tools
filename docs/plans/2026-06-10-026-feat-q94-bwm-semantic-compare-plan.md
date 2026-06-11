---
title: "feat: Q94 BWM/WOK semantic compare"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q93-auto-selected
phase: Q94
track: Patching/Diff Tooling
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-023-feat-q91-mdl-semantic-compare-plan.md
  - formats/bwm_parser.gd
---

# Q94: BWM/WOK Semantic Compare

## Summary

Add `BwmCompare` so GameFS override compare reports walkmesh geometry deltas for `.wok` overrides instead of opaque binary diffs.

---

## Problem Frame

Q91 shipped MDL semantic compare. Area walkmesh overrides (`.wok`) still fall through to binary diff, hiding vertex/face/material changes modders care about when tuning navigation.

---

## Scope Boundaries

### In scope

- `formats/bwm_compare.gd` with `build_difference_report(base_bytes, mod_bytes)`
- Wire `wok` extension in `KotorModdingPipeline._build_difference_report`
- Headless `tests/editor/test_bwm_compare.gd`
- Execution queue + parity matrix Q94 entry

### Deferred

- Per-face material diff sampling
- `bwm` extension alias (GameFS indexes `wok` only)

### Out of scope

- BWM writer changes
- Walkmesh mutation compare beyond metadata

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Vertex count change produces semantic report | Unit test |
| R2 | Walkable face count change produces semantic report | Unit test |
| R3 | Identical bytes return empty report | Unit test |
| R4 | Invalid bytes fall back (empty report) | Unit test |
| R5 | Pipeline routes `wok` to `BwmCompare` | Wiring test |
| R6 | Docs mark Q94 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_compare.gd
```
