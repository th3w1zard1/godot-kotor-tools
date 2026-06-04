---
title: "feat: Q35 SSF semantic install compare reports"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q34-next-parity-slice
phase: Q35
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-005-feat-q32-semantic-gff-compare-plan.md
---

# Q35: SSF Semantic Install Compare Reports

## Summary

Extend install compare diff reports with slot-level SSF summaries — per-slot StrRef changes with Holocron slot labels — mirroring Q32 GFF compare and existing 2DA/TLK semantic reports.

---

## Problem Frame

Q32 shipped semantic GFF-family compare. SSF install diffs still fall back to binary byte offsets, which is opaque for sound-set modding where only a few of 28 slots change.

---

## Scope Boundaries

### In scope

- `formats/ssf_compare.gd` — slot-level StrRef diff with labeled samples
- Pipeline `_build_difference_report` SSF arm
- Headless `test_ssf_compare.gd`
- Execution queue + parity matrix Q35 entry

### Deferred

- TLK string resolution in compare samples (StrRef labels only)
- LIP/TPC/WAV semantic compare
- KotorDiff UI

### Out of scope

- SSF editor changes
- New SSF mutation APIs

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `SSFCompare.build_difference_report` lists changed slots with labels | `test_ssf_compare.gd` |
| R2 | Invalid SSF bytes return empty (binary fallback) | Unit test |
| R3 | Pipeline routes `ssf` extension through SSF compare | Unit test |
| R4 | Docs mark Q35 shipped | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Compare API | Static `SSFCompare` mirroring `GFFCompare` | Consistent diff tooling pattern |
| Slot labels | Reuse `SSFParser.slot_label()` | Single label source |
| Unassigned StrRef | Treat `-1` as `(none)` in samples | Readable diff lines |

---

## Implementation Units

### U1. SSFCompare

**Files:** `formats/ssf_compare.gd`

### U2. Pipeline wiring

**Files:** `editor/modding/kotor_modding_pipeline.gd`

### U3. Tests + docs

**Files:** `tests/editor/test_ssf_compare.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_ssf_compare.gd
```

---

## Acceptance

- [ ] SSF compare reports slot changes
- [ ] Pipeline wired for `ssf`
- [ ] Tests pass
- [ ] Docs updated
