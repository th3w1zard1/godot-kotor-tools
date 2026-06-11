---
title: "feat: Q87 TPC editor DXT re-encode"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q86-auto-selected
phase: Q87
track: Texture/Media Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-018-feat-q86-tpc-dxt-encode-plan.md
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q87: TPC Editor DXT Re-encode

## Summary

Expose Q86 DXT compression in the **TPC workspace editor** via toolbar actions that re-encode the loaded texture as DXT1 or DXT5, marking the document dirty for export/install.

---

## Problem Frame

Q86 added `TPCWriter.serialize_dxt1/dxt5` but modders still cannot compress textures from the editor UI — only uncompressed RGBA import paths exist.

---

## Scope Boundaries

### In scope

- `reencode_loaded_as_dxt1()` / `reencode_loaded_as_dxt5()` on `KotorTPCWorkspaceEditor`
- Toolbar buttons **Re-encode DXT1...** and **Re-encode DXT5...**
- Headless tests for re-encode + toolbar wiring
- Execution queue + parity matrix Q87 entry

### Deferred

- DXT3 re-encode
- Import-image-as-DXT directly from file dialog
- Batch converter DXT mode

### Out of scope

- Encoder algorithm changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Re-encode DXT1 updates `_bytes` with DXT1 encoding | Unit test |
| R2 | Re-encode DXT5 updates `_bytes` with DXT5 encoding | Unit test |
| R3 | Re-encode marks document dirty and refreshes preview/metadata | Unit test |
| R4 | Toolbar exposes both re-encode buttons | Unit test |
| R5 | Docs mark Q87 shipped | Doc diff |

---

## Implementation Units

### U1 — TPC editor re-encode API + toolbar

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U2 — Tests + docs

- **Files:** `tests/editor/test_tpc_dxt_reencode.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_dxt_reencode.gd
```
