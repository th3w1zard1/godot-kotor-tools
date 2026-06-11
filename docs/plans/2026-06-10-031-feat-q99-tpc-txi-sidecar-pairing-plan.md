---
title: "feat: Q99 TPC TXI sidecar pairing on image import"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q98-auto-selected
phase: Q99
track: Advanced Utility Tools
parent: docs/plans/2026-06-10-030-feat-q98-bwm-batch-folder-import-override-plan.md
related:
  - formats/tpc_batch_converter.gd
  - formats/tpc_writer.gd
  - formats/tpc_gamefs_batch_importer.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q99: TPC TXI Sidecar Pairing on Image Import

## Summary

When converting `foo.png`/`foo.tga` to TPC, append sibling `foo.txi` bytes to the TPC tail so batch convert, GameFS batch import, and single-file TPC editor import preserve texture metadata parity with PyKotor/Holocron workflows.

---

## Problem Frame

Q77/Q82/Q88/Q89 deferred TXI sidecar pairing. `TPCReader.read_metadata` already reports `txi_length`, but `TPCWriter` and `TpcBatchConverter` omit TXI tails on fresh encodes. Modders keeping `.txi` beside source images lose metadata on import.

---

## Scope Boundaries

### In scope

- `TPCWriter.append_txi_bytes(tpc_bytes, txi_bytes)` — validate TPC header, append tail after mip payload
- `TPCWriter.read_txi_bytes(tpc_bytes)` — extract tail for tests
- `TpcBatchConverter.attach_txi_sidecar(image_path, tpc_bytes, options)` — read `{basename}.txi` when present; `include_txi_sidecar` option (default `true`)
- Wire through `convert_from_image_file` and `batch_directory`
- `tpc_workspace_editor.gd` `_load_image_as_tpc` — attach TXI after encode (inherits via shared helper)
- Headless tests in `tests/editor/test_tpc_writer.gd` and `tests/editor/test_tpc_batch_converter.gd`
- Execution queue + parity matrix Q99 entry

### Deferred

- TXI editing UI in TPC editor
- `TPCCompare` TXI line-by-line diff (Q37 scope)
- Recursive subfolder scan

### Out of scope

- DXT3 encode
- PyKotor CLI `--txi` bridge changes (native path only)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `append_txi_bytes` produces valid TPC with non-zero `txi_length` | `test_tpc_writer.gd` |
| R2 | `convert_from_image_file` attaches sibling `.txi` when present | `test_tpc_batch_converter.gd` |
| R3 | `include_txi_sidecar: false` skips TXI attach | `test_tpc_batch_converter.gd` |
| R4 | Missing `.txi` leaves encode unchanged (zero `txi_length`) | `test_tpc_batch_converter.gd` |
| R5 | `batch_directory` writes TPC files with TXI tails | `test_tpc_batch_converter.gd` |
| R6 | Docs mark Q99 shipped | Doc diff |

---

## Implementation Units

### U1: `TPCWriter` TXI tail helpers

- `formats/tpc_writer.gd`
- Append after `HEADER_SIZE + data_size`; reject invalid TPC input
- `read_txi_bytes` slices tail for assertions

### U2: `TpcBatchConverter` sidecar wiring

- `formats/tpc_batch_converter.gd`
- `_txi_path_for_image(image_path)` → `{basename}.txi`
- Call attach after `_serialize_image` in `convert_from_image_file`

### U3: TPC editor single-file import

- `ui/workspace/editors/tpc_workspace_editor.gd`
- After encode in `_load_image_as_tpc`, call `TpcBatchConverter.attach_txi_sidecar(path, bytes)` or equivalent static helper

### U4: Tests + docs

- Extend `tests/editor/test_tpc_writer.gd`, `tests/editor/test_tpc_batch_converter.gd`
- Update `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_writer.gd
godot --headless --path . --script tests/editor/test_tpc_batch_converter.gd
```
