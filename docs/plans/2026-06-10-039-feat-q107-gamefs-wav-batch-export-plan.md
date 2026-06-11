---
title: "feat: Q107 install-scoped GameFS WAV batch export"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q106-auto-selected
phase: Q107
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-038-feat-q106-gamefs-wav-batch-convert-plan.md
related:
  - docs/plans/2026-06-10-028-feat-q96-gamefs-wok-batch-export-plan.md
  - formats/wav_gamefs_batch_importer.gd
  - ui/workspace/editors/wav_workspace_editor.gd
---

# Q107: Install-Scoped GameFS WAV Batch Export

## Summary

Add **GameFS-scoped batch WAV export** so modders can dump indexed override `.wav` resources to a flat filesystem folder with `WavMetadata` summaries — completing the deferred Q106 export path and mirroring Q96 WOK batch export.

---

## Problem Frame

Q106 converts override WAVs in-place via PyKotor. Q104 imports external folders. Modders still need a batch path to **extract** indexed override WAV bytes to an external folder for auditing, diffing, or external tooling — symmetric with `BwmGamefsBatchExporter` and `TpcGamefsBatchExporter`.

---

## Scope Boundaries

### In scope

- `WavGamefsBatchExporter.batch_install()` — enumerate indexed `.wav`, copy bytes to output folder
- `WavMetadata.parse_bytes` summaries on generated records
- WAV workspace editor **Batch Export Install WAV...** (output folder picker)
- Headless `tests/editor/test_wav_gamefs_batch_exporter.gd`
- Execution queue + parity matrix Q107 entry

### Deferred

- Recursive subfolder scan
- Resource browser duplicate button (WAV editor is canonical surface for WAV batch tooling)
- Export with PyKotor re-encode (raw byte copy only)

### Out of scope

- WAV editing / native encode

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install` discovers indexed `.wav` entries | Unit test |
| R2 | Non-dry-run writes valid `.wav` files | Unit test |
| R3 | `skip_existing` skips destination files | Unit test |
| R4 | Generated records include duration/channels metadata | Unit test |
| R5 | WAV editor exposes batch export button | Wiring test |
| R6 | Docs mark Q107 shipped | Doc diff |

---

## Implementation Units

| Unit | Files |
| --- | --- |
| U1 Exporter | `formats/wav_gamefs_batch_exporter.gd` |
| U2 Editor wiring | `ui/workspace/editors/wav_workspace_editor.gd` |
| U3 Tests | `tests/editor/test_wav_gamefs_batch_exporter.gd` |
| U4 Docs | `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md` |

---

## Pattern Reference

Follow `formats/bwm_gamefs_batch_exporter.gd` for `batch_install` options (`skip_existing`, `dry_run`, `source_filter`, `query`, `limit`) and `format_report`.

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_wav_gamefs_batch_exporter.gd
```
