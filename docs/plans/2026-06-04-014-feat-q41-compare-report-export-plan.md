---
title: "feat: Q41 compare report export to disk"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q40-next-kotordiff-slice
phase: Q41
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-013-feat-q40-override-batch-compare-plan.md
---

# Q41: Compare Report Export

## Summary

Let modders save single-resource and batch override compare reports to a `.txt` file via the KotOR dock, completing the deferred Q40 export path toward KotorDiff-style workflows.

---

## Problem Frame

Q40 added install-wide override scanning with in-dock reports and activity log output. Modders still cannot persist compare output for sharing, review, or diff archives. Q40 explicitly deferred save-to-disk.

---

## Scope Boundaries

### In scope

- `export_text_report_to_path` and `export_compare_result_to_path` on `KotorModdingPipeline`
- Dock **Export Compare Report…** (GameFS tab + workspace sidebar) using last compare output
- Headless `tests/editor/test_compare_report_export.gd`
- Execution queue + parity matrix Q41 entry

### Deferred

- Full KotorDiff CLI integration
- Native indoor build
- Auto-prompt save after every compare

### Out of scope

- HTML/JSON report formats
- HoloPatcher UI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `export_text_report_to_path` writes UTF-8 text and returns structured result | Unit test |
| R2 | Empty path or empty text returns error | Unit test |
| R3 | `export_compare_result_to_path` uses result details/message | Unit test |
| R4 | Dock stores last compare report and exports via file dialog | Wiring |
| R5 | Docs mark Q41 shipped | Doc diff |

---

## Implementation Units

### U1. Pipeline export helpers — `editor/modding/kotor_modding_pipeline.gd`

### U2. Dock wiring — `ui/kotor_dock.gd`

### U3. Tests + docs

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_compare_report_export.gd
```
