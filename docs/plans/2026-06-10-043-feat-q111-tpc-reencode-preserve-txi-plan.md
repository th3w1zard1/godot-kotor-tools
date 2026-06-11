---
title: "feat: Q111 preserve TXI on TPC DXT re-encode"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q110-auto-selected
phase: Q111
track: Texture/Media Editing
parent: docs/plans/2026-06-10-042-feat-q110-tpc-txi-editing-ui-plan.md
related:
  - ui/workspace/editors/tpc_workspace_editor.gd
  - formats/tpc_writer.gd
---

# Q111: Preserve TXI on TPC DXT Re-encode

## Summary

When re-encoding a loaded TPC as DXT1/DXT5, preserve any existing TXI tail bytes so envmap/bumpmap metadata survives texture compression — closing the gap deferred from Q110.

---

## Problem Frame

Q110 added TXI editing, but `_reencode_loaded_image` replaces `_bytes` with fresh DXT mip payloads and drops the TXI tail. Modders lose metadata on every DXT re-encode.

---

## Scope Boundaries

### In scope

- `_reencode_loaded_image` reads TXI via `TPCWriter.read_txi_bytes` before encode and re-appends after DXT serialize
- Headless tests in `tests/editor/test_tpc_dxt_reencode.gd` (DXT1 + DXT5 preserve cases)
- Execution queue + parity matrix Q111 entry

### Deferred

- DXT3 encode/import
- TXI preservation on RGBA re-encode paths (no RGBA re-encode toolbar today)

### Out of scope

- TXI syntax validation

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | DXT1 re-encode keeps TXI tail bytes | Unit test |
| R2 | DXT5 re-encode keeps TXI tail bytes | Unit test |
| R3 | `get_txi_text()` unchanged after re-encode | Unit test |
| R4 | Docs mark Q111 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_dxt_reencode.gd
godot --headless --path . --script tests/editor/test_tpc_txi_editor.gd
```
