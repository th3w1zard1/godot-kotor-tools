---
title: "feat: Q48 native indoor MOD builder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q47-next-indoor-native-slice
phase: Q48
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-020-feat-q47-indoor-git-builder-plan.md
  - docs/plans/2026-06-04-015-feat-q42-indoor-build-manifest-plan.md
  - docs/plans/2026-05-29-030-feat-q25-indoor-mod-export-plan.md
---

# Q48: Native Indoor MOD Builder

## Summary

Add `KotorIndoorModBuilder` to assemble native indoor module outputs (LYT/IFO/VIS/ARE/GIT + kit room assets) into a `.mod` ERF via `ERFWriter`, integrate with the build manifest, and expose **Export Native MOD Preview** in the Indoor Builder.

---

## Problem Frame

Q43–Q47 shipped all core native writers. Q25 still depends on PyKotor CLI for `.mod` export. This slice packs the native writers into a loadable `.mod` without external tooling.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_mod_builder.gd`
- Manifest MOD metadata + Export Native MOD Preview
- Headless `tests/editor/test_indoor_mod_builder.gd`

### Deferred

- Embedded-component MDL/WOK binary generation
- Replacing PyKotor CLI export button
- KotorDiff CLI

### Out of scope

- Module Designer changes
- HoloPatcher UI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Build fails when layout validation or any core writer fails | Unit test |
| R2 | MOD contains all five core module resources | Unit test |
| R3 | Kit room `.wok`/`.mdl`/`.mdx` copied from kits path when present | Unit test |
| R4 | Generated MOD round-trips through `ERFParser` | Unit test |
| R5 | Manifest includes MOD build summary | Unit test |
| R6 | Indoor Builder exports native `.mod` preview file | Wiring |
| R7 | Docs mark Q48 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_mod_builder.gd
```
