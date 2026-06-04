---
title: "feat: Q43 native indoor LYT builder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q42-next-indoor-native-writer
phase: Q43
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-015-feat-q42-indoor-build-manifest-plan.md
---

# Q43: Native Indoor LYT Builder

## Summary

Add `KotorIndoorLyTBuilder` to generate KotOR-compatible `.lyt` ASCII from indoor room placements, wire it into the build manifest, and expose **Export LYT Preview** in the Indoor Builder.

---

## Problem Frame

Q42 lists `module.lyt` in the build manifest but does not generate it. Native indoor build needs resource writers starting with LYT room model placement — the simplest format already parsed by `LYTParser`.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_lyt_builder.gd`
- Manifest includes LYT build metadata
- Indoor Builder **Export LYT Preview** save action
- Headless `tests/editor/test_indoor_lyt_builder.gd`
- Execution queue + parity matrix Q43 entry

### Deferred

- IFO/ARE/GIT native writers
- Door hook lines in LYT output
- Replacing PyKotor CLI export

### Out of scope

- KotorDiff CLI
- Module Designer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Builder emits `beginlayout` / `roomcount` / `roommodel` / `donelayout` | Unit test |
| R2 | Generated LYT round-trips through `LYTParser` with matching room count/positions | Unit test |
| R3 | Builder errors when document has no rooms | Unit test |
| R4 | Build manifest includes LYT build summary | Unit test |
| R5 | Indoor Builder exports `.lyt` preview file | Wiring |
| R6 | Docs mark Q43 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_lyt_builder.gd
```
