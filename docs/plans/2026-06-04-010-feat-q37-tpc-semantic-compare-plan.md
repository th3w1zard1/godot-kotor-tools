---
title: "feat: Q37 TPC semantic install compare reports"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q36-next-parity-slice
phase: Q37
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-008-feat-q35-ssf-semantic-compare-plan.md
  - docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md
---

# Q37: TPC Semantic Install Compare Reports

## Summary

Extend install compare diff reports with TPC header summaries — dimensions, encoding, mip count, alpha test, and payload size — using existing `TPCReader.read_metadata`, completing the media-format diff tooling wave (SSF/LIP/TPC).

---

## Problem Frame

Q35–Q36 added SSF and LIP semantic compare. TPC install diffs still fall back to binary byte offsets despite readable 128-byte headers modders inspect in the TPC workspace editor.

---

## Scope Boundaries

### In scope

- `formats/tpc_compare.gd` — header metadata diff + payload mismatch line when headers match
- Pipeline `_build_difference_report` `tpc` arm
- Headless `test_tpc_compare.gd`
- Execution queue + parity matrix Q37 entry

### Deferred

- Per-pixel / decoded image diff
- TXI text body line-by-line compare
- KotorDiff UI

### Out of scope

- TPC editor changes
- DXT encode (separate backlog)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `TPCCompare.build_difference_report` reports header field changes | `test_tpc_compare.gd` |
| R2 | Identical metadata + differing payload reports pixel payload line | Unit test |
| R3 | Invalid TPC bytes return empty (binary fallback) | Unit test |
| R4 | Pipeline routes `tpc` extension through TPC compare | Unit test |
| R5 | Docs mark Q37 shipped | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Metadata source | `TPCReader.read_metadata()` | Already used by editor/tests |
| Payload diff | Single summary line when headers match | Avoid decoding DXT in compare path |
| Float compare | `is_equal_approx` for `alpha_test` | Match LIP compare pattern |

---

## Implementation Units

### U1. TPCCompare

**Files:** `formats/tpc_compare.gd`

### U2. Pipeline wiring

**Files:** `editor/modding/kotor_modding_pipeline.gd`

### U3. Tests + docs

**Files:** `tests/editor/test_tpc_compare.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_compare.gd
```

---

## Acceptance

- [ ] TPC compare reports header/payload changes
- [ ] Pipeline wired for `tpc`
- [ ] Tests pass
- [ ] Docs updated
