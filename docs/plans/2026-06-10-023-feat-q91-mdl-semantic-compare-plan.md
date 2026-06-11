---
title: "feat: Q91 MDL semantic compare"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q90-auto-selected
phase: Q91
track: Patching/Diff Tooling
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-010-feat-q37-tpc-semantic-compare-plan.md
  - editor/tools/mdl_model_metadata_helper.gd
---

# Q91: MDL Semantic Compare

## Summary

Add `MdlCompare` so GameFS override compare reports vertex/face/bounds deltas for `.mdl` overrides instead of opaque binary diffs.

---

## Problem Frame

Q32–Q38 shipped semantic compare for GFF/SSF/LIP/TPC/WAV. MDL overrides still fall through to `_build_binary_difference_report`, hiding whether geometry changed.

---

## Scope Boundaries

### In scope

- `formats/mdl_compare.gd` with `build_difference_report(base_mdl, mod_mdl)`
- Wire `mdl` extension in `KotorModdingPipeline._build_difference_report`
- Headless `tests/editor/test_mdl_compare.gd`
- Execution queue + parity matrix Q91 entry

### Deferred

- MDX sidecar pairing in compare (MDL-only metadata for now)
- Full mesh vertex diff sampling

### Out of scope

- MDL writer / mutation compare beyond metadata

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Vertex count change produces semantic report | Unit test |
| R2 | Identical MDL bytes return empty report | Unit test |
| R3 | Invalid MDL falls back (empty report) | Unit test |
| R4 | Pipeline routes `mdl` to `MdlCompare` | Wiring test |
| R5 | Docs mark Q91 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_compare.gd
```
