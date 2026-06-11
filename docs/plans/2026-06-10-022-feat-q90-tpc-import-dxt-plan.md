---
title: "feat: Q90 TPC editor import image as DXT"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q89-auto-selected
phase: Q90
track: Texture/Media Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-021-feat-q89-gamefs-batch-dxt-import-plan.md
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q90: TPC Editor Import Image as DXT

## Summary

Add TPC workspace toolbar actions to import a single TGA/PNG file directly as **DXT1 or DXT5** TPC, completing the single-file import path deferred from Q89.

---

## Problem Frame

Q30 added **Import TGA/PNG...** (RGBA only). Q87–Q89 added re-encode and batch DXT paths, but modders opening one source image still cannot import it compressed without an extra re-encode step.

---

## Scope Boundaries

### In scope

- Refactor image import to shared `_load_image_as_tpc(path, encoding)` helper
- Public `load_image_as_dxt1/dxt5(path)` for headless tests
- Toolbar **Import TGA/PNG as DXT1...** and **Import TGA/PNG as DXT5...**
- Headless tests + docs Q90 entry

### Deferred

- DXT3 import
- TXI sidecar pairing on import

### Out of scope

- Batch/folder import changes (Q88/Q89)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `load_image_as_dxt1` loads PNG and sets `ENC_DXT1` metadata | Unit test |
| R2 | `load_image_as_dxt5` loads PNG and sets `ENC_DXT5` metadata | Unit test |
| R3 | Existing RGBA import unchanged | Existing test path |
| R4 | Toolbar exposes DXT1/DXT5 import buttons | Wiring test |
| R5 | Docs mark Q90 shipped | Doc diff |

---

## Implementation Units

### U1 — Shared import helper + public API

- **Files:** `ui/workspace/editors/tpc_workspace_editor.gd`

### U2 — Tests + docs

- **Files:** `tests/editor/test_tpc_dxt_reencode.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_dxt_reencode.gd
```
