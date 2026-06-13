---
title: "feat: Holocron parity Wave D — DLG K1 depth"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q155-Q157
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - ui/workspace/editors/dlg_workspace_editor.gd
  - ui/workspace/panels/dlg_graph_view.gd
  - resources/documents/kotor_dlg_document.gd
---

# Wave D: DLG Holocron Depth (K1) (Q155–Q157)

## Summary

Close K1 gaps in Holocron `editors/dlg/` after Q128 graph foundations and Q148–Q150 port/fit polish.

## Requirements

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | Animations list editor on entry/reply nodes (add/remove/reorder) | Q155 |
| R2 | Graph minimap or zoom navigator for large DLGs | Q156 |
| R3 | Camera angle, delay, fade guided fields (not raw tree only) | Q157 |
| R4 | Sound/VO ResRef pickers on dialogue nodes | Q157 |
| R5 | Headless tests in `test_dlg_workspace_editor.gd` + `test_dlg_graph_layout.gd` | All |

## Q155 — Animations panel

**Files:**
- `kotor_dlg_document.gd` — animation list CRUD on entry/reply structs
- `dlg_workspace_editor.gd` — Animations sub-panel in detail inspector
- `tests/editor/test_dlg_workspace_editor.gd`

## Q156 — Graph minimap

**Files:**
- `dlg_graph_view.gd` — minimap SubViewport or GraphEdit minimap overlay
- `dlg_workspace_editor.gd` — toggle minimap visibility
- `tests/editor/test_dlg_graph_layout.gd` — bounds/minimap sync

## Q157 — Sound/VO/camera fields

**Files:**
- `dlg_workspace_editor.gd` — guided controls wired to document setters
- Reuse `ResRef` pickers from typed field helpers

## Verification

```bash
godot --headless --path . --script tests/editor/test_dlg_workspace_editor.gd
godot --headless --path . --script tests/editor/test_dlg_graph_layout.gd
```

## Out of scope

- TSL/K2-only DLG fields (Q200+)
- Animated graph edges (P2 polish)
