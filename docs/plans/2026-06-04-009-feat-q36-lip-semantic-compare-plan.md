---
title: "feat: Q36 LIP semantic install compare reports"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q35-next-parity-slice
phase: Q36
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-008-feat-q35-ssf-semantic-compare-plan.md
---

# Q36: LIP Semantic Install Compare Reports

## Summary

Extend install compare diff reports with LIP summaries — duration, keyframe count, and per-keyframe time/shape changes with viseme labels — continuing the Q32/Q35 semantic diff tooling wave.

---

## Problem Frame

Q35 added SSF slot-level compare. LIP install diffs still report opaque binary offsets despite a simple V1.0 keyframe structure modders edit in the LIP Sync workspace.

---

## Scope Boundaries

### In scope

- `formats/lip_compare.gd` — duration + keyframe diff with labeled samples
- Pipeline `_build_difference_report` `lip` arm
- Headless `test_lip_compare.gd`
- Execution queue + parity matrix Q36 entry

### Deferred

- Per-keyframe added/removed beyond pairwise index diff (count line covers size mismatch)
- TPC metadata compare
- KotorDiff UI

### Out of scope

- LIP editor changes
- New LIP mutation APIs

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `LIPCompare.build_difference_report` reports length/keyframe changes | `test_lip_compare.gd` |
| R2 | Invalid LIP bytes return empty (binary fallback) | Unit test |
| R3 | Pipeline routes `lip` extension through LIP compare | Unit test |
| R4 | Docs mark Q36 shipped | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Compare API | Static `LIPCompare` mirroring `SSFCompare` | Consistent diff tooling pattern |
| Keyframe diff | Pairwise on sorted keyframes after parse | Parser already sorts |
| Float compare | `is_equal_approx` for duration/time | Avoid float noise in reports |

---

## Implementation Units

### U1. LIPCompare

**Files:** `formats/lip_compare.gd`

### U2. Pipeline wiring

**Files:** `editor/modding/kotor_modding_pipeline.gd`

### U3. Tests + docs

**Files:** `tests/editor/test_lip_compare.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_lip_compare.gd
```

---

## Acceptance

- [ ] LIP compare reports duration/keyframe changes
- [ ] Pipeline wired for `lip`
- [ ] Tests pass
- [ ] Docs updated
