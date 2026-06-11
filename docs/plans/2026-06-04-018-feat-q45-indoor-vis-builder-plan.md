---
title: "feat: Q45 native indoor VIS builder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q44-next-indoor-native-writer
phase: Q45
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-017-feat-q44-indoor-ifo-builder-plan.md
  - docs/plans/2026-06-04-016-feat-q43-indoor-lyt-builder-plan.md
---

# Q45: Native Indoor VIS Builder

## Summary

Add `VISParser` and `KotorIndoorVisBuilder` to generate KotOR ASCII `.vis` room visibility from indoor hook connections, integrate with the build manifest, and expose **Export VIS Preview** in the Indoor Builder.

---

## Problem Frame

Q43–Q44 generate LYT and IFO. Module `.vis` files drive room-to-room occlusion culling and pair with LYT room names. This slice adds the third ASCII native writer using hook connection adjacency.

---

## Scope Boundaries

### In scope

- `formats/vis_parser.gd`
- `resources/indoor/kotor_indoor_vis_builder.gd`
- `KotorIndoorDocument.get_visible_room_indices()`
- Manifest VIS metadata + Export VIS Preview
- Headless `tests/editor/test_indoor_vis_builder.gd`

### Deferred

- ARE/GIT native writers
- Full `.mod` assembly
- PyKotor CLI replacement

### Out of scope

- KotorDiff CLI
- Module Designer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | VIS text uses parent/child ASCII layout | Unit test |
| R2 | Each room lists itself plus hook-connected neighbors | Unit test |
| R3 | Generated VIS round-trips through `VISParser` | Unit test |
| R4 | Manifest includes VIS build summary | Unit test |
| R5 | Indoor Builder exports `.vis` preview file | Wiring |
| R6 | Docs mark Q45 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_vis_builder.gd
```
