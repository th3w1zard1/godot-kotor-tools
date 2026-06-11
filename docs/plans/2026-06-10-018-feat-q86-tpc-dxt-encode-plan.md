---
title: "feat: Q86 native TPC DXT encode"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q85-auto-selected
phase: Q86
track: Texture/Media Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md
  - formats/tpc_reader.gd
---

# Q86: Native TPC DXT Encode

## Summary

Add **native DXT1 and DXT5 encoding** for KotOR TPC write-back, closing the Q30-deferred compression gap so RGBA sources can be written as compressed TPC without PyKotor CLI.

---

## Problem Frame

`TPCReader` decodes DXT1/DXT3/DXT5 but `TPCWriter` only emits passthrough and uncompressed RGBA. Most game textures are DXT-compressed; batch/import paths currently write bulky RGBA TPC files.

---

## Scope Boundaries

### In scope

- `TpcDxtEncoder` — CPU DXT1 + DXT5 block encoder from RGBA `Image`
- `TPCWriter.serialize_dxt1` / `serialize_dxt5` wrappers (mip 0, num_mips=1)
- Headless round-trip tests via existing `TPCReader` decode path
- Execution queue + parity matrix Q86 entry

### Deferred

- DXT3 encode (less common in KotOR workflows)
- Mipmap generation for compressed encodes
- TPC editor UI toggle (encode-on-save menu)

### Out of scope

- GPU/compute compression
- PyKotor CLI texture-convert changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `serialize_dxt1` writes valid DXT1 TPC readable by `TPCReader` | Unit test |
| R2 | `serialize_dxt5` writes valid DXT5 TPC readable by `TPCReader` | Unit test |
| R3 | Round-trip preserves dimensions and approximate color for solid blocks | Unit test |
| R4 | Invalid inputs return empty bytes | Unit test |
| R5 | Docs mark Q86 shipped | Doc diff |

---

## Implementation Units

### U1 — DXT encoder

- **Files:** `formats/tpc_dxt_encoder.gd`

### U2 — TPCWriter integration

- **Files:** `formats/tpc_writer.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_tpc_dxt_encoder.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_dxt_encoder.gd
godot --headless --path . --script tests/editor/test_tpc_writer.gd
```
