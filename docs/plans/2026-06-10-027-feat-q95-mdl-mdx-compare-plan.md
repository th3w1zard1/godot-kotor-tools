---
title: "feat: Q95 MDL compare with MDX sidecar pairing"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q94-auto-selected
phase: Q95
track: Patching/Diff Tooling
parent: docs/plans/2026-06-10-023-feat-q91-mdl-semantic-compare-plan.md
related:
  - formats/mdl_compare.gd
  - editor/modding/kotor_modding_pipeline.gd
---

# Q95: MDL Compare with MDX Sidecar Pairing

## Summary

Extend `MdlCompare` and GameFS compare wiring so MDL override diffs load paired `.mdx` sidecars per source and report MDX presence/size/payload changes.

---

## Problem Frame

Q91 deferred MDX pairing. MDL-only compare misses overrides where geometry metadata matches but the MDX sidecar changed or was added/removed.

---

## Scope Boundaries

### In scope

- `MdlCompare.build_difference_report(base_mdl, mod_mdl, base_mdx, mod_mdx)` optional MDX args
- `compare_gamefs_resource` loads MDX from matching source for core/override entries
- MDX presence, size, and payload diff samples in report
- Pass MDX into `MdlModelMetadataHelper.summarize_bytes` when present
- Extend `tests/editor/test_mdl_compare.gd` with MDX unit + GameFS wiring tests
- Execution queue + parity matrix Q95 entry

### Deferred

- Per-vertex MDX payload sampling
- MDX-only override compare (no `.mdl` override row)

### Out of scope

- MDL writer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | MDX size change on identical MDL produces semantic report | Unit test |
| R2 | MDX presence change (absent/present) reported | Unit test |
| R3 | GameFS compare loads paired MDX per source | Integration test |
| R4 | Identical MDL+MDX returns empty report | Unit test |
| R5 | Docs mark Q95 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_compare.gd
```
