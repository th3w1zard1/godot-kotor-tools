---
title: "feat: Q114 TPC editor TXI file import/export"
type: feat
status: shipped
date: 2026-06-10
origin: lfg-next-after-q113-auto-selected
phase: Q114
track: Texture/Media Editing
parent: docs/plans/2026-06-10-042-feat-q110-tpc-txi-editing-ui-plan.md
related:
  - formats/tpc_writer.gd
  - ui/workspace/editors/tpc_workspace_editor.gd
---

# Q114: TPC Editor TXI File Import/Export

## Summary

Round out the TXI editing workflow with **Import TXI...** and **Export TXI...** toolbar actions so modders can load sibling `.txi` files into the embedded tail or write the current TXI text to disk.

---

## Problem Frame

Q110 added in-editor TXI editing and **Apply TXI**. Q99 pairs sibling `.txi` on image import. Modders still need explicit file I/O to sync embedded tails with external `.txi` sidecars without re-importing the whole texture.

---

## Scope Boundaries

### In scope

- `import_txi_from_file(path)` — read UTF-8 `.txi`, call `apply_txi_text`
- `export_txi_to_file(path)` — write `get_txi_text()` UTF-8 to `.txi`
- Toolbar **Import TXI...** / **Export TXI...** with `EditorFileDialog`
- Extend `tests/editor/test_tpc_txi_editor.gd`
- Execution queue + parity matrix Q114 entry

### Deferred

- TXI syntax validation
- Batch TXI export for folders

### Out of scope

- Standalone TXI-only workspace editor

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Import applies `.txi` file content to embedded tail | Unit test |
| R2 | Export writes editor TXI text to `.txi` file | Unit test |
| R3 | Import missing file fails gracefully | Unit test |
| R4 | Toolbar exposes both buttons | Wiring test |
| R5 | Docs mark Q114 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_txi_editor.gd
```
