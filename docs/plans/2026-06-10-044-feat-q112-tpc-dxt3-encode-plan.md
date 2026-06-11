---
title: "feat: Q112 native TPC DXT3 encode"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q111-auto-selected
phase: Q112
track: Texture/Media Editing
parent: docs/plans/2026-06-10-018-feat-q86-tpc-dxt-encode-plan.md
related:
  - formats/tpc_dxt_encoder.gd
  - formats/tpc_writer.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q112: Native TPC DXT3 Encode

## Summary

Add CPU **DXT3 (BC2)** mip-0 encoding to close the decode-only gap in `TpcDxtEncoder` / `TPCWriter`, and expose **Re-encode DXT3...** in the TPC workspace editor with TXI preservation.

---

## Problem Frame

`TPCReader` decodes DXT3 but writers only emit RGBA/DXT1/DXT5. Modders with alpha-cutout textures need DXT3 re-encode without PyKotor CLI — deferred since Q86.

---

## Scope Boundaries

### In scope

- `TpcDxtEncoder.encode_dxt3_image()` — explicit 4-bit alpha + DXT1 color blocks
- `TPCWriter.serialize_dxt3()`
- TPC editor **Re-encode DXT3...** + `reencode_loaded_as_dxt3()`
- Headless `test_tpc_dxt_encoder.gd` + `test_tpc_dxt_reencode.gd` extensions
- Loader/saver parity matrix + execution queue Q112 entry

### Deferred

- Batch convert/import DXT3 toolbar paths (Q88/Q89/Q90 parity)
- `TpcBatchConverter` `dxt3` encoding option

### Out of scope

- BC7 / ASTC encoders

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | DXT3 round-trip through writer/reader | `test_tpc_dxt_encoder.gd` |
| R2 | Editor re-encode produces `ENC_DXT3` | `test_tpc_dxt_reencode.gd` |
| R3 | DXT3 re-encode preserves TXI | `test_tpc_dxt_reencode.gd` |
| R4 | Toolbar exposes **Re-encode DXT3...** | Wiring test |
| R5 | Docs mark Q112 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_dxt_encoder.gd
godot --headless --path . --script tests/editor/test_tpc_dxt_reencode.gd
```
