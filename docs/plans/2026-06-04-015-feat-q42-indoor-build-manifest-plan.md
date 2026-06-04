---
title: "feat: Q42 native indoor build manifest preview"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q41-next-indoor-native-slice
phase: Q42
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-012-feat-q39-indoor-layout-validation-plan.md
  - docs/plans/2026-05-29-030-feat-q25-indoor-mod-export-plan.md
---

# Q42: Native Indoor Build Manifest

## Summary

Add `KotorIndoorBuildManifest` to enumerate the core module resources and per-room assets a native `IndoorMap.build()` would emit from a validated layout, plus an Indoor Builder **Build Preview** action.

---

## Problem Frame

Q39 validates layouts before PyKotor CLI export. Q25 still depends entirely on external `indoor-build`. The next step toward native indoor build is a headless manifest describing expected module outputs without porting full ARE/GIT/IFO generation.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_build_manifest.gd`
- Indoor Builder **Build Preview** toolbar button + detail report
- Headless `tests/editor/test_indoor_build_manifest.gd`
- Execution queue + parity matrix Q42 entry

### Deferred

- Full native `IndoorMap.build()` resource writers
- Replacing PyKotor CLI export
- 3D rotate gizmo / LYT depth

### Out of scope

- KotorDiff CLI
- HoloPatcher UI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Manifest fails when layout validation fails | Unit test |
| R2 | Valid layout lists core module files (`are/git/ifo/lyt/vis`) | Unit test |
| R3 | Per-room MDL/WOK asset entries derived from kit components | Unit test |
| R4 | `format_report` renders human-readable summary | Unit test |
| R5 | Indoor Builder Build Preview shows manifest or validation errors | Wiring |
| R6 | Docs mark Q42 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_build_manifest.gd
```
