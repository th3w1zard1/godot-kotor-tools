---
title: "feat: Q44 native indoor IFO builder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q43-next-indoor-native-writer
phase: Q44
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-016-feat-q43-indoor-lyt-builder-plan.md
---

# Q44: Native Indoor IFO Builder

## Summary

Add `KotorIndoorIfoBuilder` to generate a minimal module `.ifo` GFF from indoor layouts, integrate with the build manifest, and expose **Export IFO Preview** in the Indoor Builder.

---

## Problem Frame

Q43 generates LYT from room placements. Indoor `.mod` builds also require an IFO with module identity and starting area list. This slice adds the second native resource writer toward replacing PyKotor `indoor-build`.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_ifo_builder.gd`
- Manifest IFO metadata + report line
- Indoor Builder **Export IFO Preview**
- Headless `tests/editor/test_indoor_ifo_builder.gd`
- Execution queue + parity matrix Q44 entry

### Deferred

- ARE/GIT/VIS native writers
- Full `.mod` container assembly
- PyKotor CLI replacement

### Out of scope

- KotorDiff CLI
- Module Designer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Builder sets Mod_Name, Mod_Tag, Mod_ResRef from module id | Unit test |
| R2 | Mod_Area_list contains one entry for the module area | Unit test |
| R3 | Serialized IFO round-trips through GFFParser + IFOResource | Unit test |
| R4 | Manifest includes IFO build summary | Unit test |
| R5 | Indoor Builder exports `.ifo` preview file | Wiring |
| R6 | Docs mark Q44 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_ifo_builder.gd
```
