---
title: "feat: Q32 semantic GFF compare reports for install diff"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q30-next-parity-slice
phase: Q32
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-28-017-feat-openkotor-parity-program-plan.md
---

# Q32: Semantic GFF Compare Reports

## Summary

Extend install compare so GFF-family resources (including DLG) produce field-level difference summaries instead of binary-only first-byte offsets, matching existing 2DA/TLK semantic compare behavior in `KotorModdingPipeline`.

---

## Problem Frame

`compare_gamefs_resource` already reports semantic diffs for 2DA and TLK. GFF-family overrides (DLG, UTC, ARE, etc.) fall back to `_build_binary_difference_report`, which tells modders little about what changed. Holocron/KotorDiff parity backlog calls for richer diff visibility.

---

## Scope Boundaries

### In scope

- `formats/gff_compare.gd` — recursive root/list/scalar diff with sample limit
- Wire GFF extensions into `_build_difference_report`
- DLG-specific list count summary (EntryList, ReplyList, StartingList)
- Headless tests with synthetic/minimal GFF bytes

### Deferred

- Full KotorDiff CLI integration
- Side-by-side compare UI dialog
- Deep nested list field-by-field for large GIT/ARE files (sample cap only)

### Out of scope

- HoloPatcher apply flows
- Three-way merge

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | GFF compare returns non-empty semantic report when root scalars differ | `test_gff_compare.gd` |
| R2 | DLG compare includes EntryList/ReplyList count deltas when list sizes differ | `test_gff_compare.gd` |
| R3 | Invalid GFF bytes fall back to binary report via empty semantic result | Pipeline behavior |
| R4 | Resource browser compare shows semantic details for `.dlg` overrides | Existing detail panel path |
| R5 | Execution queue + parity matrix note Q32 | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Module location | `formats/gff_compare.gd` | Keeps pipeline thin; testable standalone |
| Sample limit | 5 paths (reuse `DETAIL_SAMPLE_LIMIT`) | Matches 2DA/TLK compare style |
| List diff | Size mismatch + per-index struct scalar diff | Bounded cost on large GIT files |
| LocString diff | Compare strref + English string if present | Actionable for dialogue edits |

---

## Implementation Units

### U1. GFFCompare helper

**Files:** `formats/gff_compare.gd`

### U2. Pipeline wiring

**Files:** `editor/modding/kotor_modding_pipeline.gd`

### U3. Tests

**Files:** `tests/editor/test_gff_compare.gd`

### U4. Docs

**Files:** execution queue, parity matrix (diff tooling partial)

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_gff_compare.gd
```
