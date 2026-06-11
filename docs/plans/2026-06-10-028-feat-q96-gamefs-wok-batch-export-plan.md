---
title: "feat: Q96 install-scoped GameFS WOK batch export"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q95-auto-selected
phase: Q96
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-015-feat-q83-gamefs-mdl-batch-export-plan.md
  - docs/plans/2026-06-10-026-feat-q94-bwm-semantic-compare-plan.md
---

# Q96: Install-Scoped GameFS WOK Batch Export

## Summary

Add **GameFS-scoped batch walkmesh export** so modders can dump indexed override `.wok` resources to a flat folder with vertex/face/walkable summaries — complementing Q94 semantic compare and Module Designer single-file walkmesh export.

---

## Problem Frame

Q94 added WOK semantic compare. Module Designer exports one loaded area walkmesh. Modders need a batch path to extract many override walkmeshes for external tooling without per-file saves.

---

## Scope Boundaries

### In scope

- `BwmGamefsBatchExporter.batch_install()` — enumerate indexed `.wok`, copy bytes to output folder
- `BwmMetadataHelper` summaries via `BWMParser`
- Resource browser **Batch Export Install WOK...**
- Headless `tests/editor/test_bwm_gamefs_batch_exporter.gd`
- Execution queue + parity matrix Q96 entry

### Deferred

- Flat-folder WOK batch copy (filesystem→filesystem)
- WOK batch import to override
- `bwm` extension alias

### Out of scope

- BWM writer / walkmesh editing

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install` discovers indexed `.wok` entries | Unit test |
| R2 | Non-dry-run writes valid `.wok` files | Unit test |
| R3 | `skip_existing` skips destination files | Unit test |
| R4 | Resource browser exposes batch export button | Wiring test |
| R5 | Docs mark Q96 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_exporter.gd
```
