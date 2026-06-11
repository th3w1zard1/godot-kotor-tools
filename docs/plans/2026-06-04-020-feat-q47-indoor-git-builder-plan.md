---
title: "feat: Q47 native indoor GIT builder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q46-next-indoor-native-writer
phase: Q47
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-019-feat-q46-indoor-are-builder-plan.md
  - docs/plans/2026-06-04-018-feat-q45-indoor-vis-builder-plan.md
---

# Q47: Native Indoor GIT Builder

## Summary

Add `KotorIndoorGitBuilder` to generate module `.git` GFF from `.indoor` hook connections (door instances at connected hooks), integrate with the build manifest, and expose **Export GIT Preview** in the Indoor Builder.

---

## Problem Frame

Q43–Q46 generate LYT, IFO, VIS, and ARE. Module `.git` files hold area instance layout; indoor modules place **doors** at hook connection points. This slice completes the core GFF native writer pair (ARE + GIT) for the indoor build chain.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_git_builder.gd`
- Manifest GIT metadata + Export GIT Preview
- Headless `tests/editor/test_indoor_git_builder.gd`

### Deferred

- Creature/placeable GIT instances from indoor data
- Full `.mod` assembly
- PyKotor CLI replacement

### Out of scope

- KotorDiff CLI
- Module Designer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | GIT includes standard instance lists (empty except doors) | Unit test |
| R2 | One door per deduplicated hook connection at world position | Unit test |
| R3 | Generated GIT round-trips through GFFParser + GITResource | Unit test |
| R4 | Manifest includes GIT build summary | Unit test |
| R5 | Indoor Builder exports `.git` preview file | Wiring |
| R6 | Docs mark Q47 shipped | Doc diff |

---

## Implementation Units

### U1 — GIT builder (`kotor_indoor_git_builder.gd`)

Follow `KotorIndoorAreBuilder` / module designer GIT schema. Emit empty lists for all `KotorGITDocument.LIST_FIELDS` categories except **Door List**, populated from `get_room_records()` hook markers (dedupe when `room_index < connected_room`).

### U2 — Manifest + UI wiring

Extend `KotorIndoorBuildManifest` and Indoor Builder **Export GIT Preview**.

### U3 — Tests + docs

Mirror `test_indoor_are_builder.gd` patterns with embedded connected-room fixture.

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_git_builder.gd
```
