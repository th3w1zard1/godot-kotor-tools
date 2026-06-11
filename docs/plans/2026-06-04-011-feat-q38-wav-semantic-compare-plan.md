---
title: "feat: Q38 WAV semantic install compare reports"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q37-next-parity-slice
phase: Q38
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-010-feat-q37-tpc-semantic-compare-plan.md
---

# Q38: WAV Semantic Install Compare Reports

## Summary

Add WAV install compare summaries using `WavMetadata` — format, channels, sample rate, duration, and payload size — completing semantic diff coverage for shipped media formats (SSF/LIP/TPC/WAV).

---

## Problem Frame

Q35–Q37 added SSF, LIP, and TPC semantic compare. WAV install diffs still report binary byte offsets despite shared `WavMetadata` already powering the WAV workspace editor and LIP tooling.

---

## Scope Boundaries

### In scope

- `formats/wav_compare.gd`
- Pipeline `_build_difference_report` `wav` arm
- Headless `test_wav_compare.gd`
- Execution queue + parity matrix Q38 entry

### Deferred

- PCM sample-by-sample diff
- PyKotor sound-convert integration in compare path
- KotorDiff UI

### Out of scope

- WAV editor changes
- New WAV mutation APIs

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `WavCompare.build_difference_report` reports format/channel/rate/duration changes | `test_wav_compare.gd` |
| R2 | Identical metadata + differing payload reports audio payload line | Unit test |
| R3 | Invalid WAV bytes return empty (binary fallback) | Unit test |
| R4 | Pipeline routes `wav` extension through WAV compare | Unit test |
| R5 | Docs mark Q38 shipped | Doc diff |

---

## Implementation Units

### U1. WavCompare — `formats/wav_compare.gd`

### U2. Pipeline wiring — `editor/modding/kotor_modding_pipeline.gd`

### U3. Tests + docs — `tests/editor/test_wav_compare.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_compare.gd
```
