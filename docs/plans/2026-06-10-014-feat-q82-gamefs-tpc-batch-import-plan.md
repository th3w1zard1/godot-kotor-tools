---
title: "feat: Q82 install-scoped GameFS batch TGA/PNG to TPC import"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q81-auto-selected
phase: Q82
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-013-feat-q81-gamefs-tpc-batch-export-plan.md
  - docs/plans/2026-06-07-009-feat-q77-texture-batch-converter-plan.md
---

# Q82: Install-Scoped GameFS Batch TGA/PNG → TPC Import

## Summary

Add **GameFS-scoped batch image→TPC import** so modders can convert indexed override `.tga` files and flat override `.png` files into `.tpc` resources written to the install override folder — complementing Q81's install batch export and Q77's folder-only batch convert.

---

## Problem Frame

Q77 batch-converts images in an arbitrary folder. Modders often drop `.tga`/`.png` directly into override; GameFS indexes `.tga` but not `.png`. They need a one-click path to produce matching `.tpc` files in override without manual per-file import.

---

## Scope Boundaries

### In scope

- `TpcGamefsBatchImporter.batch_install_to_override()` — discover override images, encode RGBA TPC via `TpcBatchConverter`, write `{resref}.tpc` under override
- Discovery: indexed `.tga` via `list_core_resources`; flat override `.png` via directory scan (PNG not in ERF extension map)
- `skip_existing`, `dry_run`, `limit`, optional resref query, `source_filter` (default `override`)
- TPC workspace editor **Batch Import Install TGA/PNG→TPC...** toolbar action with summary status + GameFS refresh
- Headless `tests/editor/test_tpc_gamefs_batch_importer.gd`
- Execution queue + parity matrix Q82 entry

### Deferred

- TXI sidecar pairing in batch
- Recursive subfolder scan
- Mutation preflight per file (batch writes directly; single-file install keeps preflight)
- Indexed sources beyond override (modules/archives)

### Out of scope

- PyKotor CLI texture encode
- Resource browser bulk actions

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `batch_install_to_override` discovers indexed `.tga` and override `.png` | Unit test with seeded override |
| R2 | Each image encodes valid TPC bytes and writes to override in non-dry-run | Unit test |
| R3 | `skip_existing` skips when `{resref}.tpc` already present | Unit test |
| R4 | `dry_run` reports planned conversions without writing | Unit test |
| R5 | TPC editor exposes install batch import button | Wiring test |
| R6 | Docs mark Q82 shipped | Doc diff |

---

## Implementation Units

### U1 — GameFS batch importer

- **Files:** `formats/tpc_gamefs_batch_importer.gd`
- **Pattern:** Mirror `formats/tpc_gamefs_batch_exporter.gd` result shape (`generated`/`skipped`/`failed`/`summary`); encode via `TpcBatchConverter.convert_from_image_file`

### U2 — TPC editor action

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`
- **Pattern:** Q81 install batch export flow without output folder picker; refresh GameFS after apply

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_gamefs_batch_importer.gd`, `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_gamefs_batch_importer.gd
```
