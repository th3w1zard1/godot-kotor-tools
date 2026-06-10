---
title: "feat: Q77 batch TGA/PNG to TPC converter"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q76-auto-selected
phase: Q77
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-008-feat-q76-resref-references-finder-plan.md
  - docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md
  - docs/plans/2026-06-04-004-feat-q31-batch-lip-generator-plan.md
---

# Q77: Batch TGA/PNG → TPC Converter

## Summary

Ship native batch texture conversion: scan a flat folder of `.tga` and `.png` images, encode each as uncompressed RGBA TPC via `TPCWriter`, and expose **Batch Convert TGA/PNG→TPC...** in the TPC workspace editor.

---

## Problem Frame

Q30 shipped single-image TPC import and Q27 ships per-file PyKotor `texture-convert` export. Holocron/PyKotor texture batch utilities help modders convert many source images into game-ready `.tpc` files without repetitive single-file work. The Godot plugin has no folder-level texture batch path.

---

## Scope Boundaries

### In scope

- `TpcBatchConverter` — single image → TPC bytes + flat directory batch scan
- TPC editor toolbar **Batch Convert TGA/PNG→TPC...** with folder picker and summary status
- Headless `tests/editor/test_tpc_batch_converter.gd`
- Execution queue + parity matrix Q77 entry

### Deferred

- Batch TPC → TGA export via PyKotor CLI (requires CLI per file)
- DXT compression batch encode
- Recursive subfolder scan (flat folder only for v1)
- Auto-install batch output to Override
- TXI sidecar pairing in batch

### Out of scope

- ModuleKit utility
- PyKotor CLI texture batch bridge

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `TpcBatchConverter.convert_from_image_file` returns valid RGBA TPC bytes for PNG | `test_tpc_batch_converter.gd` |
| R2 | `TpcBatchConverter.batch_directory` writes `.tpc` beside each `.tga`/`.png`, skips existing when configured | `test_tpc_batch_converter.gd` |
| R3 | Unsupported/invalid images reported as failed, not silent | Unit test |
| R4 | TPC editor exposes batch folder action | Wiring test |
| R5 | Docs mark Q77 shipped | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Encoding | RGBA uncompressed via `TPCWriter.serialize_rgba` | Matches Q30 single-import path; DXT deferred |
| Extensions | `.png`, `.tga` only (flat folder) | Holocron batch convention; mirrors Q31 flat scan |
| Output location | Same directory, matching basename `.tpc` | Predictable batch output |
| skip_existing | Default true | Safe re-run on partial folders |

---

## Implementation Units

### U1 — TpcBatchConverter

- **Files:** `formats/tpc_batch_converter.gd`

### U2 — TPC editor batch action

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_batch_converter.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
```
