---
title: "feat: Q103 BWM .bwm extension alias"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q102-auto-selected
phase: Q103
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-030-feat-q98-bwm-batch-folder-import-override-plan.md
related:
  - formats/bwm_batch_exporter.gd
  - formats/bwm_gamefs_batch_importer.gd
  - resources/indoor/kotor_indoor_embedded_asset_generator.gd
---

# Q103: BWM `.bwm` Extension Alias

## Summary

Accept `.bwm` as an input alias for walkmesh batch copy/import workflows, normalizing output to canonical `.wok` files — matching PyKotor/Holocron and `KotorIndoorEmbeddedAssetGenerator` (`bwm` → `wok`).

---

## Problem Frame

Q97–Q98 shipped flat-folder WOK batch export/import but only scan `.wok` sources. Toolchains and kit exports often emit `.bwm` files with identical BWM payload. Modders must manually rename before batch import to override.

---

## Scope Boundaries

### In scope

- `BwmBatchExporter.batch_directory` accepts `.wok` and `.bwm` inputs
- Destination files always use `.wok` extension (install-canonical)
- `skip_existing` checks normalized `{resref}.wok` destination
- `BwmGamefsBatchImporter` inherits behavior via batch exporter delegate
- Headless tests for `.bwm` → `.wok` copy and skip-existing
- Execution queue + parity matrix Q103 entry

### Deferred

- GameFS index `bwm` extension (install indexes `wok` only)
- Recursive subfolder scan

### Out of scope

- BWM compare extension alias (compare loads bytes by GameFS entry)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `.bwm` sources included in batch_directory scan | Unit test |
| R2 | `.bwm` input writes `{resref}.wok` to output | Unit test |
| R3 | `skip_existing` skips when normalized `.wok` dest exists | Unit test |
| R4 | GameFS batch import to override normalizes `.bwm` | Unit test |
| R5 | Docs mark Q103 shipped | Doc diff |

---

## Implementation Units

### U1: `formats/bwm_batch_exporter.gd`

- Add walkmesh source extension set (`wok`, `bwm`)
- Normalize destination to `{resref}.wok`
- Update class/doc comments

### U2: Tests

- `tests/editor/test_bwm_batch_exporter.gd` — `.bwm` dry-run, write, skip-existing
- `tests/editor/test_bwm_gamefs_batch_importer.gd` — override import from `.bwm` folder

### U3: Docs

- `docs/50-execution/godot-capability-execution-queue.md`
- `docs/30-gap-analysis/openkotor-parity-matrix.md`

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_batch_exporter.gd
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_importer.gd
```
