---
title: "feat: Q110 TPC editor TXI editing UI"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q109-auto-selected
phase: Q110
track: Texture/Media Editing
parent: docs/plans/2026-06-10-031-feat-q99-tpc-txi-sidecar-pairing-plan.md
related:
  - formats/tpc_writer.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q110: TPC Editor TXI Editing UI

## Summary

Expose embedded TXI metadata editing in the TPC workspace editor so modders can view and write TXI tails on loaded `.tpc` files using existing `TPCWriter.append_txi_bytes` / `read_txi_bytes`.

---

## Problem Frame

Q99 attaches sibling `.txi` on import/convert. Loaded TPC files may already carry TXI tails, but the editor only shows byte length — modders cannot edit envmap/bumpmap/procedure lines without external tools.

---

## Scope Boundaries

### In scope

- TXI `TextEdit` panel below metadata in `KotorTPCWorkspaceEditor`
- **Apply TXI** toolbar action + public `apply_txi_text(text: String) -> bool` for tests
- `get_txi_text() -> String` reads current editor text
- Headless `tests/editor/test_tpc_txi_editor.gd`
- Execution queue + parity matrix Q110 entry

### Deferred

- DXT3 encode/import
- Preserve TXI across DXT re-encode (separate slice)
- TXI syntax validation beyond UTF-8 round-trip

### Out of scope

- Standalone `.txi` file editor

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Loaded TPC populates TXI editor from tail bytes | Unit test |
| R2 | `apply_txi_text` updates `txi_length` in metadata | Unit test |
| R3 | Empty apply clears TXI tail | Unit test |
| R4 | Apply marks document dirty | Unit test |
| R5 | Toolbar exposes **Apply TXI** button | Wiring test |
| R6 | Docs mark Q110 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_txi_editor.gd
```
