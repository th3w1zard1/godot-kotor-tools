---
title: "feat: Q46 native indoor ARE builder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q45-next-indoor-native-writer
phase: Q46
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-018-feat-q45-indoor-vis-builder-plan.md
  - docs/plans/2026-06-04-017-feat-q44-indoor-ifo-builder-plan.md
---

# Q46: Native Indoor ARE Builder

## Summary

Add `KotorIndoorAreBuilder` to generate minimal module `.are` GFF from `.indoor` layouts (tag, name, interior flag, ambient lighting, skybox), integrate with the build manifest, and expose **Export ARE Preview** in the Indoor Builder.

---

## Problem Frame

Q43–Q45 generate LYT, IFO, and VIS. Module `.are` files hold area properties consumed with `.git` layout data. This slice adds the first GFF native writer in the indoor build chain, mirroring `KotorIndoorIfoBuilder`.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_are_builder.gd`
- Manifest ARE metadata + Export ARE Preview
- Headless `tests/editor/test_indoor_are_builder.gd`

### Deferred

- GIT native writer
- Full `.mod` assembly
- PyKotor CLI replacement

### Out of scope

- KotorDiff CLI
- Module Designer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | ARE GFF includes Tag, Name, Interior=1 | Unit test |
| R2 | Ambient colors map from `.indoor` lighting RGB | Unit test |
| R3 | SkyBox resref maps from `.indoor` skybox when set | Unit test |
| R4 | Generated ARE round-trips through GFFParser + AREResource | Unit test |
| R5 | Manifest includes ARE build summary | Unit test |
| R6 | Indoor Builder exports `.are` preview file | Wiring |
| R7 | Docs mark Q46 shipped | Doc diff |

---

## Implementation Units

### U1 — ARE builder (`kotor_indoor_are_builder.gd`)

Follow `KotorIndoorIfoBuilder`: build `AREResource`, serialize with `GFFWriter`, return `{ok, bytes, tag, area_name}`.

Map indoor `lighting` `[r,g,b]` to `DynAmbientColor` and `SunAmbientColor` as `Vector3`. Empty skybox → empty `SkyBox` resref.

### U2 — Manifest + UI wiring

Extend `KotorIndoorBuildManifest.build` / `format_report` with `are` block. Add **Export ARE Preview** beside existing export buttons in `indoor_builder_workspace_editor.gd`.

### U3 — Tests + docs

Headless test mirroring `test_indoor_ifo_builder.gd`. Update execution queue and parity matrix.

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_are_builder.gd
```
